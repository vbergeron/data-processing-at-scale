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

def newRid(): String = f"${Random.nextInt() & 0xffff}%04x"

enum RPCRequest:
  def replyTo: ActorRef[RPCResponse]
  def rid: String
  case Get(key: String, replyTo: ActorRef[RPCResponse], rid: String = newRid())
  case Put(key: String, value: String, replyTo: ActorRef[RPCResponse], rid: String = newRid())
  case Del(key: String, replyTo: ActorRef[RPCResponse], rid: String = newRid())

enum RPCResponse:
  def rid: String
  case GetResult(key: String, value: Option[String], rid: String)
  case PutResult(key: String, rid: String)
  case DelResult(key: String, deleted: Boolean, rid: String)

case class ServerCommand(rpc: RPCRequest, nodeRef: ActorRef[NodeCommand], clientRef: ActorRef[RPCResponse])

type NodeFactory = (String, Path) => Behavior[NodeCommand]

def networkCall[T](ctx: ActorContext[?], target: ActorRef[T], msg: T): FiniteDuration =
  val delay = (50 + Random.nextInt(450)).millis
  ctx.scheduleOnce(delay, target, msg)
  delay

// --- KV application logic ---

object KVServer:
  def init(id: String, storeRoot: Path): Behavior[ServerCommand] =
    val store = KV(storeRoot.resolve(id))
    Behaviors.setup: ctx =>
      ctx.log.info("[{}] KVServer started, store at {}", id, storeRoot.resolve(id))
      Behaviors.receiveMessage(handle(id, store, ctx))

  private def handle(id: String, store: KV, ctx: ActorContext[ServerCommand])(cmd: ServerCommand): Behavior[ServerCommand] =
    val ServerCommand(rpc, nodeRef, _) = cmd
    val rid = rpc.rid
    val response = rpc match
      case RPCRequest.Get(key, _, _) =>
        val value = store.get(key)
        ctx.log.info("[{}] req={} GET {} -> {}", id, rid, key, value.getOrElse("<none>"))
        RPCResponse.GetResult(key, value, rid)
      case RPCRequest.Put(key, value, _, _) =>
        ctx.log.info("[{}] req={} PUT {} = {}", id, rid, key, value)
        store.put(key, value)
        RPCResponse.PutResult(key, rid)
      case RPCRequest.Del(key, _, _) =>
        val deleted = store.del(key)
        ctx.log.info("[{}] req={} DEL {} -> deleted={}", id, rid, key, deleted)
        RPCResponse.DelResult(key, deleted, rid)
    nodeRef ! NodeCommand.InternalReply(response, cmd.clientRef)
    Behaviors.same

// --- Client ---

class KVClient(node: ActorRef[NodeCommand])(using system: ActorSystem[?]):
  import AskPattern.*
  given org.apache.pekko.util.Timeout = 3.seconds
  given scala.concurrent.ExecutionContext = system.executionContext

  def get(key: String): Future[RPCResponse] =
    system.log.info("[client] GET {}", key)
    node.ask[RPCResponse](ref => NodeCommand.Request(RPCRequest.Get(key, ref))).map: resp =>
      system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

  def put(key: String, value: String): Future[RPCResponse] =
    system.log.info("[client] PUT {} = {}", key, value)
    node.ask[RPCResponse](ref => NodeCommand.Request(RPCRequest.Put(key, value, ref))).map: resp =>
      system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

  def del(key: String): Future[RPCResponse] =
    system.log.info("[client] DEL {}", key)
    node.ask[RPCResponse](ref => NodeCommand.Request(RPCRequest.Del(key, ref))).map: resp =>
      system.log.info("[client] req={} → {}", resp.rid, resp)
      resp

// --- Cluster ---

class Cluster(name: String):
  val storeRoot: Path = Files.createTempDirectory(s"cluster-$name-")
  given system: ActorSystem[Nothing] = ActorSystem(Behaviors.empty, name)
  private var nodes: Map[String, ActorRef[NodeCommand]] = Map.empty

  system.log.info("Cluster '{}' started, store root: {}", name, storeRoot)

  def spawn(id: String, factory: NodeFactory): KVClient =
    system.log.info("Spawning node '{}'", id)
    val ref = system.systemActorOf(factory(id, storeRoot), s"node-$id")
    nodes = nodes.updated(id, ref)
    KVClient(ref)

  def client(id: String): KVClient =
    nodes.get(id) match
      case Some(ref) => KVClient(ref)
      case None      => throw IllegalArgumentException(s"No node '$id'")

  def ref(id: String): ActorRef[NodeCommand] =
    nodes.getOrElse(id, throw IllegalArgumentException(s"No node '$id'"))

  def stop(id: String): Unit =
    system.log.info("Stopping node '{}'", id)
    nodes.get(id).foreach(_ ! NodeCommand.Stop)
    nodes = nodes.removed(id)

  def shutdown(): Unit =
    system.log.info("Shutting down cluster '{}' ({} nodes)", name, nodes.size)
    nodes.keys.foreach(stop)
    system.terminate()
    Await.result(system.whenTerminated, 10.seconds)
