#import "../../style.typ": hero, pause

= Lakehouse Table Formats

== The problem Parquet doesn't solve

You have a data lake: thousands of Parquet files in S3.


- How do you know which files belong to the `transactions` table?
- You add a column — how do old files get read with the new schema?
- A write fails halfway — some files are written, some aren't. Is the table consistent?
- You need to delete GDPR-regulated rows. Parquet files are immutable.


Parquet is a *file* format. You need a *table* format.

== What a table format does

A metadata layer on top of immutable Parquet (or ORC) files:


- *Catalog*: which files constitute the current table
- *Schema evolution*: add, rename, reorder columns across file versions
- *ACID transactions*: atomic writes — readers never see partial results
- *Time travel*: query the table as it was at any point in the past
- *Partition evolution*: change partitioning without rewriting data

== Apache Iceberg

Created by Netflix (2017), now the most widely adopted table format.


- *Snapshot isolation*: readers see a consistent snapshot; writers commit atomically
- *Hidden partitioning*: partition strategy is metadata, not directory structure — `WHERE date = '2024-03-15'` works without knowing the partition scheme
- *Schema evolution*: add, drop, rename, reorder columns — all via metadata updates
- *Time travel*: `SELECT * FROM t AS OF '2024-01-01'`


Adopted by: Spark, Flink, Trino, Snowflake, BigQuery, Dremio, AWS Athena.

== Delta Lake

Created by Databricks (2019). Built on a *transaction log* (`_delta_log/`):


- JSON log files record every change: add file, remove file, schema change
- *Optimistic concurrency*: writers commit by appending to the log
- *MERGE / UPDATE / DELETE*: SQL DML on immutable Parquet files
- *Z-ordering*: sort data across multiple columns for better predicate pushdown


Tightly integrated with Spark and the Databricks platform. \
Open-sourced, but the ecosystem is narrower than Iceberg's.

== Table format comparison

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Feature*], [*Iceberg*], [*Delta Lake*]),
  [ACID transactions], [Yes], [Yes],
  [Time travel], [Yes], [Yes],
  [Schema evolution], [Full], [Full],
  [Hidden partitioning], [Yes], [No],
  [Partition evolution], [Yes], [No],
  [Upsert optimization], [Merge-on-read (v2)], [Via MERGE],
)


The industry is converging toward *Iceberg* as the default.
