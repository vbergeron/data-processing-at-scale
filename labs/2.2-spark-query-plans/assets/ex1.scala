//> using scala 2.13.16
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

@main def ex1(): Unit =
  val spark = SparkSession.builder()
    .master("local[*]")
    .appName("lab-2.2-ex1")
    .config("spark.sql.shuffle.partitions", "8")
    .getOrCreate()

  spark.sparkContext.setLogLevel("WARN")

  // ── Exercise 1: two lines to Parquet ─────────────────────────────────────

  // val raw = spark.read
  //   .option("header", "true")
  //   .option("inferSchema", "true")
  //   .csv("data/noaa/raw/")
  //
  // raw
  //   .write
  //   .mode("overwrite")
  //   .parquet("data/noaa/2023.parquet")
  //
  // println("Conversion done. Run: du -sh data/noaa/raw data/noaa/2023.parquet")

  // ── Exercise 1 & 2: comparing plans ──────────────────────────────────────

  // val parquet = spark.read.parquet("data/noaa/2023.parquet")
  //
  // val freezingCsv     = raw.filter(col("TEMP") < 32.0)
  // val freezingParquet = parquet.filter(col("TEMP") < 32.0)
  //
  // println("\n=== Plan: filter on CSV ===")
  // freezingCsv.explain("formatted")
  //
  // println("\n=== Plan: filter on Parquet (look for PushedFilters) ===")
  // freezingParquet.explain("formatted")

  // ── Exercise 2: join plan ─────────────────────────────────────────────────

  // val stations = parquet
  //   .select("STATION", "NAME", "LATITUDE", "LONGITUDE")
  //   .distinct()
  //
  // val annualMeans = parquet
  //   .filter(col("TEMP") < 9000)
  //   .groupBy("STATION")
  //   .agg(avg("TEMP").as("avg_temp_f"), count("*").as("n_days"))
  //
  // val joined = annualMeans
  //   .join(stations, "STATION")
  //   .select("STATION", "NAME", "LATITUDE", "LONGITUDE", "avg_temp_f", "n_days")
  //   .orderBy(col("avg_temp_f").desc)
  //
  // println("\n=== Plan: annual mean joined to station dimension ===")
  // joined.explain("formatted")
  //
  // joined.show(10, truncate = false)
  //
  // // Inspect the Spark UI before the program exits.
  // // Jobs, stages, and the DAG visualisation are available at http://localhost:4040
  // println("\nSpark UI: http://localhost:4040  — press Enter to stop the application.")
  // scala.io.StdIn.readLine()
  //
  // // Uncomment to force sort-merge join and compare:
  // // spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
  // // println("\n=== Plan: sort-merge join forced ===")
  // // joined.explain("formatted")

  spark.stop()
