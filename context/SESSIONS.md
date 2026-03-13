# Data Processing at Scale — Course Plan

**Level:** Master 2  
**Duration:** 21 hours (14 sessions × 1h30, across 4 days)  
**Prerequisites:** Databases, Python/SQL proficiency, basic systems knowledge, Apache Kafka (covered earlier in the year)

---

## Day 1 — Foundations & Data Modeling (7h30, 5 sessions)

**Learning outcomes:** Students can explain why single-machine processing fails at scale, reason about partitioning and replication trade-offs, implement a MapReduce computation, design a denormalized data model for analytical workloads, and estimate the cost of a data operation from first principles.

**1.1 — Introduction & Motivation**

- Why data processing at scale? Volume, velocity, variety
- Limits of single-machine processing
- Vertical vs horizontal scaling
- Overview of the modern data stack
- Taxonomy: batch, micro-batch, streaming
- **Lab:** [Benchmarking a single-node pipeline to its breaking point](labs/1.1-single-node-benchmark/main.typ) — any language, SQLite, system monitor

**1.2 — Distributed Systems Fundamentals**

- Network partitions, failures, and fallacies of distributed computing
- CAP theorem and its practical implications
- Consistency models: strong, eventual, causal
- Partitioning strategies: hash, range, consistent hashing
- Replication: leader/follower, quorum-based
- **Demo:** [Observing partition and replication behavior in a distributed KV store](labs/1.2-distributed-kv/main.typ)

**1.3 — Batch Processing: MapReduce & Beyond**

- The MapReduce programming model
- Shuffle, sort, and combiners
- Limitations of MapReduce (multi-stage, iterative workloads)
- From Hadoop to modern engines
- Data locality and fault tolerance
- **Demo:** [Implementing word-count and join in a MapReduce-style framework](labs/1.3-mapreduce/main.typ)

**1.4 — Data Modeling at Scale**

- Why modeling changes at scale: cost of joins, denormalization trade-offs
- Star schemas, wide tables, and pre-aggregation patterns
- Normalization vs denormalization: when and why
- **Demo:** [Designing a star schema and comparing join strategies in PostgreSQL](labs/1.4-star-schema/main.typ)

**1.5 — Cost Modeling & Performance Reasoning**

- The memory and storage hierarchy: L1/L2/L3 cache, RAM, SSD, network, object storage — bandwidth and latency at each level
- Sequential vs random access: why the access pattern matters more than the medium
- Columnar vs row-oriented storage: a cache-efficiency argument, not just a format choice
- The cost anatomy of a shuffle: serialization, network transfer, disk spill, deserialization
- Amdahl's law applied to data parallelism: what serializes and what doesn't
- Strong vs weak scaling: adding machines to go faster vs adding machines to handle more data
- Back-of-the-envelope estimation: how long should this query take? How to sanity-check before running
- Why "just add more nodes" is not always the answer: coordination overhead, straggler effects, diminishing returns

---

## Day 2 — Storage & Query Execution (3h, 2 sessions)

**Learning outcomes:** Students can choose the right storage format for a workload, read a Spark query plan, identify the join strategy and shuffle boundaries, and explain why the optimizer chose that plan.

**2.1 — Storage Formats & Distributed File Systems**

- Distributed file systems: HDFS, object storage (S3, GCS)
- NoSQL databases: trade-offs, advantages
- File formats: Parquet, ORC, Avro — trade-offs and internals
- Schema evolution and data serialization
- Lakehouse table formats (Delta Lake, Iceberg, Hudi): metadata, time travel, partition pruning
- **Demo:** [Comparing query performance across file formats and partitioning schemes](labs/2.1-file-formats/main.typ)

**2.2 — Apache Spark & Query Execution Internals**

- Lazy evaluation and DAG-based execution plans
- Query execution models: Volcano (tuple-at-a-time) vs vectorized (batch) vs compiled (JIT)
- Push vs pull-based execution pipelines
- The Catalyst optimizer: logical plan, physical plan, cost-based optimization
- Tungsten: whole-stage code generation, off-heap memory management
- DataFrames and the Spark SQL API
- Partitioning, shuffles, and performance tuning
- **Demo:** [Reading and optimizing Spark query plans on a multi-GB dataset](labs/2.2-spark-query-plans/main.typ)

---

## Day 3 — Stream Processing & Real-Time Analytics (6h, 4 sessions)

