= Apache Druid & Course Conclusion

== \

#align(center + horizon,
  image("../assets/druid-logo.svg", width: 60%)
)

== Apache Druid — when massive data meets massive demand

Druid is a real-time analytics database designed for the intersection of two hard problems: *ingesting high-velocity streams* and *answering sub-second queries* over petabyte-scale historical data simultaneously.

== Apache Druid — when massive data meets massive demand

#table(
  columns: (1fr, 1fr),
  [*Course concept*], [*Druid mechanism*],
  [Columnar storage (Day 2)], [Per-segment column files, dictionary encoding],
  [Parquet / Kafka ingestion (Days 2–3)], [Streaming ingestion via Kafka; batch via S3 / HDFS],
  [Vectorized execution (Day 3)], [SIMD-friendly column scans over compressed segments],
  [Pre-aggregation (Day 3)], [Rollup at ingest time — rows collapsed into aggregated cubes],
  [Probabilistic DS (Day 4)], [HyperLogLog and quantile sketches as native column types],
  [Incremental computation (Day 4)], [Real-time segments merged continuously into historical ones],
)

== Apache Druid — architecture

Druid separates *ingestion*, *storage*, and *query* into independent services that scale independently.

- *Overlord + MiddleManagers* — coordinate and execute ingestion tasks (streaming or batch)
- *Historical nodes* — serve immutable, fully indexed segments from deep storage (S3 / GCS)
- *Brokers* — receive queries, fan out to Historicals and Realtimes, merge results
- *Real-time tasks* — ingest live Kafka streams into *in-memory segments*; publish to deep storage on completion
- *Deep storage* — S3 or HDFS; the source of truth; Historical nodes load segments from it on demand

The key property: *real-time and historical data are queryable simultaneously*. A query spanning today (in memory) and last year (on S3) returns a unified result with sub-second latency on the recent portion.

== Apache Druid — rollup and sketches

Druid's most aggressive optimisation is *rollup*: at ingest time, rows with the same dimensions and timestamp granularity are collapsed into a single aggregated row.

```json
{ "ts": "2024-01-01T10:00:00", "country": "FR", "page": "/home",
  "views": 1, "uniq_users": "HLL_sketch" }
```

A billion raw events become millions of pre-aggregated rows. Queries that would scan 1 TB scan 10 GB instead.

Sketches (`HyperLogLog`, `quantilesDoublesSketch` from the Apache DataSketches library) are stored *as column values* — they merge exactly at query time. The incremental `kappa` model you saw in the differential dataflow section is what Druid implements natively, at ingest speed.

== Course conclusion — three principles

Every system in this course, from SQLite to Druid, is an expression of three engineering principles:

#align(center,
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1cm,
    align: top,
    [
      *Think ahead* \
    ],
    [
      *Algorithms matter* \
    ],
    [
      *Precompute aggressively* \
    ],
  )
)
