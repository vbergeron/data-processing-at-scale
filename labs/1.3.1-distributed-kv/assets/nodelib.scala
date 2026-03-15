//> using scala 3.7
//> using dep org.apache.pekko::pekko-actor-typed:1.4.0
//> using dep org.slf4j:slf4j-simple:2.0.17

package nodelib

import java.nio.file.{Files, Path}
import org.apache.pekko.actor.typed.{ActorRef, ActorSystem, Behavior}
import org.apache.pekko.actor.typed.scaladsl.{ActorContext, AskPattern, Behaviors}
import scala.concurrent.{Future, Await}
import scala.concurrent.duration.*
import scala.util.Random

// --- Storage layer (hidden from students) ---

private class KV(root: Path):
  Files.createDirectories(root)

  private def keyPath(key: String): Path = root.resolve(key)

  def get(key: String): Option[String] =
    val p = keyPath(key)
    Option.when(Files.exists(p))(Files.readString(p))

  def put(key: String, value: String): Unit =
    Files.writeString(keyPath(key), value)

  def del(key: String): Boolean =
    Files.deleteIfExists(keyPath(key))

// --- Protocol ---

private def newRid(): String = f"${Random.nextInt() & 0xffff}%04x"

enum RPCRequest(val rid: String = newRid()):
  def replyTo: ActorRef[RPCResponse]
  case Get(key: String, replyTo: ActorRef[RPCResponse]) extends RPCRequest()
  case Put(key: String, value: String, replyTo: ActorRef[RPCResponse]) extends RPCRequest()
  case Del(key: String, replyTo: ActorRef[RPCResponse]) extends RPCRequest()

enum RPCResponse:
  def rid: String
  case GetResult(key: String, value: Option[String], rid: String)
  case PutResult(key: String, rid: String)
  case DelResult(key: String, deleted: Boolean, rid: String)

enum NodeCommand:
  case Stop
  case Request(rpc: RPCRequest)

case class ServerCommand(rpc: RPCRequest, replyTo: ActorRef[RPCResponse])

type NodeFactory = (Cluster, String, Path) => Behavior[NodeCommand]

// --- KV application logic ---

object KVServer:
  def init(id: String, storeRoot: Path): Behavior[ServerCommand] =
    val store = KV(storeRoot.resolve(id))
    Behaviors.setup: ctx =>
      ctx.log.info("[{}] KVServer started, store at {}", id, storeRoot.resolve(id))
      Behaviors.receiveMessage(handle(id, store, ctx))

  private def handle(id: String, store: KV, ctx: ActorContext[ServerCommand])(cmd: ServerCommand): Behavior[ServerCommand] =
    val ServerCommand(rpc, replyTo) = cmd
    val rid = rpc.rid
    val response = rpc match
      case RPCRequest.Get(key, _) =>
        val value = store.get(key)
        ctx.log.info("[{}] req={} GET {} -> {}", id, rid, key, value.getOrElse("<none>"))
        RPCResponse.GetResult(key, value, rid)
      case RPCRequest.Put(key, value, _) =>
        ctx.log.info("[{}] req={} PUT {} = {}", id, rid, key, value)
        store.put(key, value)
        RPCResponse.PutResult(key, rid)
      case RPCRequest.Del(key, _) =>
        val deleted = store.del(key)
        ctx.log.info("[{}] req={} DEL {} -> deleted={}", id, rid, key, deleted)
        RPCResponse.DelResult(key, deleted, rid)
    replyTo ! response
    Behaviors.same

// --- Client ---

class KVClient(nodeId: String, cluster: Cluster):
  given ActorSystem[?] = cluster.system
  given scala.concurrent.ExecutionContext = cluster.system.executionContext

  def get(key: String): Future[RPCResponse] =
    cluster.system.log.info("[client] GET {} on {}", key, nodeId)
    cluster.ask(nodeId, ref => RPCRequest.Get(key, ref)).map: resp =>
      cluster.system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

  def put(key: String, value: String): Future[RPCResponse] =
    cluster.system.log.info("[client] PUT {} = {} on {}", key, value, nodeId)
    cluster.ask(nodeId, ref => RPCRequest.Put(key, value, ref)).map: resp =>
      cluster.system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

  def del(key: String): Future[RPCResponse] =
    cluster.system.log.info("[client] DEL {} on {}", key, nodeId)
    cluster.ask(nodeId, ref => RPCRequest.Del(key, ref)).map: resp =>
      cluster.system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

// --- Cluster (the network) ---

