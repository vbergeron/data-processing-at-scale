# Data Processing at Scale — Course Plan

**Level:** Master 2  
**Duration:** ~20 hours (12 sessions × 1h30 + 1 dedicated lab × 1h30, across 4 days)  
**Prerequisites:** Databases, Python/SQL proficiency, basic systems knowledge, Apache Kafka (covered earlier in the year)

---

## Day 1 — Foundations (4h30, 3 sessions)

**Learning outcomes:** Students can explain why single-machine processing fails at scale, write Scala programs using FP principles that are safe to distribute, and reason about partitioning, replication, and consistency trade-offs.

**1.1 — Introduction & Motivation**

- Course philosophy: vocabulary, judgment and intuition — what an LLM can't give you
- Course format, schedule and evaluation
- Why data processing at scale? What big data made possible, the data explosion
- Throughput as the unifying measure
- Limits of single-machine processing: vertical vs horizontal scaling

**1.2 — Distributed Programming with Scala**

- History of FP: λ-calculus, LISP, ML, Scala
- What is Scala: positioning, compilation backends, the JVM ecosystem (Spark, Kafka, Akka/Pekko, Flink, Druid, Trino)
- Principles of FP and their distributed payoff: functions as values, immutability, referential transparency, pure functions
- Data modeling with traits, ADTs (case classes, sealed traits, enums), and generics
- **Lab:** [Benchmarking a single-node pipeline to its breaking point](../labs/1.2-single-node-benchmark/main.typ) — Scala, scala-cli, SQLite (JDBC), system monitor

**1.3 — Distributed Systems Fundamentals**

- Partitioning strategies: hash, range, consistent hashing; rebalancing and hot spots
- Partial failures, the 8 fallacies of distributed computing, failure taxonomy, timeouts
- Replication: leader/follower (sync vs async), split-brain, leaderless quorums (W + R > N)
- CAP theorem and its practical implications
- Consistency models: linearizability, eventual, causal
- **Lab:** [Observing partition and replication behavior in a distributed KV store](../labs/1.3.1-distributed-kv/main.typ)
- **Lab:** [Distributed batch processing and partitioning](../labs/1.3.2-batch-processing/main.typ)

---

## Day 2 — Storage & Query Execution (3h, 2 sessions)

**Learning outcomes:** Students can choose the right storage format for a workload, read a Spark query plan, identify the join strategy and shuffle boundaries, and explain why the optimizer chose that plan.

**2.1 — Storage Formats & Distributed File Systems**

- From MapReduce to files: why the file format is the first optimization
- Distributed file systems: HDFS (read/write paths, NameNode HA, ZooKeeper, federation), object storage (S3, GCS)
- Text formats: CSV, JSON, NDJSON
- Binary row formats: MessagePack/CBOR, Protobuf, Avro, FlatBuffers/Cap'n Proto, SQLite — schema evolution and serialization
- Columnar formats: encodings (dictionary, delta, RLE), Parquet internals and Dremel encoding, Arrow
- Emerging formats: Lance, Vortex, F3
- Lakehouse table formats (Iceberg, Delta Lake, Hudi): metadata, time travel, partition pruning
- **Demo:** [Comparing query performance across file formats and partitioning schemes](../labs/2.1-file-formats/main.typ)

**2.2 — Apache Spark & Query Execution Internals**

- From MapReduce to Spark: RDDs, cluster architecture, Kubernetes
- Lazy evaluation, the DAG, stages and tasks, narrow vs wide dependencies
- DataFrames, Datasets and Spark SQL — one plan, three syntaxes; Scala vs Python
- Query execution models: pull (Volcano) vs push, vectorized (batch) vs compiled (JIT)
- The Catalyst optimizer: logical plan, physical plan, join strategies, cost-based optimization
- Tungsten: whole-stage code generation, off-heap memory management
- Partitioning, shuffles, skew, broadcast joins, caching, AQE, and performance tuning
- **Demo:** [Reading and optimizing Spark query plans on a multi-GB dataset](../labs/2.2-spark-query-plans/main.typ)

---

## Day 3 — Stream Processing & Real-Time Analytics (3h, 2 sessions)

