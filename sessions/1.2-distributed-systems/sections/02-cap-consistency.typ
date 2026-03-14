#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= CAP & Consistency

== The scenario

#align(center,
  fletcher.diagram(
    spacing: (5cm, 2.5cm),
    node-stroke: 0.8pt,
    node((0, 0), [Node A \ `x = 42`]),
    node((1, 0), [Node B \ `x = ?`]),
    edge((0, 0), (1, 0), "<->", [replication], label-side: left),
    node((0, 1), [Client 1], stroke: (dash: "dashed")),
    node((1, 1), [Client 2], stroke: (dash: "dashed")),
    edge((0, 1), (0, 0), "->", [`write(x, 42)`], label-side: left),
    edge((1, 1), (1, 0), "->", [`read(x)`], label-side: right),
  )
)

Client 1 writes to A, Client 2 reads from B. \
What should the read return?

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

== A network partition

#{
  let r = 1.5
  let pts = range(8).map(i => {
    let a = i * 45deg
    (calc.cos(a) * r, calc.sin(a) * r)
  })
  let left = (2, 3, 4, 5)

  let draw-clique(partition: false) = cetz.canvas(length: 1cm, {
    import cetz.draw: *
    for i in range(8) {
      for j in range(i + 1, 8) {
        let cross = (i in left) != (j in left)
        if not (partition and cross) {
          line(pts.at(i), pts.at(j), stroke: 0.4pt + luma(160))
        }
      }
    }
    if partition {
      let mid-a = 67.5deg
      let d = 2.0
      line(
        (calc.cos(mid-a) * d, calc.sin(mid-a) * d),
        (-calc.cos(mid-a) * d, -calc.sin(mid-a) * d),
        stroke: (paint: red, thickness: 2pt, dash: "dashed"),
      )
    }
    for p in pts {
      circle(p, radius: 0.22, fill: rgb("#c8e6c9"), stroke: 0.8pt)
    }
  })

  align(center,
    grid(
      columns: 2,
      gutter: 2cm,
      align: center,
      draw-clique(),
      draw-clique(partition: true),
    )
  )
}

- Both sides are alive, but they *cannot talk to each other*
- Clients can still reach each node independently
- The system must now choose: consistency or availability?

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
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Leader (A)])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Follower (B)])
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
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Leader (A)])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Follower (B)])
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
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Leader (A)])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Follower (B)])
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

- Same scenario as eventual — but the system tracks the *causal dependency*
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

