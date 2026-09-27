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
import org.apache.spark.storage.StorageLevel

@main def ex2(): Unit =
  val spark = SparkSession.builder()
    .master("local[*]")
    .appName("lab-2.2-ex2")
    .config("spark.sql.shuffle.partitions", "8")
    .getOrCreate()

  spark.sparkContext.setLogLevel("WARN")

  // def timed(label: String)(block: => Unit): Unit =
  //   val t0 = System.nanoTime()
  //   block
  //   val elapsed = (System.nanoTime() - t0) / 1e9
  //   println(f"  [$label] $elapsed%.3f s")
  //
  // def query(df: org.apache.spark.sql.DataFrame): Unit =
  //   df.filter(col("TEMP") < 9000)
  //     .groupBy("STATION")
  //     .agg(
  //       avg("TEMP").as("avg_temp"),
  //       max("TEMP").as("max_temp"),
  //       count("*").as("n_days")
  //     )
  //     .orderBy("STATION")
  //     .collect()
  //   ()
  //
  // val df = spark.read.parquet("data/noaa/2023.parquet")
  //
  // // ── Without cache ──────────────────────────────────────────────────────
  // println("\n=== Without cache (5 runs — each re-reads Parquet) ===")
  // (1 to 5).foreach(i => timed(s"run $i, no cache")(query(df)))
  //
  // // ── With MEMORY_AND_DISK cache ─────────────────────────────────────────
  // println("\n=== With MEMORY_AND_DISK cache ===")
  // df.cache()
  // (1 to 5).foreach(i => timed(s"run $i, cached")(query(df)))
  // println("Storage tab: http://localhost:4040/storage")
  // df.unpersist()
  //
  // // ── With DISK_ONLY persistence ─────────────────────────────────────────
  // println("\n=== With DISK_ONLY persistence ===")
  // df.persist(StorageLevel.DISK_ONLY)
  // (1 to 3).foreach(i => timed(s"run $i, disk-only")(query(df)))
  // df.unpersist()

  spark.stop()
