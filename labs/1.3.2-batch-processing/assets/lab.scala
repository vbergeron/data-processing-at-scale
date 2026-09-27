//> using scala 3.7
//> using file batchlib.scala

package batchlib

import scala.concurrent.{Await, Future}
import scala.concurrent.duration.*
import scala.util.Random

@main def lab(): Unit =
  val cluster = Cluster("mr", numWorkers = 4)
  given scala.concurrent.ExecutionContext = cluster.system.executionContext

  // --- Generate 10,000 sales records: "id,region,product,amount" ---
  val regions  = Vector("eu", "us", "asia", "africa")
  val products = (1 to 20).map(i => s"product-$i").toVector
  val data = Vector.fill(10_000):
    val id      = java.util.UUID.randomUUID().toString.take(8)
    val region  = regions(Random.nextInt(4))
    val product = products(Random.nextInt(20))
    val amount  = 100 + Random.nextInt(49_901)
    s"$id,$region,$product,$amount"

  println(s"Generated ${data.size} records\n")

  // --- Phase 1: Load (round-robin) ---
  val loadResults = timed("Load"):
    val chunkSize = math.ceil(data.size.toDouble / cluster.numWorkers).toInt
    val chunks = data.grouped(chunkSize).toVector
    Await.result(
      Future.sequence(
        cluster.workerIds.zip(chunks).map: (id, chunk) =>
          cluster.ask[LoadResult](id, ref => WorkerCommand.LoadData(chunk, ref))
      ),
      30.seconds
    )
  loadResults.foreach(r => println(s"  ${r.workerId}: ${r.count} records"))

  // --- Phase 2: Map — extract (region, amount) ---
  val mapFn: String => Vector[(String, String)] = line =>
    val cols = line.split(",")
    Vector((cols(1), cols(3)))

  val mapResults = timed("Map"):
    Await.result(
      cluster.askAll[MapResult](ref => WorkerCommand.RunMap(mapFn, ref)),
      30.seconds
    )
  mapResults.foreach(r => println(s"  ${r.workerId}: ${r.pairs.size} pairs"))

  // --- Phase 3: Shuffle — route each key to hash(key) % numWorkers ---
  val shuffleResults = timed("Shuffle"):
    val allPairs = mapResults.flatMap(_.pairs)
    val byWorker = allPairs.groupBy: (k, _) =>
      cluster.workerIds(Math.floorMod(k.hashCode, cluster.numWorkers))
    Await.result(
      Future.sequence(
        cluster.workerIds.map: id =>
          val pairs   = byWorker.getOrElse(id, Vector.empty)
          val grouped = pairs.groupBy(_._1).map((k, vs) => k -> vs.map(_._2))
          cluster.ask[ShuffleAck](id, ref => WorkerCommand.ReceiveShuffle(grouped, ref))
      ),
      30.seconds
    )
  shuffleResults.foreach(r => println(s"  ${r.workerId}: ${r.keysReceived} keys"))

  // --- Phase 4: Reduce — sum amounts per region ---
  val reduceFn: (String, Vector[String]) => String = (_, values) =>
    values.map(_.toLong).sum.toString

  val reduceResults = timed("Reduce"):
    Await.result(
      cluster.askAll[ReduceResult](ref => WorkerCommand.RunReduce(reduceFn, ref)),
      30.seconds
    )

  val results = reduceResults.flatMap(_.results)
  results.foreach((k, v) => println(s"  $k → $v"))

  cluster.shutdown()
