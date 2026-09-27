//> using scala 3.3.6
//> using dep "org.apache.spark:spark-sql_2.13:4.0.2"
//> using javaOpt "--add-opens=java.base/java.lang=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.lang.invoke=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.io=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.net=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.nio=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/java.util=ALL-UNNAMED"
//> using javaOpt "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.rdd.RDD
import org.apache.spark.sql.Row

// Per-station annual climate features, derived from NOAA daily readings.
// NOAA missing-value sentinels: TEMP/DEWP >= 9000, WDSP >= 999, PRCP >= 99.
case class StationFeatures(
  temp: Double,  // mean daily temperature   (°F)
  dewp: Double,  // mean dew point           (°F)
  wdsp: Double,  // mean wind speed          (kt)
  prcp: Double,  // mean precipitation       (in/day)
) {

  // Add two StationFeatures together
  def +(that: StationFeatures): StationFeatures =
    StationFeatures(
      this.temp + that.temp,
      this.dewp + that.dewp,
      this.wdsp + that.wdsp,
      this.prcp + that.prcp,
    )
  
  // Divide a StationFeatures by a scalar
  def /(n: Double): StationFeatures =
    StationFeatures(
      this.temp / n,
      this.dewp / n,
      this.wdsp / n,
      this.prcp / n,
    )
}

object StationFeatures:
  def fromRow(row: Row): StationFeatures =
    StationFeatures(
      row.getDouble(0),
      row.getDouble(1),
      row.getDouble(2),
      row.getDouble(3),
    )
// Build one StationFeatures per station from the NOAA Parquet file.
// Stations with fewer than 300 days of valid readings are excluded.
def loadFeatures(spark: SparkSession, path: String): RDD[StationFeatures] =
  import spark.implicits._
  spark.read.parquet(path)
    .filter(col("TEMP") < 9000 && col("DEWP") < 9000 &&
            col("WDSP") < 999  && col("PRCP") < 99)
    .groupBy("STATION")
    .agg(
      avg("TEMP").as("mean_temp"),
      avg("DEWP").as("mean_dewp"),
      avg("WDSP").as("mean_wdsp"),
      avg("PRCP").as("mean_prcp"),
      count("*").as("n_days"),
    )
    .filter(col("n_days") >= 300)
    // Scala 3 means no encoder derivation possible, so this part is a bit of a hack
    .select("mean_temp", "mean_dewp", "mean_wdsp", "mean_prcp")
    .rdd
    .map(StationFeatures.fromRow)

// ── Distance & centroid helpers ────────────────────────────────────────────

def distance(a: StationFeatures, b: StationFeatures): Double =
  math.sqrt(
    math.pow(a.temp - b.temp, 2) +
    math.pow(a.dewp - b.dewp, 2) +
    math.pow(a.wdsp - b.wdsp, 2) +
    math.pow(a.prcp - b.prcp, 2)
  )

def nearest(v: StationFeatures, centroids: Array[StationFeatures]): StationFeatures =
  centroids.minBy(c => distance(v, c))

// ── KMeans — implement me! ─────────────────────────────────────────────────
//
// Algorithm:
//   1. Pick k random points from `points` as the initial centroids.
//      Hint: RDD.takeSample(withReplacement = false, num = k, seed = 7L)
//
//   2. Repeat `iterations` times:
//      a. Broadcast the current centroids to all executors.
//      b. Map each point to (clusterIndex, (point, 1L))  using `nearest`.
//      c. Sum partial results with reduceByKey, using `StationFeatures.+` for
//         the feature accumulator and (+) for the count.
//      d. Divide the sum by the count with `StationFeatures./` to get new centroids.
//      e. Collect, destroy the broadcast, and loop.
//
//   3. Return the final centroids.

def kmeans(points: RDD[StationFeatures], k: Int, iterations: Int): Array[StationFeatures] =
  ???

// ── Entry point ────────────────────────────────────────────────────────────

@main def ex3(): Unit =
  val spark = SparkSession.builder()
    .master("local[*]")
    .appName("lab-2.2-ex3")
    .config("spark.sql.shuffle.partitions", "8")
    .getOrCreate()

  spark.sparkContext.setLogLevel("WARN")

  def timed(label: String)(block: => Array[StationFeatures]): Array[StationFeatures] =
    val t0 = System.nanoTime()
    val result = block
    println(f"  [$label] ${(System.nanoTime() - t0) / 1e9}%.3f s")
    result

  // val points = loadFeatures(spark, "data/noaa/2023.parquet")
  //
  // val k          = 5
  // val iterations = 15
  //
  // // ── Without cache ──────────────────────────────────────────────────────
  // // Each iteration re-reads Parquet and re-runs the full aggregation pipeline.
  // println(s"\n=== KMeans without cache ($iterations iterations, k=$k) ===")
  // val resultNocache = timed("no cache")(kmeans(points, k, iterations))
  //
  // // ── With cache ─────────────────────────────────────────────────────────
  // // cache() materialises the feature vectors in JVM heap after the first pass.
  // val cached = points.cache()
  // cached.count() // force materialisation before timing
  //
  // println(s"\n=== KMeans with cache ($iterations iterations, k=$k) ===")
  // val resultCached = timed("cached")(kmeans(cached, k, iterations))
  //
  // cached.unpersist()
  //
  // println("\nCluster centroids (temp °F, dewpoint °F, wind kt, precip in/day):")
  // resultCached.zipWithIndex.foreach { case (c, i) =>
  //   println(f"  cluster $i: temp=${c.temp}%.1f  dewp=${c.dewp}%.1f  wind=${c.wdsp}%.1f  prcp=${c.prcp}%.3f")
  // }
  // println("\nHint: high temp + high dewpoint → tropical; low temp → polar; low dewpoint + low prcp → arid.")

  spark.stop()
