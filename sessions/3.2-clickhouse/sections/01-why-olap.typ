= Why Analytical Databases Exist

== The analytics tax on row storage

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *OLTP — transactional access* \
      #v(0.5em)
      Read one row at a time. \
      All columns of a small set of rows. \
      High write throughput, random point access. \
      #v(0.5em)
      _"Fetch the order with id = 12345"_
    ],
    [
      *OLAP — analytical access* \
      #v(0.5em)
      Scan billions of rows at a time. \
      Two or three columns, aggregated. \
      Mostly reads, append-only inserts. \
      #v(0.5em)
      _"Revenue by day, this quarter"_
    ],
  )
)

#v(0.8em)

Row storage is optimal for OLTP: one page holds many complete rows — ideal for point lookups. For analytics, it forces reading every column of every row just to aggregate one. On a 20-column, 1B-row table: 200 GB of I/O for a result computable from 8 GB.

== Where ClickHouse sits

#table(
  columns: (auto, 1fr, 1fr),
  [*System*], [*Model*], [*Designed for*],
  [PostgreSQL], [Row store, MVCC], [Transactional workloads, row-level ops],
  [DuckDB], [Columnar, in-process], [Local analytics on files, embedded BI],
  [Apache Spark], [Columnar DAG execution], [Large-scale ETL, shuffle-heavy batch],
  [Apache Flink], [Row streaming], [Stateful event processing, low latency],
  [*ClickHouse*], [*Columnar server, distributed*], [*High-throughput OLAP, sub-second queries*],
)

#v(0.6em)

ClickHouse does not compete with Postgres for transactions or Flink for streaming. It is purpose-built for one workload: *read a few columns from billions of rows, aggregate them, return in milliseconds*.
