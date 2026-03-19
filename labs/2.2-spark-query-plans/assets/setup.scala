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

@main def setup(): Unit =
  val spark = SparkSession.builder()
    .master("local[*]")
    .appName("lab-2.2-setup")
    .getOrCreate()

  spark.sparkContext.setLogLevel("WARN")

  // val df = spark.read
  //   .option("header", "true")
  //   .csv("data/noaa/raw/")
  //
  // val count = df.count()
  // println(s"Spark ${spark.version} — ${Runtime.getRuntime.availableProcessors()} cores")
  // println(s"Rows loaded: $count")
  // println(s"Columns    : ${df.columns.mkString(", ")}")
  // df.show(3, truncate = false)
  //
  // if count > 4_000_000 then println("Dataset OK — ready for exercises.")
  // else println("WARNING: fewer rows than expected, check the download.")

  spark.stop()
