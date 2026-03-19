#import "../style.typ": *

#show: lab-theme.with(
  title: [Lab 2.2 — Spark Internals: Plans, Caching, and RDDs],
  session: [Session 2.2 — Apache Spark & Query Execution Internals],
  format: [Individual hands-on lab],
  tools: [Scala 2.13, Spark 4.0.2, scala-cli, Java 17+],
)

= Objective

Observe Spark's execution engine on a real dataset — not in theory but through
query plans, timing measurements, and the Spark UI. You will convert raw CSV data
to Parquet in two lines, read and interpret physical plans, measure the concrete
impact of caching, and implement iterative KMeans on RDDs to cluster global
weather stations into climate zones.

= Setup

== Prerequisites

- Java 17 or later (`java -version`)
- `scala-cli` (#link("https://scala-cli.virtuslab.org")[scala-cli.virtuslab.org])

All exercises run in Spark local mode — no cluster required. The Spark UI is
available at #link("http://localhost:4040")[localhost:4040] while any exercise
is running.

== Dataset — NOAA Global Surface Summary of the Day

Daily weather observations from ~10 000 stations worldwide. One CSV file per
station, ~365 rows each. Key columns: `STATION`, `DATE`, `LATITUDE`,
`LONGITUDE`, `NAME`, `TEMP` (°F), `DEWP` (dew point °F), `SLP` (sea-level
pressure hPa), `WDSP` (wind speed knots), `PRCP` (precipitation inches).
Missing values are coded as `9999.9` / `999.9` / `99.99`.

Download one year (~300 MB compressed, ~4.7 M rows uncompressed):

```bash
mkdir -p data/noaa/raw
curl -L -o data/noaa/2023.tar.gz \
  "https://www.ncei.noaa.gov/data/global-summary-of-the-day/archive/2023.tar.gz"
tar -xzf data/noaa/2023.tar.gz -C data/noaa/raw/
```

Verify the download:

```bash
scala-cli run assets/setup.scala
```

This prints the Spark version and the row count. If you see ~4–5 million rows,
you are ready.

= Exercise 1 — Two lines to Parquet

Open `assets/ex1.scala`. It reads the entire NOAA directory as CSV and writes
it as Parquet — two lines of transformation code.

```bash
scala-cli run assets/ex1.scala
```

== Tasks

+ Compare directory sizes:
  ```bash
  du -sh data/noaa/raw data/noaa/2023.parquet
  ```
  How large is the compression ratio? Why does Parquet outperform raw CSV here —
  think about both column encoding and the nature of weather data (many repeated
  values per station, slow-changing temperatures).

+ The file runs the same filter (`TEMP < 32`, i.e. freezing) on both the CSV
  and the Parquet and calls `explain("formatted")` on each. Locate `PushedFilters`
  in the Parquet plan. What does the engine skip at scan time that it cannot skip
  on CSV?

+ Change the filter to `TEMP.cast("double") + 0 < 32` on the Parquet path.
  Does `PushedFilters` still appear? Why not?

= Exercise 2 — Reading a physical plan

Still in `ex1.scala`, inspect the plan for the join query: per-station annual
mean temperature, joined to the station dimension extracted from the same dataset.

+ Which join strategy did Spark choose? Look for `BroadcastHashJoin` or
  `SortMergeJoin`. Why did it choose that strategy for the station dimension?

+ How many `Exchange` nodes appear in the default plan? Each one is a full
  network shuffle. How many stages does that imply?

+ Force a sort-merge join:
  ```scala
  spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
  ```
  Run `explain("formatted")` again. How many `Exchange` nodes appear now?
  What is the concrete cost of losing the broadcast optimisation?

+ Which operators carry a `*(N)` prefix? What does that prefix mean, and which
  operators in the plan are *outside* a WholeStageCodeGen boundary?

The `readLine()` call at the end of the exercise keeps the Spark context alive.
Open #link("http://localhost:4040")[localhost:4040], navigate to *Jobs* and *Stages*,
and inspect the DAG visualisation for the join query before pressing Enter.

= Exercise 3 — Caching

Open `assets/ex2.scala`. It runs the same per-station aggregation five times
with and without caching, printing elapsed time for each run.

```bash
scala-cli run assets/ex2.scala
```

== Tasks

+ Record the timing output. Without caching, runs 2–5 should be roughly equal
  (each re-reads Parquet from disk). With caching, run 1 materialises the cache
  and subsequent runs read from JVM heap. What happens to run 1 with cache?

+ Open the Storage tab (`localhost:4040/storage`) while the cached run executes.
  What fraction of the DataFrame fits in memory? What happens when you call
  `df.unpersist()`?

+ The file also runs with `DISK_ONLY` persistence. Compare the timing with
  `MEMORY_AND_DISK`. Under what workload would `DISK_ONLY` be a better choice?

+ Describe a pipeline where calling `cache()` would make performance *worse*.

= Exercise 4 (bonus) — Iterative KMeans: clustering climate zones

Open `assets/ex3.scala`. It provides:

- `case class StationFeatures(temp, dewp, wdsp, prcp)` — the feature type.
- `loadFeatures(spark, path)` — reads NOAA Parquet, aggregates per-station annual
  means, and returns an `RDD[StationFeatures]`.
- Helper functions `distance`, `nearest`, `addFeatures`, `scaleFeatures`.
- A `timed` utility to measure wall-clock execution of each run.
- The `kmeans` stub — *yours to implement*.

The `kmeans` function body contains the algorithm steps in plain English.
Implement it using the RDD API before uncommenting and running the timing harness.

```bash
scala-cli run assets/ex3.scala
```

== Tasks

+ Implement `kmeans` following the commented steps. Run it once to verify the
  centroids look reasonable before moving to the timing comparison.

+ Uncomment the body of `ex3()` and run both the uncached and cached variants.
  The uncached version rebuilds the full lineage from the Parquet source on every
  iteration — how does the uncached time grow across iterations?

+ With `rdd.cache()`, the first iteration materialises the partitions; subsequent
  ones read from memory. Does per-iteration time stabilise after the first cached
  run?

+ The script prints cluster centroids. Match them against known climate zones
  (tropical: high temp + high dewpoint; polar: low temp; arid: low dewpoint +
  low precip; temperate: moderate everything). Do the centroids correspond to
  recognisable zones?

+ Why is this algorithm difficult to express cleanly with the DataFrame API
  without an explicit `checkpoint()` or `cache()` between iterations?

+ *(Hard)* The assignment step shuffles all raw feature vectors across the
  network. Rewrite it with `aggregateByKey` to compute the cluster sum and count
  in a single combiner pass — sending only `(StationFeatures, Long)` per
  partition instead of all points. How does this reduce shuffle volume?

= Key Takeaways

- Parquet reduces I/O by an order of magnitude for selective queries. Pushed
  filters skip entire row groups *before* any data value is decoded — but only
  when the filter column is not wrapped in a function.
- `BroadcastHashJoin` eliminates shuffles for small dimension tables. One
  configuration knob (`autoBroadcastJoinThreshold`) controls the threshold.
  Knowing when it fires — and when it silently falls back to sort-merge — is
  essential for tuning.
- Caching pays off only when the same DataFrame is consumed by multiple actions.
  Use the Storage UI and timing to verify, not intuition.
- Iterative algorithms that mutate shared state between rounds require the RDD
  API with explicit `cache()`. Without it, Spark rebuilds the full lineage from
  the source on every iteration — a quadratic disaster on large datasets.
