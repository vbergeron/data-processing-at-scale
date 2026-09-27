//> using scala 3.7
//> using file nodelib.scala

package nodelib

import org.apache.pekko.actor.typed.{ActorRef, Behavior}
import org.apache.pekko.actor.typed.scaladsl.Behaviors
import scala.concurrent.Await
import scala.concurrent.duration.*

import java.nio.file.Path

object MyNode:
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

@main def lab(): Unit =

  val cluster = Cluster("lab-cluster")

  // Spawn three nodes running your MyNode behavior
  val alice = cluster.spawn("alice", MyNode.init)
  val bob   = cluster.spawn("bob",   MyNode.init)
  val carol = cluster.spawn("carol", MyNode.init)

  // Write data to different nodes
  println("--- Writing data ---")
  Await.result(alice.put("name", "Alice"),   5.seconds)
  Await.result(bob.put("name", "Bob"),       5.seconds)
  Await.result(carol.put("name", "Carol"),   5.seconds)

  // Read back from each node
  println("\n--- Reading from own nodes ---")
  println(Await.result(alice.get("name"),  5.seconds))
  println(Await.result(bob.get("name"),    5.seconds))
  println(Await.result(carol.get("name"),  5.seconds))

  // Partition bob from the cluster
  println("\n--- Isolating bob ---")
  cluster.isolate("bob")
  try
    println(Await.result(bob.get("name"), 2.seconds))
  catch
    case _: java.util.concurrent.TimeoutException =>
      println("bob is unreachable (partitioned)")
    case e: Exception =>
      println(s"bob is unreachable: ${e.getMessage}")

  // alice and carol still work
  println("\n--- alice and carol still reachable ---")
  println(Await.result(alice.get("name"), 5.seconds))
  println(Await.result(carol.get("name"), 5.seconds))

  // Heal the partition
  println("\n--- Rejoining bob ---")
  cluster.rejoin("bob")
  println(Await.result(bob.get("name"), 5.seconds))

  // Stop a node
  println("\n--- Stopping bob ---")
  cluster.stop("bob")
  Thread.sleep(500)
  try
    println(Await.result(bob.get("name"), 2.seconds))
  catch
    case _: Exception =>
      println("bob is down (stopped)")

  // Shutdown
  cluster.shutdown()
  println("\n--- Done ---")
