//> using scala 3.7
//> using file nodelib.scala

package nodelib

import org.apache.pekko.actor.typed.{ActorRef, Behavior}
import org.apache.pekko.actor.typed.scaladsl.Behaviors
import scala.concurrent.Await
import scala.concurrent.duration.*

import java.nio.file.Path

enum NodeCommand:
  case Stop
  case Request(rpc: RPCRequest)
  case InternalReply(response: RPCResponse, clientRef: ActorRef[RPCResponse])

object Node:
  def init(id: String, storeRoot: Path): Behavior[NodeCommand] =
    Behaviors.setup: ctx =>
      val serverRef = ctx.spawn(KVServer.init(id, storeRoot), "server")
      ctx.log.info("[{}] Node started", id)
      handle(id, serverRef)

  private def handle(id: String, serverRef: ActorRef[ServerCommand]): Behavior[NodeCommand] =
    Behaviors.receive: (ctx, msg) =>
      msg match
        case NodeCommand.Stop =>
          ctx.log.info("[{}] Stopping", id)
          Behaviors.stopped
        case NodeCommand.Request(rpc) =>
          val delay = networkCall(ctx, serverRef, ServerCommand(rpc, ctx.self, rpc.replyTo))
          ctx.log.info("[{}] req={} → server (delay {}ms)", id, rpc.rid, delay.toMillis)
          Behaviors.same
        case NodeCommand.InternalReply(response, clientRef) =>
          val delay = networkCall(ctx, clientRef, response)
          ctx.log.info("[{}] req={} → client (delay {}ms): {}", id, response.rid, delay.toMillis, response)
          Behaviors.same

@main def lab(): Unit =

  val cluster = Cluster("lab-cluster")

  // Spawn three nodes
  val alice = cluster.spawn("alice", Node.init)
  val bob   = cluster.spawn("bob", Node.init)
  val carol = cluster.spawn("carol", Node.init)

  // Write data to different nodes
  println("--- Writing data ---")
  Await.result(alice.put("name", "Alice"),   5.seconds)
  Await.result(bob.put("name", "Bob"),       5.seconds)
  Await.result(carol.put("name", "Carol"),   5.seconds)
  Await.result(alice.put("color", "red"),    5.seconds)
  Await.result(bob.put("color", "blue"),     5.seconds)

  // Read back from each node — each has its own isolated store
  println("\n--- Reading from own nodes ---")
  println(Await.result(alice.get("name"),  5.seconds))
  println(Await.result(bob.get("name"),    5.seconds))
  println(Await.result(carol.get("name"),  5.seconds))

  // Try reading a key that only exists on alice, from bob
  println("\n--- Cross-node read (bob reads alice's key) ---")
  println(Await.result(bob.get("color"),   5.seconds))
  println(Await.result(alice.get("color"), 5.seconds))

  // Delete a key
  println("\n--- Deleting ---")
  println(Await.result(alice.del("color"), 5.seconds))
  println(Await.result(alice.get("color"), 5.seconds))

  // Concurrent requests — fire multiple gets in parallel
  println("\n--- Parallel reads ---")
  val futures = Seq(
    alice.get("name"),
    bob.get("name"),
    carol.get("name"),
  )
  val results = futures.map(f => Await.result(f, 5.seconds))
  results.foreach(println)

  // Stop a node, then try to read from it (will timeout)
  println("\n--- Stopping bob ---")
  cluster.stop("bob")
  Thread.sleep(500)
  try
    println(Await.result(bob.get("name"), 2.seconds))
  catch
    case e: java.util.concurrent.TimeoutException =>
      println(s"bob is down: ${e.getMessage}")

  // Shutdown
  cluster.shutdown()
  println("\n--- Done ---")
