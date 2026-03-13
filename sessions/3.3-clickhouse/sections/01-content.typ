== OLAP vs OLTP

- Why traditional databases fall short for analytics
- Read-optimized vs write-optimized architectures

== ClickHouse Architecture

- Column-oriented storage
- Vectorized execution engine
- Compression and encoding per column

== The MergeTree Engine Family

- Inserts, parts, and background merges
- ORDER BY as the primary index
- Why ORDER BY is the most important schema decision

== Materialized Views & Projections

- Incremental pre-aggregation on insert
- Projections: multiple sort orders, one table
- Automatic query routing

== Distributed ClickHouse

- Sharding and replication
- Distributed queries
- ReplicatedMergeTree and ZooKeeper/Keeper

== Demo

*Modeling and querying a billion-row analytics dataset in ClickHouse*
