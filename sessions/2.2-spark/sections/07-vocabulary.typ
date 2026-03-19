#import "../../style.typ": hero

= Wrap-Up

== \

#hero[A slow Spark job is almost always \ a *shuffle you didn't need* \ or a *filter that arrived too late*.]

== Key vocabulary

#table(
  columns: (auto, 1fr),
  [*Term*], [*Definition*],
  [Transformation], [Lazy operation on a DataFrame; builds the plan, executes nothing],
  [Action], [Triggers execution; returns a result or writes output],
  [Stage], [Maximal sequence of operations that can run without a shuffle],
  [Task], [One stage applied to one partition; the unit of parallelism],
  [Shuffle], [Redistribution of data across partitions; always crosses the network],
  [Volcano model], [Iterator-based execution: one tuple at a time via `next()`],
  [Vectorized execution], [Batch-at-a-time using column arrays; enables SIMD],
  [Whole-Stage CodeGen], [Tungsten's JIT: entire pipeline compiled into one Java class],
  [Catalyst], [Spark's optimizer: logical plan → physical plan via rule-based rewrites],
  [BHJ], [Broadcast hash join: no shuffle; smaller side sent to all executors],
  [SMJ], [Sort-merge join: both sides shuffled and sorted; works at any scale],
  [Predicate pushdown], [Filter evaluated at scan time, skipping row groups in Parquet],
  [Projection pruning], [Drop unused columns before deserialization],
  [AQE], [Adaptive Query Execution: re-optimizes at runtime using shuffle statistics],
  [Skew], [A few partitions hold most of the data; causes straggler tasks],
)

== One sentence to remember

The Catalyst optimizer rewrites your query for free — but only if you give it *structured expressions* it can inspect. Push filters early, broadcast small tables, and keep Python out of the hot path.

== Further reading

- *Spark: The Definitive Guide* — Chambers & Zaharia (O'Reilly, 2018) — Chapters 15–19 on query execution internals
- #link("https://www.databricks.com/blog/2015/04/28/project-tungsten-bringing-spark-closer-to-bare-metal.html")[Project Tungsten: Bringing Spark Closer to Bare Metal] — Databricks blog, 2015
- #link("https://people.csail.mit.edu/matei/papers/2015/sigmod_spark_sql.pdf")[Spark SQL: Relational Data Processing in Spark] — Armbrust et al., SIGMOD 2015
- #link("https://databricks.com/blog/2017/08/31/cost-based-optimizer-in-apache-spark-2-2.html")[Cost-Based Optimizer in Apache Spark 2.2] — Databricks blog, 2017
- #link("https://www.vldb.org/pvldb/vol13/p2195-shvachko.pdf")[Apache Spark Adaptive Query Execution] — VLDB 2020
