#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

== \

#hero[Why can't you just normalize everything?]

== Two worlds of data

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*OLTP*], [*OLAP*]),
  [Purpose], [Run the business], [Analyze the business],
  [Queries], [Point lookups, small writes], [Full scans, aggregations],
  [Users], [Application code], [Analysts, dashboards],
  [Rows touched], [1–100], [Millions–billions],
  [Latency goal], [< 10 ms], [Seconds to minutes],
  [Schema style], [Normalized (3NF)], [Denormalized (star/wide)],
)

- The same data, modeled *differently* for different access patterns
- A schema optimized for OLTP is often *terrible* for OLAP — and vice versa

== The cost of joins at scale

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(y, width, label, time, color) = {
      rect((0, y), (width, y + 0.7), fill: color, stroke: 0.5pt)
      content((-0.3, y + 0.35), anchor: "east", text(size: 10pt)[#label])
      content((width + 0.3, y + 0.35), anchor: "west", text(size: 10pt)[#time])
    }

    bar(3, 0.5, [1 GB join], [0.2 s], rgb("#c8e6c9"))
    bar(2, 2.5, [10 GB join], [5 s], rgb("#a5d6a7"))
    bar(1, 6, [100 GB join], [3 min], rgb("#fff9c4"))
    bar(0, 14, [1 TB join], [45 min], rgb("#ffcdd2"))

    content((7, -0.8), text(size: 9pt, fill: luma(120))[hash join, single node, 1 GB/s read throughput])
  })
)

- Joins require shuffling *both* tables by the join key
- At 1 TB, a join can shuffle *2 TB* across the network
- Denormalization trades storage for avoiding that shuffle

== Join strategies — a preview

#table(
  columns: 3,
  align: (left, center, center),
  table.header([*Strategy*], [*When to use*], [*Cost*]),
  [Broadcast join], [One side < ~100 MB], [Low — no shuffle],
  [Hash join], [Both sides fit in memory], [Medium — one shuffle],
  [Sort-merge join], [Both sides too large for RAM], [High — two shuffles + sort],
  [Pre-joined / denormalized], [Analytical queries], [Zero runtime — paid at write time],
)

- The optimizer picks the strategy — but the *schema* determines which strategies are possible
- A pre-joined table needs *no runtime join at all*

== Write amplification — the other side

#align(center,
  fletcher.diagram(
    spacing: (3cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Customer \ update], stroke: (dash: "dashed")),
    node((1, 0), [`customers`], fill: rgb("#c8e6c9")),
    node((2, 0), [`orders` \ (denormalized)], fill: rgb("#ffcdd2")),
    edge((0, 0), (1, 0), "->", [1 row]),
    edge((1, 0), (2, 0), "->", [100K rows], stroke: red),
  )
)

- Denormalized: a customer name change must update *every order row*
- *Write amplification*: one logical write → many physical writes
- Acceptable for analytics (infrequent updates) — deadly for OLTP (frequent updates)

== The modeling question

#hero[
  How will the data be *read*? \
  That determines how it should be *stored*.
]

== What changes at scale

- Below 10 GB: model however you want — joins are fast
- 10 GB – 1 TB: join strategy matters, index design matters
- Above 1 TB: the schema *is* the optimization — wrong model = hours instead of seconds

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  At scale, data modeling is not a design exercise. It's a performance decision.
]

== \

#hero[If reads dominate, \ design the schema for the reader.]
