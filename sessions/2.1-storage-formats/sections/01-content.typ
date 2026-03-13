== Distributed File Systems

- HDFS: architecture, block replication, NameNode/DataNode
- Object storage: S3, GCS — immutable blobs, eventual consistency

== NoSQL Databases

- Key-value, document, wide-column stores
- Trade-offs vs relational systems

== File Formats

- Parquet: columnar, predicate pushdown, row groups
- ORC: columnar with built-in indexes
- Avro: row-oriented, schema evolution
- Trade-offs and internals

== Schema Evolution & Serialization

- Forward and backward compatibility
- How Avro, Parquet, and Protobuf handle evolution differently

== Lakehouse Table Formats

- Delta Lake, Iceberg, Hudi
- Metadata, time travel, partition pruning
- ACID on object storage

== Demo

*Comparing query performance across file formats and partitioning schemes*
