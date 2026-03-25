#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Introduction

== ClickHouse

#align(center + horizon, image("../assets/clickhouse-logo.svg", width: 30%))

== A brief history

#table(
  columns: (auto, 1fr),
  [*Year*], [*Event*],
  [2009], [Started at Yandex by Alexey Milovidov to power Yandex.Metrica — the web analytics platform processing hundreds of billions of events per day],
  [2016], [Open-sourced under the Apache License 2.0; immediately adopted by teams outside Yandex needing sub-second OLAP at scale],
  [2021], [ClickHouse Inc. founded; Series A & B funding; cloud-managed service launched],
  [2022–], [Adopted at Cloudflare (DNS query logs, 13M+ events/s), Uber, Discord, ByteDance, Bloomberg, Stripe, and many others],
)

#v(0.6em)

ClickHouse started as an internal tool for one specific problem — aggregating clickstream data fast enough to power real-time dashboards — and its design has never deviated from that goal. Every architectural decision traces back to *making analytical queries faster*.

== The OLTP–OLAP continuum

#align(center,
  fletcher.diagram(
    spacing: (0pt, 1.4cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), width: 14cm, inset: 0pt, stroke: none,
      align(center,
        grid(
          columns: (1fr, 1fr, 1fr, 1fr, 1fr),
          column-gutter: 0.3cm,
          rect(fill: rgb("#e3f2fd"), inset: 8pt, radius: 4pt, width: 100%)[
            #text(weight: "bold", size: 10pt)[OLTP] \
            #text(size: 9pt, fill: luma(100))[PostgreSQL \ MySQL]
          ],
          rect(fill: rgb("#e8eaf6"), inset: 8pt, radius: 4pt, width: 100%)[
            #text(weight: "bold", size: 10pt)[Document] \
            #text(size: 9pt, fill: luma(100))[MongoDB \ Elasticsearch]
          ],
          rect(fill: rgb("#f3e5f5"), inset: 8pt, radius: 4pt, width: 100%)[
            #text(weight: "bold", size: 10pt)[HTAP] \
            #text(size: 9pt, fill: luma(100))[SingleStore \ TiDB]
          ],
          rect(fill: rgb("#fce4ec"), inset: 8pt, radius: 4pt, width: 100%)[
            #text(weight: "bold", size: 10pt)[Batch OLAP] \
            #text(size: 9pt, fill: luma(100))[Spark \ BigQuery]
          ],
          rect(fill: rgb("#B5303B"), inset: 8pt, radius: 4pt, width: 100%)[
            #text(weight: "bold", size: 10pt, fill: white)[Real-time OLAP] \
            #text(size: 9pt, fill: rgb("#fce4ec"))[*ClickHouse* \ Druid]
          ],
        )
      )
    ),
    node((0, 1), width: 14cm, inset: 0pt, stroke: none,
      align(center,
        grid(
          columns: (1fr, 1fr, 1fr, 1fr, 1fr),
          column-gutter: 0.3cm,
          align: top + center,
          text(size: 9pt)[Row store \ Point reads \ High write rate \ Small data],
          text(size: 9pt)[Flexible schema \ Full-text search \ Semi-structured],
          text(size: 9pt)[Both workloads \ Hybrid storage \ Higher latency],
          text(size: 9pt)[Columnar \ Shuffle-based \ Minutes latency \ Huge scale],
          text(size: 9pt)[Columnar \ Append-only \ Milliseconds \ Sub-petabyte],
        )
      )
    ),
  )
)

== Where ClickHouse fits

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
