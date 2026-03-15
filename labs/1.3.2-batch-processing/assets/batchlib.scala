//> using scala 3.7
//> using dep org.apache.pekko::pekko-actor-typed:1.4.0
//> using dep org.slf4j:slf4j-simple:2.0.17

package batchlib

import org.apache.pekko.actor.typed.{ActorRef, ActorSystem, Behavior}
import org.apache.pekko.actor.typed.scaladsl.{ActorContext, AskPattern, Behaviors}
import scala.concurrent.{Future, Promise, Await}
import scala.concurrent.duration.*
import scala.util.Random

// --- Utilities ---

def timed[A](label: String)(body: => A): A =
  val t0 = System.nanoTime()
  val result = body
  val ms = (System.nanoTime() - t0) / 1_000_000
  println(s"[$label] ${ms}ms")
  result

def timedFuture[A](label: String)(body: => Future[A])(using ec: scala.concurrent.ExecutionContext): Future[A] =
  val t0 = System.nanoTime()
  body.map: result =>
    val ms = (System.nanoTime() - t0) / 1_000_000
    println(s"[$label] ${ms}ms")
    result

// --- Protocol ---

enum WorkerCommand:
  case LoadData(records: Vector[String], replyTo: ActorRef[LoadResult])
  case RunMap(mapFn: String => Vector[(String, String)], replyTo: ActorRef[MapResult])
  case ReceiveShuffle(data: Map[String, Vector[String]], replyTo: ActorRef[ShuffleAck])
  case RunReduce(reduceFn: (String, Vector[String]) => String, replyTo: ActorRef[ReduceResult])
  case Stop

case class LoadResult(workerId: String, count: Int)
case class MapResult(workerId: String, pairs: Vector[(String, String)])
case class ShuffleAck(workerId: String, keysReceived: Int)
case class ReduceResult(workerId: String, results: Map[String, String])

// --- Worker ---

object Worker:
  def init(id: String): Behavior[WorkerCommand] =
    Behaviors.setup: ctx =>
      ctx.log.info("[{}] Worker started", id)
      ready(id, ctx, Vector.empty, Map.empty)

  private def ready(
    id: String,
    ctx: ActorContext[WorkerCommand],
    data: Vector[String],
    shuffled: Map[String, Vector[String]]
  ): Behavior[WorkerCommand] =
    Behaviors.receiveMessage:
      case WorkerCommand.LoadData(records, replyTo) =>
        val newData = data ++ records
        ctx.log.info("[{}] Loaded {} records (total: {})", id, records.size, newData.size)
        replyTo ! LoadResult(id, newData.size)
        ready(id, ctx, newData, shuffled)

      case WorkerCommand.RunMap(mapFn, replyTo) =>
        val t0 = System.nanoTime()
        val pairs = data.flatMap(mapFn)
        val ms = (System.nanoTime() - t0) / 1_000_000
        ctx.log.info("[{}] Map: {} records → {} pairs ({}ms)", id, data.size, pairs.size, ms)
        replyTo ! MapResult(id, pairs)
        Behaviors.same

      case WorkerCommand.ReceiveShuffle(incoming, replyTo) =>
        val merged = incoming.foldLeft(shuffled):
          case (acc, (k, vs)) => acc.updated(k, acc.getOrElse(k, Vector.empty) ++ vs)
        val count = incoming.values.map(_.size).sum
        ctx.log.info("[{}] Shuffle: +{} keys, {} values (total keys: {})", id, incoming.size, count, merged.size)
        replyTo ! ShuffleAck(id, incoming.size)
        ready(id, ctx, data, merged)

      case WorkerCommand.RunReduce(reduceFn, replyTo) =>
        val t0 = System.nanoTime()
        val results = shuffled.map((k, vs) => k -> reduceFn(k, vs))
        val ms = (System.nanoTime() - t0) / 1_000_000
        ctx.log.info("[{}] Reduce: {} keys ({}ms)", id, results.size, ms)
        replyTo ! ReduceResult(id, results)
        Behaviors.same

      case WorkerCommand.Stop =>
        ctx.log.info("[{}] Stopping", id)
        Behaviors.stopped

// --- Cluster ---

class Cluster(val name: String, val numWorkers: Int):
  given system: ActorSystem[Nothing] = ActorSystem(Behaviors.empty, name)
  given scala.concurrent.ExecutionContext = system.executionContext

  import AskPattern.*
  given org.apache.pekko.util.Timeout = 60.seconds

  val workerIds: Vector[String] = (0 until numWorkers).map(i => s"w$i").toVector

  private val workers: Map[String, ActorRef[WorkerCommand]] =
    workerIds.map(id => id -> system.systemActorOf(Worker.init(id), id)).toMap

  system.log.info("Cluster '{}': {} workers [{}]", name, numWorkers, workerIds.mkString(", "))

  private def networkDelay(): FiniteDuration = (50 + Random.nextInt(450)).millis

  def ask[Res](workerId: String, mkMsg: ActorRef[Res] => WorkerCommand): Future[Res] =
    val worker = workers.getOrElse(workerId, throw IllegalArgumentException(s"No worker '$workerId'"))
    val delay = networkDelay()
    system.log.info("[net] → {} ({}ms)", workerId, delay.toMillis)
    val promise = Promise[Res]()
    system.scheduler.scheduleOnce(delay, () =>
      promise.completeWith(worker.ask(mkMsg))
    )(using system.executionContext)
    promise.future

  def askAll[Res](mkMsg: ActorRef[Res] => WorkerCommand): Future[Vector[Res]] =
    Future.sequence(workerIds.map(id => ask[Res](id, mkMsg)))

  def shutdown(): Unit =
    system.log.info("Shutting down cluster '{}'", name)
    workers.values.foreach(_ ! WorkerCommand.Stop)
    system.terminate()
    Await.result(system.whenTerminated, 10.seconds)
