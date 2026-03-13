== The Memory & Storage Hierarchy

- L1/L2/L3 cache, RAM, SSD, network, object storage
- Bandwidth and latency at each level
- Orders-of-magnitude differences

== Access Patterns Matter

- Sequential vs random access
- Why the access pattern matters more than the medium
- Columnar vs row-oriented: a cache-efficiency argument

== The Cost Anatomy of a Shuffle

- Serialization
- Network transfer
- Disk spill
- Deserialization

== Amdahl's Law & Data Parallelism

- What serializes and what doesn't
- Strong vs weak scaling
- Why "just add more nodes" has diminishing returns

== Back-of-the-Envelope Estimation

- How long should this query take?
- Sanity-checking before running
- Coordination overhead and straggler effects
