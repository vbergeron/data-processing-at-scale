#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Normalization vs Denormalization

== \

#hero[So when is normalization \ still the right call?]

== Normalization — the benefits

#align(center,
  fletcher.diagram(
    spacing: (3cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [`customers`], fill: rgb("#c8e6c9"), width: 3cm),
    node((1, 0), [`orders`], fill: rgb("#bbdefb"), width: 3cm),
    node((2, 0), [`products`], fill: rgb("#c8e6c9"), width: 3cm),
    edge((1, 0), (0, 0), "->", [FK]),
    edge((1, 0), (2, 0), "->", [FK]),
  )
)

- *No redundancy*: customer name stored once — update it in one place
- *Consistency*: no risk of "Alice" in one row and "ALICE" in another
- *Small storage*: only store each fact once
- Essential for *OLTP*: frequent writes, strong consistency requirements

== Denormalization — the benefits

#align(center,
  fletcher.diagram(
    spacing: (2cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [`orders_wide`], fill: rgb("#fff9c4"), width: 8cm),
  )
)

#v(0.5em)

- *No joins*: everything the query needs is in one table
- *Scan-friendly*: columnar storage compresses repeated values efficiently
- *Predictable performance*: no join explosion on bad key distributions
- Essential for *OLAP*: rare writes, heavy aggregation workloads

== The decision matrix

#table(
  columns: 3,
  align: (left, center, center),
  table.header([*Criterion*], [*Normalize*], [*Denormalize*]),
  [Write frequency], [High], [Low],
  [Read pattern], [Point lookups], [Full scans / aggregations],
  [Consistency needs], [Strong], [Eventual is fine],
  [Query complexity], [Simple (few joins)], [Complex (many joins)],
  [Data volume], [< 100 GB], [> 100 GB],
  [Update anomaly risk], [Must avoid], [Acceptable (batch refresh)],
)

- Most real systems have *both*: normalized OLTP source, denormalized OLAP warehouse
- The ETL/ELT pipeline bridges the two

== The ETL bridge

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [OLTP DB \ (normalized)], fill: rgb("#c8e6c9")),
    node((1, 0), [ETL \ pipeline], fill: rgb("#e3f2fd")),
    node((2, 0), [Data Warehouse \ (star schema)], fill: rgb("#fff9c4")),
    edge((0, 0), (1, 0), "->", [extract]),
    edge((1, 0), (2, 0), "->", [transform + load]),
  )
)

- *Extract*: read from the operational database
- *Transform*: join, clean, denormalize, compute surrogate keys
- *Load*: write into the star schema / wide table
- Typically runs on a schedule (hourly, daily) — not real-time

== What's wrong here?

#align(center,
  fletcher.diagram(
    spacing: (3cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Web app], stroke: (dash: "dashed")),
    node((1, 0), [Single table: \ `orders_wide` \ (10 billion rows)], fill: rgb("#ffcdd2"), width: 5cm),
    edge((0, 0), (1, 0), "->", [reads + writes]),
  )
)

- The app *writes* to a denormalized table — every customer update touches millions of rows
- The app *reads* with point lookups — denormalization gives no benefit for those
- Fix: normalized tables for the app, denormalized views for analytics

== Slowly changing dimensions

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Type*], [*Strategy*], [*Example*]),
  [Type 1], [Overwrite the old value], [Fix a typo in a product name],
  [Type 2], [Add a new row with a version], [Customer changes city — keep history],
  [Type 3], [Add a column for the old value], [Store `current_city` and `previous_city`],
)

- *Type 2* is the most common in data warehouses — enables historical analysis
- "What was the customer's segment when they placed this order?"
- Surrogate keys make this work: the same customer has multiple keys over time

== \

#hero[Normalize for writes. \ Denormalize for reads. \ The pipeline connects them.]