**Learning outcomes:** Students can build a Flink pipeline that consumes from Kafka, implement windowed aggregations with watermarks, classify a computation as monotonic or non-monotonic using the CALM framework, and model an analytics workload in ClickHouse with appropriate ORDER BY and materialized views.

**3.1 — Apache Flink: Stream Processing Engine**

- Kafka recap (10 min): topics, partitions, consumer groups, offsets, and delivery guarantees — the contract Flink builds on
- From Kafka to Flink: consuming events vs processing them
- Flink architecture: JobManager, TaskManagers, parallelism
- DataStream API and Flink SQL
- Event time vs processing time — assigning timestamps and watermarks
- Flink's relationship to Kafka: sources, sinks, and exactly-once integration
- **Demo:** [Building a Flink pipeline on a Kafka source](labs/3.1-flink-pipeline/main.typ)

**3.2 — Advanced Flink: Windows, State & Guarantees**

- Windowing: tumbling, sliding, session windows
- Watermarks and handling late data
- Stateful processing: keyed state, operator state, state backends (RocksDB)
- Checkpointing and savepoints: exactly-once semantics end-to-end
- Backpressure and flow control
- **Demo:** [Implementing windowed aggregations with watermarks in Flink](labs/3.2-flink-windows/main.typ)

**3.3 — ClickHouse: Real-Time Analytics at Scale**

- OLAP vs OLTP: why traditional databases fall short for analytics
- ClickHouse architecture: column-oriented storage, vectorized execution
- MergeTree engine family: inserts, merges, and background compaction
- Materialized views and projections for pre-aggregation
- Sharding, replication, and distributed queries
- **Demo:** [Modeling and querying a billion-row analytics dataset in ClickHouse](labs/3.4-clickhouse/main.typ)

**3.4 — Data Pipelines: Theory & Reasoning**

- Forward chaining (push/event-driven) vs backward chaining (pull/demand-driven)
- Monotonic computations and the CALM theorem — coordination-free consistency
- Lattice state machines and CRDTs: convergent distributed state
- Idempotency and determinism as pipeline design principles
- Connecting theory to practice: how Spark, Flink, ClickHouse, and Kafka map to these models
- **Demo:** [Modeling a pipeline as a lattice](labs/3.3-lattice-pipeline/main.typ)

---

## Day 4 — Advanced Techniques & Projects (4h30, 3 sessions)

**Learning outcomes:** Students can implement and reason about probabilistic data structures (HLL, Bloom filter, CMS), explain when incremental computation is correct by construction and when it requires coordination, and scope a data processing project with appropriate architectural choices.

**4.1 — Probabilistic Data Structures**

- The case for approximation: trading accuracy for space and speed
- HyperLogLog: cardinality estimation in kilobytes
- Bloom filters: membership testing with no false negatives
- Count-Min Sketch: frequency estimation in streaming contexts
- t-digest: approximate percentiles on distributed data
- Practical use in ClickHouse, Spark, and Flink
- **Demo:** [Building HLL, Bloom filters, and CMS from scratch, then comparing against ClickHouse built-ins](labs/4.1-probabilistic-structures/main.typ)

**4.2 — Differential Dataflow & Incremental Computation**

- Recomputation vs incremental maintenance
- Differential dataflow: processing only the deltas
- Partially ordered timestamps and iteration
- Applications: materialized views, incremental ETL, live dashboards
- Connection to lattices and CALM (callback to Day 3)
- **Demo:** [Building an incremental computation engine that maintains views via deltas](labs/4.2-incremental-dataflow/main.typ)

**4.3 — Project Briefing**

- Presentation of available project topics
- Scope, expectations, and deliverables
- Team formation and Q&A

---

## Assessment

**100% project presentation** (separate day, not counted in the 21h).

Students pick one of the [proposed projects](projects/) on Day 4 and present their implementation on a later date. The presentation must demonstrate:

- A working system processing the chosen dataset
- Understanding of the architectural choices and their trade-offs
- Ability to answer questions about internals (query plans, partitioning, delivery guarantees, etc.)

See [projects/](projects/) for available subjects and [DATASETS.md](DATASETS.md) for dataset details.

---

## Recommended Reading

- *Designing Data-Intensive Applications* — Martin Kleppmann
- *Streaming Systems* — Akidau, Chernyak, Lax
- *Spark: The Definitive Guide* — Chambers, Zaharia
- *The Data Engineering Cookbook* (open-source)
