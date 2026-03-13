== Lazy Evaluation & DAG Execution

- Transformations vs actions
- DAG-based execution plans
- Stage boundaries at shuffles

== Query Execution Models

- Volcano: tuple-at-a-time (pull-based)
- Vectorized: batch-at-a-time
- Compiled / JIT: whole-stage code generation
- Push vs pull pipelines

== The Catalyst Optimizer

- Logical plan → optimized logical plan → physical plan
- Cost-based optimization
- Predicate pushdown, projection pruning, join reordering

== Tungsten

- Whole-stage code generation
- Off-heap memory management
- Why it matters for performance

== Partitioning, Shuffles & Tuning

- Shuffle = the dominant cost
- Partition skew and how to fix it
- When to cache, when not to

== Demo

*Reading and optimizing Spark query plans on a multi-GB dataset*
