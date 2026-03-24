= Spark Structured Streaming

== The Structured Streaming model

Structured Streaming treats the input as an *infinite append-only DataFrame*. Every new batch of records extends the table; the query runs continuously over it.

```scala
val events = spark.readStream
  .format("json")
  .schema(schema)
  .load("data/input/")

val counts = events
  .groupBy($"userId", window($"ts", "1 minute"))
  .count()

counts.writeStream
  .outputMode("append")
  .format("parquet")
  .option("checkpointLocation", "checkpoints/")
  .start()
```

The DataFrame API is unchanged — the same optimizer, same physical plans, same code generation.

== Trigger modes

How often Spark wakes up to process new data:

#table(
  columns: (auto, 1fr, auto),
  [*Trigger*], [*Behavior*], [*Min latency*],
  [`ProcessingTime("1 minute")`], [Micro-batch: collect all records arrived in the interval, then process], [~seconds],
  [`Once`], [Run exactly one micro-batch then stop — for scheduled jobs], [batch],
  [`AvailableNow`], [Process all available data in one or more micro-batches, then stop], [batch],
  [`Continuous("1 second")`], [Experimental low-latency mode; processes records as they arrive], [~ms],
)

Continuous mode offers lower latency but supports fewer operations and is not production-ready for complex queries.

== Output modes

What Spark writes to the sink on each trigger:

#table(
  columns: (auto, 1fr),
  [*Mode*], [*When to use*],
  [Append], [Only new rows since last trigger — for queries with no updates (e.g., stateless filters, windowed aggregations after watermark)],
  [Update], [Only rows that changed since last trigger — for aggregations that produce updates],
  [Complete], [Rewrite the entire result table on every trigger — only for aggregations without a watermark],
)

Not all modes are valid for all query types. Spark validates the combination at plan time.

== Watermarks in Spark

Watermarks tell Structured Streaming how late data can arrive before a window is closed.

```scala
events
  .withWatermark("ts", "10 seconds")   // tolerate up to 10s of late arrival
  .groupBy(window($"ts", "1 minute"))
  .count()
```

- Spark tracks the maximum event timestamp seen so far
- The watermark advances to `max(ts) − threshold`
- Windows whose end time is below the watermark are finalized and emitted in Append mode
- Records arriving after their window's watermark are *dropped*

Watermarks enable exactly-once semantics in Append mode by bounding state size.

== Where Spark Streaming fits

#table(
  columns: (1fr, 1fr),
  [*Good fit*], [*Poor fit*],
  [Team already uses Spark for batch], [Sub-second latency requirements],
  [SQL-first pipelines with DataFrame API], [Complex event time logic (arbitrary out-of-order)],
  [Micro-batch latency (seconds) is acceptable], [Fine-grained stateful processing per key],
  [Unified batch + streaming codebase], [Dynamic parallelism adjustment at runtime],
)

Structured Streaming is a strong choice when you need *streaming semantics with a batch mindset*. When you need true event-at-a-time processing with full state control, Flink is the right tool.
