#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Shuffle & Sort

== Anatomy of a shuffle

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let y = 0
    let h = 1.5
    let gap = 0.4

    let phase(x, w, label, color) = {
      rect((x, y), (x + w, y + h), fill: color, stroke: 0.8pt, radius: 0.1)
      content((x + w/2, y + h/2), text(size: 10pt)[#label])
    }

    let arrow(x) = {
      line((x, y + h/2), (x + gap, y + h/2), stroke: 0.8pt, mark: (end: ">"))
    }

    phase(0, 2.5, [Serialize], rgb("#c8e6c9"))
    arrow(2.5)
    phase(2.9, 2.5, [Partition], rgb("#bbdefb"))
    arrow(5.4)
    phase(5.8, 2.5, [Sort], rgb("#fff9c4"))
    arrow(8.3)
    phase(8.7, 3.0, [Network \ transfer], rgb("#ffcdd2"))
    arrow(11.7)
    phase(12.1, 2.5, [Merge], rgb("#bbdefb"))
    arrow(14.6)
    phase(15.0, 2.8, [Deserialize], rgb("#c8e6c9"))

    content((8.9, -1), text(size: 9pt, fill: luma(120))[each phase adds latency — the network is often the bottleneck])
  })
)

- Every `(key, value)` pair emitted by a mapper must reach the right reducer
- The framework: serializes, partitions by key hash, sorts, transfers, merges, deserializes
- This is the *most expensive* step — it's the only one that touches the network

== Why the shuffle dominates cost

#table(
  columns: 3,
  align: (left, right, right),
  table.header([*Phase*], [*Throughput*], [*100 GB shuffle*]),
  [Serialize / deserialize], [~2 GB/s (CPU-bound)], [~50 s],
  [Local sort + spill to disk], [~500 MB/s], [~200 s],
  [Network transfer], [~1 GB/s (10 Gbps link)], [~100 s],
  [Merge sorted runs], [~1 GB/s], [~100 s],
)

- A 100 GB shuffle takes *minutes* — dominated by disk I/O and network
- Reducing shuffle volume is the single biggest optimization lever
- Two tools: *combiners* and *partitioning*

== Sort-based aggregation

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let col1 = 0
    let col2 = 7
    let col3 = 14

    content((col1, 4.5), text(size: 11pt, weight: "bold")[Unsorted])
    content((col2, 4.5), text(size: 11pt, weight: "bold")[Sorted by key])
    content((col3, 4.5), text(size: 11pt, weight: "bold")[Grouped])

    rect((col1 - 1.5, 0), (col1 + 1.5, 4), fill: rgb("#fff9c4"), stroke: 0.8pt, radius: 0.1)
    content((col1, 3.3), text(size: 9pt)[`(cat, 1)`])
    content((col1, 2.6), text(size: 9pt)[`(the, 1)`])
    content((col1, 1.9), text(size: 9pt)[`(cat, 1)`])
    content((col1, 1.2), text(size: 9pt)[`(the, 1)`])

    rect((col2 - 1.5, 0), (col2 + 1.5, 4), fill: rgb("#c8e6c9"), stroke: 0.8pt, radius: 0.1)
    content((col2, 3.3), text(size: 9pt)[`(cat, 1)`])
    content((col2, 2.6), text(size: 9pt)[`(cat, 1)`])
    content((col2, 1.9), text(size: 9pt)[`(the, 1)`])
    content((col2, 1.2), text(size: 9pt)[`(the, 1)`])

    rect((col3 - 1.8, 0), (col3 + 1.8, 4), fill: rgb("#bbdefb"), stroke: 0.8pt, radius: 0.1)
    content((col3, 3.3), text(size: 9pt)[`cat → [1, 1]`])
    content((col3, 1.9), text(size: 9pt)[`the → [1, 1]`])

    line((col1 + 1.7, 2), (col2 - 1.7, 2), stroke: 0.8pt, mark: (end: ">"))
    line((col2 + 1.7, 2), (col3 - 2, 2), stroke: 0.8pt, mark: (end: ">"))
  })
)

