#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= CAP & Consistency

== Three properties

#table(
  columns: 2,
  align: (left, left),
  [`C` - *Consistency*], [Every read returns either most recent write or an error],
  [`A` - *Availability*], [Every request to a non-crashed node gets a response],
  [`P` - *Partition tolerance*], [The system keeps working despite network splits],
)

#v(0.5em)
#text(size: 16pt, fill: luma(100))[⚠ "Consistency" here is *not* the C in ACID — different concept, same word.]


== The CAP theorem

#align(center)[
  #fletcher.diagram(
    spacing: 2cm,
    node-stroke: 0.8pt,
    node((1, 0), text(size: 32pt, weight: "bold")[P], fill: rgb("#bbdefb"), shape: fletcher.shapes.diamond),
    node((0, 1), text(size: 32pt, weight: "bold")[C], fill: rgb("#c8e6c9"), shape: fletcher.shapes.diamond),
    node((2, 1), text(size: 32pt, weight: "bold")[A], fill: rgb("#fff9c4"), shape: fletcher.shapes.diamond),
    edge((1, 0), (0, 1), "-"),
    edge((1, 0), (2, 1), "-"),
    edge((0, 1), (2, 1), "-"),
  )
]

#align(center)[
  If a system is *Partition Tolerant*, \
  A system _must_ choose *Consistency* or *Availability*.
]

== CA systems

#align(center)[
  #fletcher.diagram(
    spacing: 2cm,
    node-stroke: 0.8pt,
    node((0, 1), text(size: 32pt, weight: "bold")[C], fill: rgb("#c8e6c9"), shape: fletcher.shapes.diamond),
    node((2, 1), text(size: 32pt, weight: "bold")[A], fill: rgb("#fff9c4"), shape: fletcher.shapes.diamond),
    edge((0, 1), (2, 1), "-"),
  )
]

#align(center)[
  Single node systems: PostgreSQl, Redis (single node), DuckDB
]

== AP systems

#align(center)[
  #fletcher.diagram(
    spacing: 2cm,
    node-stroke: 0.8pt,
    node((1, 0), text(size: 32pt, weight: "bold")[P], fill: rgb("#bbdefb"), shape: fletcher.shapes.diamond),
    node((2, 1), text(size: 32pt, weight: "bold")[A], fill: rgb("#fff9c4"), shape: fletcher.shapes.diamond),
    edge((1, 0), (2, 1), "-"),
  )
]

#align(center)[
  Cassandra, DynamoDB, CouchDB, ElasticSearch
]

== CP Systems

#align(center)[
  #fletcher.diagram(
    spacing: 2cm,
    node-stroke: 0.8pt,
    node((1, 0), text(size: 32pt, weight: "bold")[P], fill: rgb("#bbdefb"), shape: fletcher.shapes.diamond),
    node((0, 1), text(size: 32pt, weight: "bold")[C], fill: rgb("#c8e6c9"), shape: fletcher.shapes.diamond),
    edge((1, 0), (0, 1), "-"),
  )
]

#align(center)[
  ZooKeeper, etcd, HBase, FoundationDB
]

