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

#let ch(pos) = node(pos, text(size: 8pt)[CH], fill: white, stroke: 0.6pt, width: 0.9cm, inset: 5pt, corner-radius: 3pt)
#let keeper(pos) = node(pos, text(size: 7pt)[Keeper], fill: luma(235), stroke: 0.5pt + luma(160), width: 1.1cm, inset: 4pt, corner-radius: 3pt)

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 1cm,
  align: top,

  rect(fill: rgb("#e8f5e9"), inset: 10pt, radius: 4pt, width: 100%)[
    #text(weight: "bold")[Standalone]
    #v(0.6em)
    #align(center, block(height: 2.8cm,
      align(center + horizon,
        fletcher.diagram(
          node-stroke: 0.6pt,
          node-corner-radius: 3pt,
          node((0,0), text(size: 9pt)[CH], fill: white, width: 1.6cm, inset: 10pt),
        )
      )
    ))
  ],

  rect(fill: rgb("#fff3e0"), inset: 10pt, radius: 4pt, width: 100%)[
    #text(weight: "bold")[Replicated]
    #v(0.6em)
    #align(center, block(height: 2.8cm,
      align(center + horizon,
        fletcher.diagram(
          spacing: (1.4cm, 0.9cm),
          node-stroke: 0.6pt,
          node-corner-radius: 3pt,
          ch((0,0)), ch((2,0)), keeper((1,1)),
          edge((0,0),(2,0), "<->"),
          edge((0,0),(1,1), "->"),
          edge((2,0),(1,1), "->"),
        )
      )
    ))
  ],

  rect(fill: rgb("#fce4ec"), inset: 10pt, radius: 4pt, width: 100%)[
    #text(weight: "bold")[Sharded cluster]
    #v(0.6em)
    #align(center, block(height: 2.8cm,
      align(center + horizon,
        fletcher.diagram(
          spacing: (1.1cm, 0.9cm),
          node-stroke: 0.6pt,
          node-corner-radius: 3pt,
          keeper((1.5, 0)),
          ch((0,1)), ch((1,1)), ch((2,1)), ch((3,1)),
          edge((1.5,0),(0,1), "->"),
          edge((1.5,0),(1,1), "->"),
          edge((1.5,0),(2,1), "->"),
          edge((1.5,0),(3,1), "->"),
          edge((0,1),(1,1), "<->"),
          edge((2,1),(3,1), "<->"),
        )
      )
    ))
  ],
)

#v(0.8em)

A single ClickHouse node scales to tens of terabytes and is the right starting point for most teams. Replication adds fault-tolerance; sharding adds horizontal scale — both require CH Keeper for coordination.
