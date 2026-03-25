= Interoperability & the Modern Stack

== Arrow Flight SQL

The classic query path serializes results to rows (JDBC/ODBC) and re-columnarizes them on the client. Arrow Flight SQL keeps data columnar end-to-end.

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *JDBC / ODBC (row wire)* \
      #v(0.5em)
      ClickHouse serializes columns → rows. \
      Wire: text or binary row format. \
      Client deserializes rows → columns again. \
      #v(0.4em)
      Two unnecessary transpositions. \
      CPU-bound for large result sets.
    ],
    [
      *Arrow Flight SQL (columnar wire)* \
      #v(0.5em)
      ClickHouse serializes columns → Arrow batches. \
      Wire: gRPC + Apache Arrow record batches. \
      Client reads Arrow directly — zero extra copy. \
      #v(0.4em)
      No transposition. \
      Works natively with Pandas, Polars, DuckDB, Grafana.
    ],
  )
)

#v(0.8em)

Arrow Flight SQL is a standard protocol — not ClickHouse-specific. Any tool that speaks Flight SQL can query ClickHouse without a custom driver. ClickHouse supports it alongside its native binary protocol and HTTP interface *(as of ClickHouse 22.6+)*.

== S3 & blob store tiered storage

ClickHouse supports *storage policies* that tier parts across media by age or access frequency.

```xml
<!-- config.xml: define a hot → cold tiering policy -->
<storage_configuration>
  <disks>
    <hot>  <type>local</type>  <path>/nvme/clickhouse/</path> </hot>
    <cold> <type>s3</type>     <endpoint>https://s3.amazonaws.com/my-bucket/</endpoint> </cold>
  </disks>
  <policies>
    <tiered>
      <volumes>
        <hot_vol>  <disk>hot</disk>  <max_data_part_size_bytes>10737418240</max_data_part_size_bytes> </hot_vol>
        <cold_vol> <disk>cold</disk> </cold_vol>
      </volumes>
      <move_factor>0.2</move_factor>
    </tiered>
  </policies>
</storage_configuration>
```

Parts are moved automatically when hot disk usage exceeds the threshold, or manually with `ALTER TABLE events MOVE PART '...' TO DISK 'cold'`.

== Tiered storage — trade-offs

#table(
  columns: (auto, 1fr, 1fr),
  [*Tier*], [*Latency*], [*Role*],
  [Local NVMe], [~0.1 ms], [Hot recent data — dashboards, live queries],
  [Network block store (EBS)], [~1–5 ms], [Warm data — accessed daily or weekly],
  [Object storage (S3 / GCS)], [~10–100 ms], [Cold archive — months or years, queried rarely],
)

#v(0.6em)

For analytical workloads this is acceptable: a query that scans 10 GB from S3 at 1 GB/s takes ~10 seconds — fine for a scheduled report, not for a live dashboard.

ClickHouse caches recently accessed S3 parts on local disk (`remote_filesystem_local_cache`). Repeated access to the same cold part pays S3 latency only once.

*ClickHouse Cloud* is the productization of this model: stateless compute nodes share object storage — scale compute independently of data volume, pay only for what you store.

== When to use ClickHouse — and when not to

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *Good fit* \
      #v(0.3em)
      High-cardinality GROUP BY over billions of rows \
      Time-series analytics (metrics, events, logs) \
      Pre-aggregated dashboards and materialized views \
      Append-only event streams from Kafka \
      Exploratory analytics on large datasets \
    ],
    [
      *Poor fit* \
      #v(0.3em)
      Frequent row-level `UPDATE` / `DELETE` \
      ACID transactions across multiple tables \
      Complex JOINs between large unrelated tables \
      OLTP with many small random-access reads \
      Low-volume data where Postgres is fine \
    ],
  )
)

#v(0.8em)

The pattern of failure: teams reach for ClickHouse because it is fast, then spend weeks working around the absence of transactions and the eventual consistency of `ReplacingMergeTree`. Choose the tool for the workload, not the benchmark.