== Consistency models — what can a reader see?

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let c1x = 0; let ax = 4; let bx = 8; let c2x = 12

    line((c1x, 0), (c1x, -8), stroke: 1.2pt)
    line((ax, 0), (ax, -8), stroke: 1.2pt)
    line((bx, 0), (bx, -8), stroke: 1.2pt)
    line((c2x, 0), (c2x, -8), stroke: 1.2pt)

    content((c1x, 0.6), text(size: 11pt, weight: "bold")[Client 1])
    content((ax, 0.6), text(size: 11pt, weight: "bold")[Node A])
    content((bx, 0.6), text(size: 11pt, weight: "bold")[Node B])
    content((c2x, 0.6), text(size: 11pt, weight: "bold")[Client 2])

    line((c1x + 0.2, -1), (ax - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((ax - 0.2, -2), (c1x + 0.2, -2.5), stroke: 1pt, mark: (end: ">"))
    content((2, -2.7), text(size: 14pt, weight: "bold")[?])

    content((6, -3.75), text(size: 32pt, weight: "bold")[?])

    line((c2x - 0.2, -5.5), (bx + 0.2, -6), stroke: 1pt, mark: (end: ">"))
    content((10, -5.2), text(size: 10pt)[`read(x)`])

    line((bx + 0.2, -6.5), (c2x - 0.2, -7), stroke: 1pt, mark: (end: ">"))
    content((10, -7.2), text(size: 14pt, weight: "bold")[?])

    content((6, -8.3), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

When does A respond? What do A and B exchange? What does B return?

== Strong consistency — linearizability

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let c1x = 0; let lx = 4; let fx = 8; let c2x = 12

    line((c1x, 0), (c1x, -9), stroke: 1.2pt)
    line((lx, 0), (lx, -9), stroke: 1.2pt)
    line((fx, 0), (fx, -9), stroke: 1.2pt)
    line((c2x, 0), (c2x, -9), stroke: 1.2pt)

    content((c1x, 0.6), text(size: 11pt, weight: "bold")[Client 1])
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Node A])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Node B])
    content((c2x, 0.6), text(size: 11pt, weight: "bold")[Client 2])

    line((c1x + 0.2, -1), (lx - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((lx + 0.2, -2), (fx - 0.2, -2.5), stroke: (paint: rgb("#1565c0"), thickness: 1pt), mark: (end: ">"))
    content((6, -1.7), text(size: 10pt, fill: rgb("#1565c0"))[replicate])

    line((fx - 0.2, -3), (lx + 0.2, -3.5), stroke: (paint: rgb("#1565c0"), thickness: 1pt), mark: (end: ">"))
    content((6, -3.7), text(size: 10pt, fill: rgb("#1565c0"))[ack])

    line((lx - 0.2, -4), (c1x + 0.2, -4.5), stroke: 1pt, mark: (end: ">"))
    content((2, -4.7), text(size: 10pt)[ok ✓])

    line((c1x - 0.5, -1), (c1x - 0.5, -4.5), stroke: (paint: red, thickness: 2.5pt))
    content((c1x - 1.8, -2.75), text(size: 9pt, fill: red)[blocked])

    line((c2x - 0.2, -5.5), (fx + 0.2, -6), stroke: 1pt, mark: (end: ">"))
    content((10, -5.2), text(size: 10pt)[`read(x)`])

    line((fx + 0.2, -6.5), (c2x - 0.2, -7), stroke: (paint: rgb("#2e7d32"), thickness: 1pt), mark: (end: ">"))
    content((10.5, -7.2), text(size: 10pt, fill: rgb("#2e7d32"))[x = 42 ✓])

    content((6, -9.3), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

- *Linearizability*: behaves as if there is a single copy of the data
- The leader waits for replication acknowledgment before responding
- Cost: every write pays a round-trip latency penalty

== Eventual consistency

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let c1x = 0; let lx = 4; let fx = 8; let c2x = 12

    line((c1x, 0), (c1x, -7.5), stroke: 1.2pt)
    line((lx, 0), (lx, -7.5), stroke: 1.2pt)
    line((fx, 0), (fx, -7.5), stroke: 1.2pt)
    line((c2x, 0), (c2x, -7.5), stroke: 1.2pt)

    content((c1x, 0.6), text(size: 11pt, weight: "bold")[Client 1])
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Node A])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Node B])
    content((c2x, 0.6), text(size: 11pt, weight: "bold")[Client 2])

    line((c1x + 0.2, -1), (lx - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((lx - 0.2, -1.8), (c1x + 0.2, -2.3), stroke: 1pt, mark: (end: ">"))
    content((2, -2.5), text(size: 10pt)[ok ✓])

    line(
      (lx + 0.2, -2), (fx - 0.2, -6),
      stroke: (paint: luma(120), thickness: 1pt, dash: "dashed"),
      mark: (end: ">"),
    )
    content((5.5, -3.5), text(size: 9pt, fill: luma(120))[async \ replication])

    line((c2x - 0.2, -3), (fx + 0.2, -3.5), stroke: 1pt, mark: (end: ">"))
    content((10, -2.7), text(size: 10pt)[`read(x)`])

    line((fx + 0.2, -4), (c2x - 0.2, -4.5), stroke: (paint: red, thickness: 1pt), mark: (end: ">"))
    content((10.5, -4.7), text(size: 10pt, fill: red)[stale!])

    content((6, -7.8), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

- If no new writes arrive, all replicas *eventually converge*
- No bound on when — could be milliseconds, could be minutes
- Cheap and fast, but dangerous when you need read-your-writes

== Causal consistency

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let c1x = 0; let lx = 4; let fx = 8; let c2x = 12

    line((c1x, 0), (c1x, -9.5), stroke: 1.2pt)
    line((lx, 0), (lx, -9.5), stroke: 1.2pt)
    line((fx, 0), (fx, -9.5), stroke: 1.2pt)
    line((c2x, 0), (c2x, -9.5), stroke: 1.2pt)

    content((c1x, 0.6), text(size: 11pt, weight: "bold")[Client 1])
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Node A])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Node B])
    content((c2x, 0.6), text(size: 11pt, weight: "bold")[Client 2])

    line((c1x + 0.2, -1), (lx - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((lx - 0.2, -1.8), (c1x + 0.2, -2.3), stroke: 1pt, mark: (end: ">"))
    content((2, -2.5), text(size: 10pt)[ok ✓])

    line(
      (lx + 0.2, -2), (fx - 0.2, -7),
      stroke: (paint: luma(120), thickness: 1pt, dash: "dashed"),
      mark: (end: ">"),
    )
    content((5.5, -5), text(size: 9pt, fill: luma(120))[async \ replication])

    line(
      (c1x + 0.2, -3.5), (c2x - 0.2, -4),
      stroke: (paint: rgb("#7b1fa2"), thickness: 1pt, dash: "dotted"),
      mark: (end: ">"),
    )
    content((6, -3.2), text(size: 9pt, fill: rgb("#7b1fa2"))[app message (causal link)])

    line((c2x - 0.2, -5), (fx + 0.2, -5.5), stroke: 1pt, mark: (end: ">"))
    content((10, -4.7), text(size: 10pt)[`read(x)`])

    line((fx - 0.5, -5.5), (fx - 0.5, -7), stroke: (paint: rgb("#e65100"), thickness: 2.5pt))
    content((fx - 1.5, -6.25), text(size: 9pt, fill: rgb("#e65100"))[wait])

    line((fx + 0.2, -7.3), (c2x - 0.2, -7.8), stroke: (paint: rgb("#2e7d32"), thickness: 1pt), mark: (end: ">"))
    content((10.5, -8), text(size: 10pt, fill: rgb("#2e7d32"))[x = 42 ✓])

    content((6, -9.8), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

- The follower delays its response until replication catches up
- Writes are fast (like eventual), reads are causally correct (like strong)

== Choosing a consistency model

#table(
  columns: 4,
  align: (left, center, center, left),
  table.header([*Model*], [*Latency*], [*Safety*], [*Good for*]),
  [Strong (linearizable)], [High], [Highest], [Bank transfers, distributed locks],
  [Causal], [Medium], [Medium], [Collaborative editing, social feeds],
  [Eventual], [Low], [Lowest], [Caches, analytics counters, DNS],
)

- Ask: "What happens if a reader sees a stale value?"
- If the answer is "nothing bad" → eventual is fine
- If the answer is "we lose money" → you need strong