**Learning outcomes:** Students can build a Flink pipeline with stateful operators, windowed aggregations, and fault-tolerance guarantees, and model an analytics workload in ClickHouse with appropriate ORDER BY and materialized views.

**3.1 — Data Streaming at Scale**

- Stream processing theory: bounded vs unbounded data, batch vs micro-batch vs streaming, backpressure, push vs pull
- Monotonicity and the CALM theorem, idempotency, delivery guarantees
- The problem of time: tumbling, sliding and session windows, watermarks
- Kafka recap (10 min): topics, partitions, offsets, and what Kafka does not do — the contract stream processors build on
- Spark Structured Streaming: trigger modes, output modes, watermarks, where it fits
- Flink architecture: JobManager, TaskManagers, parallelism, operator graph
- DataStream API: sources, transformations, sinks, watermark strategies
- Event time vs processing time — windows, allowed lateness, side outputs
- Keyed state (ValueState, ListState, MapState), state TTL, state backends
- Fault tolerance: checkpointing, savepoints, exactly-once semantics
- Advanced operators: timers, serialization, Async I/O, Broadcast, Keyed Broadcast, testing harness and MiniCluster
- **Lab:** [Portfolio analytics with the Flink DataStream API](../labs/3.1-data-streaming-at-scale/main.typ)

**3.2 — ClickHouse: Real-Time Analytics at Scale**

- History and the OLTP–OLAP continuum: why traditional databases fall short for analytics
- Topology (single node, replicated, sharded with Keeper) and protocols
- MergeTree engine family: write path, merges, ORDER BY, ReplacingMergeTree, deletes
- Storage layout: columnar parts, compression codecs, sparse primary index, skip indexes
- Query execution: vectorized execution, EXPLAIN, system.query_log
- ClickHouse SQL: arrays, approximate aggregation, combinators, SAMPLE, ASOF JOIN
- Materialized views, AggregatingMergeTree and projections for pre-aggregation
- Interoperability and tiered storage
- **Demo:** [Modeling and querying a billion-row analytics dataset in ClickHouse](../labs/3.2-clickhouse/main.typ)

---

## Day 4 — Advanced Topics & Projects (3h, 2 sessions)

**Learning outcomes:** Students can implement and reason about probabilistic data structures (Bloom filter, HLL, CMS, reservoir sampling), explain when incremental computation is correct by construction and when it requires coordination, and scope a data processing project with appropriate architectural choices.

**4.1 — Advanced Topics & Technology**

- *Probabilistic data structures*
  - The case for approximation: trading accuracy for space and speed
  - Bloom filters: membership testing with no false negatives — tuning and variants
  - HyperLogLog: cardinality estimation in kilobytes
  - Count-Min Sketch: frequency estimation in streaming contexts
  - Reservoir sampling: uniform samples in one pass and bounded memory
- *Incremental computation*
  - Recomputation vs incremental maintenance
  - Differential dataflow: processing only the deltas
  - Monotonic vs non-monotonic operators and connection to CALM
  - Real systems: materialized views, incremental ETL, live dashboards
- *Apache Druid & course conclusion*
  - Druid as a synthesis of the course: columnar segments, streaming + batch ingestion, rollup, native sketches

**4.2 — Project Briefing**

- Presentation of available project topics
- Scope, expectations, and deliverables
- Team formation and Q&A

---

## Assessment

**100% project presentation** (separate day, not counted in the ~20h).

Students pick one of the [proposed projects](PROJECTS.md) on Day 4 and present their implementation on a later date. The presentation must demonstrate:

- A working system processing the chosen dataset
- Understanding of the architectural choices and their trade-offs
- Ability to answer questions about internals (query plans, partitioning, delivery guarantees, etc.)

See [PROJECTS.md](PROJECTS.md) and [projects/](../projects/) for available subjects and [DATASETS.md](DATASETS.md) for dataset details.

---

## Recommended Reading

- *Designing Data-Intensive Applications* — Martin Kleppmann
- *Streaming Systems* — Akidau, Chernyak, Lax
- *Spark: The Definitive Guide* — Chambers, Zaharia
- *The Data Engineering Cookbook* (open-source)
