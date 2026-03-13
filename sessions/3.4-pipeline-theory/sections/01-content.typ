== Push vs Pull

- Forward chaining: event-driven / push-based
- Backward chaining: demand-driven / pull-based
- When to use which

== Monotonic Computations & the CALM Theorem

- What makes a computation monotonic
- CALM: coordination-free consistency for monotonic programs
- Non-monotonic operations require coordination

== Lattice State Machines & CRDTs

- Lattices: a partial order with a join (merge) operation
- Convergent replicated data types
- GCounter, GSet, 2P-Set, OR-Set

== Design Principles

- Idempotency: safe to retry
- Determinism: same input → same output
- Why these matter for fault tolerance

== Connecting Theory to Practice

- Kafka offsets: a monotonically advancing high-water mark
- Spark accumulators: associative, commutative merge
- ClickHouse ReplacingMergeTree: last-write-wins as a lattice
- Flink checkpoints: consistent cuts across event time

== Demo

*Modeling a pipeline as a lattice*