- Sort brings identical keys together — no hash table needed
- Enables *streaming aggregation*: process one key group at a time, constant memory
- This is why MapReduce always sorts — even when you don't ask for it

== Combiners — local pre-aggregation

#align(center,
  fletcher.diagram(
    spacing: (2cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Map 1 \ `(a,1)(a,1)(b,1)`], fill: rgb("#c8e6c9"), width: 4cm),
    node((0, 1), [Map 2 \ `(a,1)(b,1)(b,1)`], fill: rgb("#c8e6c9"), width: 4cm),
    node((1, 0), [Combiner \ `(a,2)(b,1)`], fill: rgb("#fff9c4"), width: 3cm),
    node((1, 1), [Combiner \ `(a,1)(b,2)`], fill: rgb("#fff9c4"), width: 3cm),
    node((2.3, 0.5), [Reduce \ `(a,3)(b,3)`], fill: rgb("#bbdefb"), width: 3cm),
    edge((0, 0), (1, 0), "->"),
    edge((0, 1), (1, 1), "->"),
    edge((1, 0), (2.3, 0.5), "->"),
    edge((1, 1), (2.3, 0.5), "->"),
  )
)

- A *combiner* runs the reduce function *locally* on each mapper's output
- Reduces shuffle volume: 6 pairs → 4 pairs in this example
- On real data, combiners can cut shuffle size by *90%+*

== When can you use a combiner?

- The reduce function must be *associative* and *commutative*
- `sum`, `max`, `min`, `count` — yes
- `average`, `median`, `top-k` — not directly (need restructuring)

#v(0.5em)

#table(
  columns: 3,
  align: (left, center, center),
  table.header([*Operation*], [*Combiner-safe?*], [*Why*]),
  [Sum], [✓], [sum(sum(a,b), sum(c,d)) = sum(a,b,c,d)],
  [Max], [✓], [max is associative and commutative],
  [Average], [✗], [avg(avg(1,2), avg(3,4)) ≠ avg(1,2,3,4)],
  [Average (restructured)], [✓], [Emit `(sum, count)`, divide at the end],
)

== Partitioning — controlling key distribution

#align(center,
  fletcher.diagram(
    spacing: (3cm, 1.5cm),
    node-stroke: 0.8pt,
    node((0, 0), [Map output], fill: rgb("#c8e6c9"), width: 3cm),
    node((1, 0), [Reducer 0 \ keys A–M], fill: rgb("#bbdefb"), width: 3cm),
    node((1, 1), [Reducer 1 \ keys N–Z], fill: rgb("#bbdefb"), width: 3cm),
    edge((0, 0), (1, 0), "->", [`hash(k) mod 2 = 0`], label-side: left),
    edge((0, 0), (1, 1), "->", [`hash(k) mod 2 = 1`], label-side: left),
  )
)

- Default: `hash(key) mod R` distributes keys across *R* reducers
- Skewed keys → skewed reducers → one reducer does all the work
- Custom partitioners let you control the distribution

== Data skew — the recurring problem

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(x, h, label, color) = {
      rect((x - 0.6, 0), (x + 0.6, h), fill: color, stroke: 0.8pt, radius: 0.05)
      content((x, -0.6), text(size: 9pt)[#label])
      content((x, h + 0.4), text(size: 9pt)[#calc.round(h * 10, digits: 0) GB])
    }

    bar(1, 1, [R0], rgb("#c8e6c9"))
    bar(3, 1.2, [R1], rgb("#c8e6c9"))
    bar(5, 0.8, [R2], rgb("#c8e6c9"))
    bar(7, 5, [R3 🔥], rgb("#ffcdd2"))
    bar(9, 0.9, [R4], rgb("#c8e6c9"))

    line((0, 0), (10.5, 0), stroke: 0.8pt)
    content((5, -1.5), text(size: 9pt, fill: luma(120))[Reducer 3 has a hot key — the entire job waits for it])
  })
)

- *Data skew*: one reducer gets disproportionate data
- The job's wall-clock time = the *slowest reducer's* time
- Mitigations: key salting, two-phase aggregation, sampling-based partitioners
