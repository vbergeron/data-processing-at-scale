#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Parallelism & Scaling

== \

#hero[Can you just throw \ more machines at it?]

== The cost anatomy of a shuffle

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let phase(x, w, label, cost, color) = {
      rect((x, 0), (x + w, 1.8), fill: color, stroke: 0.8pt, radius: 0.1)
      content((x + w/2, 1.1), text(size: 10pt)[#label])
      content((x + w/2, 0.5), text(size: 8pt, fill: luma(100))[#cost])
    }

    phase(0, 3, [Serialize], [CPU-bound], rgb("#c8e6c9"))
    line((3.2, 0.9), (3.6, 0.9), stroke: 0.8pt, mark: (end: ">"))
    phase(3.8, 3, [Network], [bandwidth-bound], rgb("#ffcdd2"))
    line((7, 0.9), (7.4, 0.9), stroke: 0.8pt, mark: (end: ">"))
    phase(7.6, 3, [Disk spill], [I/O-bound], rgb("#fff9c4"))
    line((10.8, 0.9), (11.2, 0.9), stroke: 0.8pt, mark: (end: ">"))
    phase(11.4, 3, [Deserialize], [CPU-bound], rgb("#c8e6c9"))

    content((7.2, -0.7), text(size: 9pt, fill: luma(120))[100 GB shuffle ≈ 2–5 minutes on a 10-node cluster])
  })
)

- Every shuffle pays *four costs* — each bound by a different resource
- Network is often the bottleneck, but CPU serialization can dominate with complex types
- Disk spill happens when shuffle data exceeds available RAM

== Amdahl's law

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let max-x = 14
    let max-y = 7

    line((0, 0), (max-x + 1, 0), stroke: 0.8pt, mark: (end: ">"))
    line((0, 0), (0, max-y + 1), stroke: 0.8pt, mark: (end: ">"))
    content((max-x + 1.5, -0.4), text(size: 9pt)[cores])
    content((-0.8, max-y + 0.5), text(size: 9pt)[speedup])

    for n in (2, 4, 8, 16, 32, 64) {
      let x = calc.log(n, base: 2) / calc.log(64, base: 2) * max-x
      content((x, -0.5), text(size: 8pt)[#n])
    }
    for s in (2, 5, 10, 20) {
      content((-0.8, s / 20 * max-y), text(size: 8pt)[#{ s }×])
    }

    let curve(serial, color, label-pos, label) = {
      let pts = range(1, 65).map(n => {
        let x = calc.log(n, base: 2) / calc.log(64, base: 2) * max-x
        let speedup = 1 / (serial + (1 - serial) / n)
        let y = speedup / 20 * max-y
        (x, y)
      })
      for i in range(pts.len() - 1) {
        line(pts.at(i), pts.at(i + 1), stroke: (paint: color, thickness: 1.2pt))
      }
      content(label-pos, text(size: 9pt, fill: color)[#label])
    }

    curve(0.01, rgb("#1565c0"), (max-x + 0.3, max-y * 0.98 / 20 * max-y), [1%])
    curve(0.05, rgb("#2e7d32"), (max-x + 0.3, max-y * 0.95 / 20 * max-y - 1), [5%])
    curve(0.1, rgb("#e65100"), (max-x + 0.3, max-y * 0.5 / 20 * max-y), [10%])
    curve(0.25, rgb("#c62828"), (max-x + 0.3, max-y * 0.2 / 20 * max-y), [25%])

    content((7, -1.5), text(size: 9pt, fill: luma(120))[% = fraction of work that is serial (cannot be parallelized)])
  })
)

== Amdahl's law — the takeaway

$ S = 1 / (s + (1 - s) / N) $

- *s* = serial fraction,  *N* = number of processors
- With 5% serial work, *max speedup is 20×* — regardless of how many nodes you add
- Serial bottlenecks: coordination, shuffles, single-threaded drivers, barrier synchronization

== Strong vs weak scaling

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  [
    *Strong scaling*
    - Fixed problem size
    - Add nodes to go *faster*
    - Limited by Amdahl's law
    - Example: "Can I run this 1 TB query in 10 s instead of 100 s?"
  ],
  [
    *Weak scaling*
    - Problem grows with nodes
    - Add nodes to handle *more data*
    - Limited by communication overhead
    - Example: "Can I handle 10 TB instead of 1 TB?"
  ],
)

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  Most data systems need *weak* scaling — data grows, budget is fixed.
]

== Coordination overhead

#align(center,
  fletcher.diagram(
    spacing: (2cm, 1.5cm),
    node-stroke: 0.8pt,
    node((1, 0), [Coordinator], fill: rgb("#bbdefb")),
    node((0, 1), [W1], fill: rgb("#c8e6c9")),
    node((1, 1), [W2], fill: rgb("#c8e6c9")),
    node((2, 1), [W3], fill: rgb("#c8e6c9")),
    node((3, 1), [...], stroke: none),
    node((4, 1), [Wn], fill: rgb("#c8e6c9")),
    edge((1, 0), (0, 1), "<->"),
    edge((1, 0), (1, 1), "<->"),
    edge((1, 0), (2, 1), "<->"),
    edge((1, 0), (4, 1), "<->"),
  )
)

- Every worker must coordinate with the driver: task assignment, shuffle metadata, barriers
- Coordination is *O(N)* or *O(N²)* — adding nodes increases overhead
- At some point, the coordination cost *exceeds the parallelism gain*

== Diminishing returns — why adding nodes stops helping

#table(
  columns: 4,
  align: (center, right, right, right),
  table.header([*Nodes*], [*Compute time*], [*Coord. overhead*], [*Total*]),
  [1], [100 s], [0 s], [100 s],
  [10], [10 s], [2 s], [12 s],
  [50], [2 s], [8 s], [10 s],
  [100], [1 s], [15 s], [16 s],
  [200], [0.5 s], [30 s], [30.5 s],
)

- Going from 1 → 10 nodes: *8× faster*
- Going from 50 → 200 nodes: *3× slower*
- The sweet spot depends on the ratio of computation to coordination

== \

#hero[Parallelism is not free. \ Every node you add pays a coordination tax.]
