#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

== \

#hero[Your data doesn't fit on one machine.]

= Partitioning

== Why partition?

- One node can't hold all the data, or can't serve all the traffic
- *Partition* (aka *shard*): split data so each node owns a subset
- Goal: distribute load *evenly* — avoid hot spots
- Often make sense economically.

== Hash partitioning

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [`"alice"`], stroke: (dash: "dashed")),
    node((1, 0), [`"bob"`], stroke: (dash: "dashed")),
    node((2, 0), [`"carol"`], stroke: (dash: "dashed")),
    node((3, 0), [`"dave"`], stroke: (dash: "dashed")),
    node((1.5, 1), [`hash(key) % 3`], fill: rgb("#e3f2fd"), width: 6cm),
    edge((0, 0), (1.5, 1), "->"),
    edge((1, 0), (1.5, 1), "->"),
    edge((2, 0), (1.5, 1), "->"),
    edge((3, 0), (1.5, 1), "->"),
    node((0, 2), [Node 0], fill: rgb("#c8e6c9")),
    node((1.5, 2), [Node 1], fill: rgb("#c8e6c9")),
    node((3, 2), [Node 2], fill: rgb("#c8e6c9")),
    edge((1.5, 1), (0, 2), "->"),
    edge((1.5, 1), (1.5, 2), "->"),
    edge((1.5, 1), (3, 2), "->"),
  )
)

- Uniform distribution — good for point lookups
- `hash("alice-order-1")` and `hash("alice-order-2")` land on different nodes
- Simple to implement, hard to rebalance

== The rebalancing problem

- Adding a node means movings most of the keys
- `P(X moves) = N / (N + 1)`
- With 100 TB across 10 nodes, adding node 11 reshuffles ~90 TB

== Consistent hashing

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let r = 3.5
    let cx = 0
    let cy = 0

    // ring
    circle((cx, cy), radius: r, stroke: 1.2pt, fill: none)

    // nodes on the ring (at specific angles)
    let nodes = (
      (angle: 30deg, label: "A", color: rgb("#1565c0")),
      (angle: 150deg, label: "B", color: rgb("#2e7d32")),
      (angle: 270deg, label: "C", color: rgb("#e65100")),
    )

    for n in nodes {
      let x = cx + r * calc.cos(n.angle)
      let y = cy + r * calc.sin(n.angle)
      circle((x, y), radius: 0.3, fill: n.color, stroke: none)
      let lx = cx + (r + 0.8) * calc.cos(n.angle)
      let ly = cy + (r + 0.8) * calc.sin(n.angle)
      content((lx, ly), text(size: 11pt, weight: "bold", fill: n.color)[#n.label])
    }

    // keys on the ring
    let keys = (
      (angle: 60deg, label: "k1", owner: rgb("#2e7d32")),
      (angle: 100deg, label: "k2", owner: rgb("#2e7d32")),
      (angle: 200deg, label: "k3", owner: rgb("#e65100")),
      (angle: 330deg, label: "k4", owner: rgb("#1565c0")),
    )

    for k in keys {
      let x = cx + r * calc.cos(k.angle)
      let y = cy + r * calc.sin(k.angle)
      circle((x, y), radius: 0.15, fill: k.owner)
      let lx = cx + (r - 0.8) * calc.cos(k.angle)
      let ly = cy + (r - 0.8) * calc.sin(k.angle)
      content((lx, ly), text(size: 9pt, fill: k.owner)[#k.label])
    }

    // clockwise arrow hint
    content((cx, cy), text(size: 10pt, fill: luma(120))[clockwise \ to owner])
  })
)

- Each key walks clockwise to the next node — that node owns it
- Adding a node moves only the keys in its arc (~1/N of total)
- *Virtual nodes*: each physical node gets multiple positions on the ring

== Range partitioning

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let w = 15
    let h = 1.2

    // range bar segments
    rect((0, 0), (5, h), fill: rgb("#bbdefb"), stroke: 0.8pt)
    content((2.5, h/2), text(size: 12pt)[A – F])

    rect((5, 0), (10, h), fill: rgb("#c8e6c9"), stroke: 0.8pt)
    content((7.5, h/2), text(size: 12pt)[G – M])

    rect((10, 0), (w, h), fill: rgb("#fff9c4"), stroke: 0.8pt)
    content((12.5, h/2), text(size: 12pt)[N – Z])

    // nodes below
    content((2.5, -1), text(size: 11pt)[Node 1])
    content((7.5, -1), text(size: 11pt)[Node 2])
    content((12.5, -1), text(size: 11pt)[Node 3])

    line((2.5, -0.2), (2.5, -0.6), stroke: 0.8pt, mark: (end: ">"))
    line((7.5, -0.2), (7.5, -0.6), stroke: 0.8pt, mark: (end: ">"))
    line((12.5, -0.2), (12.5, -0.6), stroke: 0.8pt, mark: (end: ">"))
  })
)

- Keys are sorted; each node owns a contiguous range
- Enables efficient *range queries* — scan within one partition
- Risk: ranges can be uneven (time-series keys cluster on "today")

== Hot spots — the recurring nightmare

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let w = 15
    let h = 1.2

    rect((0, 0), (2, h), fill: rgb("#bbdefb"), stroke: 0.8pt)
    content((1, h/2), text(size: 10pt)[A – F])

    rect((2, 0), (4, h), fill: rgb("#c8e6c9"), stroke: 0.8pt)
    content((3, h/2), text(size: 10pt)[G – M])

    rect((4, 0), (w, h), fill: rgb("#ffcdd2"), stroke: 0.8pt)
    content((9.5, h/2), text(size: 12pt, weight: "bold")[N – Z   🔥])

    content((1, -1), text(size: 10pt)[Node 1 \ idle])
    content((3, -1), text(size: 10pt)[Node 2 \ idle])
    content((9.5, -1), text(size: 10pt, fill: red, weight: "bold")[Node 3 \ overloaded])

    line((1, -0.2), (1, -0.5), stroke: 0.8pt, mark: (end: ">"))
    line((3, -0.2), (3, -0.5), stroke: 0.8pt, mark: (end: ">"))
    line((9.5, -0.2), (9.5, -0.5), stroke: (paint: red, thickness: 1.5pt), mark: (end: ">"))
  })
)

- *Hot spot* / *skew*: one partition gets disproportionate traffic
- Classic: time-series by date (all writes go to "today's" partition)
- Celebrity problem: `user_id = @taylorswift` → 50% of reads
- Mitigation: key salting, sub-partitioning, application-level splitting

== Hash vs range — decision matrix

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Hash*], [*Range*]),
  [Distribution], [Uniform], [Depends on key distribution],
  [Range queries], [✗ Not supported], [✓ Efficient],
  [Rebalancing cost], [Low (consistent hashing)], [Medium (split/merge)],
  [Hot-spot risk], [Low], [High (without salting)],
)

== \

#hero[Data is split across machines. \ But what if a node dies?]