class Cluster(name: String):
  val storeRoot: Path = Files.createTempDirectory(s"cluster-$name-")
  given system: ActorSystem[Nothing] = ActorSystem(Behaviors.empty, name)
  private var nodes: Map[String, ActorRef[NodeCommand]] = Map.empty
  private var partitions: Set[(String, String)] = Set.empty

  import AskPattern.*
  given org.apache.pekko.util.Timeout = 3.seconds

  system.log.info("Cluster '{}' started, store root: {}", name, storeRoot)

  private def networkDelay(): FiniteDuration =
    (50 + Random.nextInt(450)).millis

  def isReachable(from: String, to: String): Boolean =
    !partitions.contains((from, to))

  def send(from: String, to: String, msg: NodeCommand): Boolean =
    if !isReachable(from, to) then
      system.log.info("[net] {} → {} DROPPED", from, to)
      false
    else
      val delay = networkDelay()
      system.log.info("[net] {} → {} (delay {}ms)", from, to, delay.toMillis)
      val target = nodes.getOrElse(to, throw IllegalArgumentException(s"No node '$to'"))
      system.scheduler.scheduleOnce(delay, () => target ! msg)(using system.executionContext)
      true

  def ask(to: String, mkRpc: ActorRef[RPCResponse] => RPCRequest): Future[RPCResponse] =
    val target = nodes.getOrElse(to, throw IllegalArgumentException(s"No node '$to'"))
    if !isReachable("client", to) then
      system.log.info("[net] client → {} DROPPED", to)
      Future.failed(java.util.concurrent.TimeoutException(s"Partitioned from $to"))
    else
      val delay = networkDelay()
      system.log.info("[net] client → {} (delay {}ms)", to, delay.toMillis)
      val promise = scala.concurrent.Promise[RPCResponse]()
      system.scheduler.scheduleOnce(delay, () =>
        val future = target.ask[RPCResponse](ref => NodeCommand.Request(mkRpc(ref)))
        promise.completeWith(future)
      )(using system.executionContext)
      promise.future

  def spawn(id: String): KVClient =
    spawn(id, Node.defaultFactory)

  def spawn(id: String, factory: NodeFactory): KVClient =
    system.log.info("Spawning node '{}'", id)
    val ref = system.systemActorOf(factory(this, id, storeRoot), s"node-$id")
    nodes = nodes.updated(id, ref)
    KVClient(id, this)

  def client(id: String): KVClient =
    if !nodes.contains(id) then throw IllegalArgumentException(s"No node '$id'")
    KVClient(id, this)

  def ref(id: String): ActorRef[NodeCommand] =
    nodes.getOrElse(id, throw IllegalArgumentException(s"No node '$id'"))

  def partition(a: String, b: String): Unit =
    system.log.info("[net] Partition: {} <-/-> {}", a, b)
    partitions += ((a, b))
    partitions += ((b, a))

  def heal(a: String, b: String): Unit =
    system.log.info("[net] Healed: {} <-> {}", a, b)
    partitions -= ((a, b))
    partitions -= ((b, a))

  def isolate(id: String): Unit =
    system.log.info("[net] Isolating node '{}'", id)
    nodes.keys.foreach: other =>
      if other != id then
        partitions += ((id, other))
        partitions += ((other, id))
    partitions += (("client", id))
    partitions += ((id, "client"))

  def rejoin(id: String): Unit =
    system.log.info("[net] Rejoining node '{}'", id)
    partitions = partitions.filterNot((a, b) => a == id || b == id)

  def stop(id: String): Unit =
    system.log.info("Stopping node '{}'", id)
    nodes.get(id).foreach(_ ! NodeCommand.Stop)
    nodes = nodes.removed(id)

  def shutdown(): Unit =
    system.log.info("Shutting down cluster '{}' ({} nodes)", name, nodes.size)
    nodes.keys.foreach(stop)
    system.terminate()
    Await.result(system.whenTerminated, 10.seconds)

// Default Node factory reference
private[nodelib] object Node:
  val defaultFactory: NodeFactory = (cluster, id, storeRoot) => init(cluster, id, storeRoot)

  def init(cluster: Cluster, id: String, storeRoot: Path): Behavior[NodeCommand] =
    Behaviors.setup: ctx =>
      val serverRef = ctx.spawn(KVServer.init(id, storeRoot), "server")
      ctx.log.info("[{}] Node started", id)
      Behaviors.receiveMessage:
        case NodeCommand.Stop =>
          ctx.log.info("[{}] Stopping", id)
          Behaviors.stopped
        case NodeCommand.Request(rpc) =>
          ctx.log.info("[{}] req={} processing", id, rpc.rid)
          serverRef ! ServerCommand(rpc, rpc.replyTo)
          Behaviors.same
