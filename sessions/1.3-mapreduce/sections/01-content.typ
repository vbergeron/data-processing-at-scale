== The MapReduce Programming Model

- Map: transform each record independently
- Reduce: aggregate by key
- The shuffle in between

== Shuffle, Sort & Combiners

- Why the shuffle is the expensive part
- Sort-based aggregation
- Combiners: local pre-aggregation before the shuffle

== Limitations of MapReduce

- Multi-stage pipelines require chaining jobs
- Iterative workloads (graph algorithms, ML) are painful
- No in-memory caching between stages

== From Hadoop to Modern Engines

- Hadoop MapReduce → Spark, Flink, Dataflow
- What changed: DAGs, in-memory processing, lazy evaluation

== Data Locality & Fault Tolerance

- Move computation to data, not data to computation
- Lineage-based recovery vs checkpoint-based recovery

== Demo

*Implementing word-count and join in a MapReduce-style framework*
