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
)

#v(0.6em)

*Today*, ClickHouse is adopted at Cloudflare (DNS query logs, 13M+ events/s), Uber, Discord, ByteDance, Bloomberg, Stripe, and many others.

== In the beginning

ClickHouse started as an internal tool for one specific problem — aggregating clickstream data fast enough to power real-time dashboards — and its design has never deviated from that goal. Every architectural decision traces back to *making analytical queries faster*.

== The OLTP – OLAP continuum

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
            #text(size: 9pt, fill: rgb("#fce4ec"))[ClickHouse \ Druid]
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

== Topology & deployment

#align(center,
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1.2cm,
    align: top + center,
    [
      #rect(fill: rgb("#e8f5e9"), inset: 12pt, radius: 4pt, width: 100%)[
        #text(weight: "bold")[Single node] \
        #v(0.4em)
        #text(size: 9pt, fill: luma(80))[
          One process. \
          No coordination overhead. \
          Scales to *tens of TB* on a single machine. \
          `clickhouse local` or `clickhouse server`.
        ]
      ]
      #v(0.5em)
      #text(size: 9pt)[
        *The right choice for most teams.* \
        A single ClickHouse node saturates a 100 Gbps NIC before running out of CPU.
      ]
    ],
    [
      #rect(fill: rgb("#fff3e0"), inset: 12pt, radius: 4pt, width: 100%)[
        #text(weight: "bold")[Replicated] \
        #v(0.4em)
        #text(size: 9pt, fill: luma(80))[
          2–3 nodes + ClickHouse Keeper. \
          `ReplicatedMergeTree` — parts sync at the part level. \
          High availability, no data loss on one failure.
        ]
      ]
      #v(0.5em)
      #text(size: 9pt)[Suitable when uptime matters more than raw throughput.]
    ],
    [
      #rect(fill: rgb("#fce4ec"), inset: 12pt, radius: 4pt, width: 100%)[
        #text(weight: "bold")[Sharded cluster] \
        #v(0.4em)
        #text(size: 9pt, fill: luma(80))[
          N shards × M replicas. \
          `Distributed` table fans out reads and writes. \
          Scales to petabytes and millions of events/s.
        ]
      ]
      #v(0.5em)
      #text(size: 9pt)[Cloudflare, ByteDance, Yandex scale — not day-one architecture.]
    ],
  )
)

#v(0.6em)

The single-node topology is not a compromise — it is the recommended starting point. ClickHouse is designed so that one well-specced machine outperforms a Spark cluster for OLAP workloads. Add sharding only when a single machine's disk or I/O is genuinely the bottleneck.
