#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Partitioning, Shuffles & Tuning

== \

#hero[Every shuffle is a network call \ for every row. \ Minimize them.]

== What a shuffle is

A shuffle is the process of redistributing data across partitions so that rows with the same key land on the same partition.

Mechanically:
1. Each task in stage N writes its output to local disk, partitioned by the target partition key (the *shuffle write*)
2. Each task in stage N+1 fetches the relevant partition files from all executors (the *shuffle read*)
3. The fetched data is sorted, merged, and processed

Shuffles are expensive because they involve *serialization*, *disk I/O*, and *network transfer* for every row.

#v(0.5em)
#align(center,
  fletcher.diagram(
    spacing: (4cm, 0.9cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0), [Executor A], fill: rgb("#e3f2fd"), width: 2.5cm, inset: 10pt),
    node((0, 1), [Executor B], fill: rgb("#e3f2fd"), width: 2.5cm, inset: 10pt),
    node((0, 2), [Executor C], fill: rgb("#e3f2fd"), width: 2.5cm, inset: 10pt),

    node((1, 0), [Executor A], fill: rgb("#e8f5e9"), width: 2.5cm, inset: 10pt),
    node((1, 1), [Executor B], fill: rgb("#e8f5e9"), width: 2.5cm, inset: 10pt),
    node((1, 2), [Executor C], fill: rgb("#e8f5e9"), width: 2.5cm, inset: 10pt),

    edge((0,0),(1,0), "->"),
    edge((0,0),(1,1), "->"),
    edge((0,0),(1,2), "->"),
    edge((0,1),(1,0), "->"),
    edge((0,1),(1,1), "->"),
    edge((0,1),(1,2), "->"),
    edge((0,2),(1,0), "->"),
    edge((0,2),(1,1), "->"),
    edge((0,2),(1,2), "->"),
  )
)
#align(center, text(size: 9pt, fill: luma(120))[
  Every executor writes to every other executor — $N^2$ data flows for $N$ executors.
])

== Partition count: the key knob

*Default*: `spark.sql.shuffle.partitions = 200`

Too few: each task processes too much data → spills to disk, OOM risk, long task time.

Too many: overhead of scheduling, launching, and tracking thousands of tiny tasks dominates computation time.

Rule of thumb: target *100 MB–1 GB of data per partition after the shuffle*. For a 100 GB dataset, `100–1000` partitions is reasonable.

With *Adaptive Query Execution* (AQE, Spark 3.0+), Spark can coalesce small post-shuffle partitions automatically — set `spark.sql.adaptive.enabled = true` and let it tune partition count.

== Partition skew

Skew occurs when a small number of partitions hold a disproportionate share of the data — e.g., 90% of orders have `region = NULL`.

Symptoms: one long-running task while all others finish, OOM errors on specific executors, "straggler" stage in the UI.

*Solutions:*

*Salting*: add a random suffix to the skewed key to spread it across `N` partitions. Requires a corresponding re-aggregation step after the join/agg.

*AQE skew join optimization*: AQE detects skewed partitions after the shuffle and automatically splits them into smaller sub-tasks. Enabled with `spark.sql.adaptive.skewJoin.enabled = true`.

*Filter and handle separately*: isolate the dominant key, process it apart, union back.

== Avoiding shuffles — broadcast joins

If one side of a join fits in memory on each executor, broadcast it:

```scala
import org.apache.spark.sql.functions.broadcast

orders.join(broadcast(countries), "country_code")
```

No shuffle on either side. The `countries` table is serialized on the driver and sent to every executor once.

Auto-broadcast threshold: `spark.sql.autoBroadcastJoinThreshold` (default: 10 MB). Increase for large in-memory clusters:

```
spark.sql.autoBroadcastJoinThreshold = 100MB
```

Force-disable broadcasting (e.g., when the table is large but Catalyst underestimates): `broadcast(df)` explicitly, or set threshold to `-1`.

== Caching

`df.cache()` / `df.persist()` stores the DataFrame's data in memory across actions.

*Use when:* the same DataFrame is consumed by multiple downstream actions (e.g., a filter result used in two different joins).

*Do not use when:*
- The DataFrame is used only once — caching consumes memory and adds a write step
- The DataFrame does not fit in memory — spilling to disk can be slower than recomputing from Parquet with predicate pushdown

Cache is *lazy*: `df.cache()` registers intent; the data is actually cached on the first action that touches it.

Unpersist explicitly with `df.unpersist()`. Spark's LRU eviction policy is not always predictable in complex pipelines.

== Adaptive Query Execution (AQE)

AQE re-optimizes the query *at runtime*, after each shuffle materializes:

- *Partition coalescing*: merge empty or tiny post-shuffle partitions into fewer tasks
- *Skew join handling*: split large skewed partitions, replicate the matching side
- *Join strategy switching*: if runtime stats reveal one side is smaller than estimated, switch from SMJ to BHJ mid-execution

Enable with:
```
spark.sql.adaptive.enabled = true
spark.sql.adaptive.coalescePartitions.enabled = true
spark.sql.adaptive.skewJoin.enabled = true
```

AQE does not replace understanding partitioning — it reduces the cost of getting it wrong.

== Anatomy of a slow job — checklist

#table(
  columns: (auto, 1fr),
  [*Symptom*], [*Likely cause*],
  [One task takes 10× longer than others], [Partition skew — salt the key or enable AQE skew join],
  [OOM on executors], [Partition too large — increase shuffle partitions or broadcast smaller side],
  [Hundreds of tiny tasks], [Too many shuffle partitions — reduce or enable AQE coalescing],
  [Full-table scans on Parquet], [Missing predicate pushdown — check `PushedFilters` in the plan],
  [Unexpected SMJ instead of BHJ], [Table stats not collected — run `ANALYZE TABLE`],
  [Python UDF stage takes 10× longer], [Cross-process serialization — replace with built-in functions],
)
