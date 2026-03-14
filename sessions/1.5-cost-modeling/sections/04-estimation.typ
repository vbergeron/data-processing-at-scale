#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Back-of-the-Envelope Estimation

== The estimation framework

+ *How much data?* — table size in bytes (not rows)
+ *What access pattern?* — sequential scan, random lookup, shuffle?
+ *What's the bottleneck?* — disk, network, CPU, memory?
+ *Divide by throughput* at that bottleneck → expected time
+ *Sanity check*: does the answer feel right?

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  You don't need exact numbers. You need the right *order of magnitude*.
]

== Worked example — scanning 1 TB

*Question*: How long to scan 1 TB from SSD on a single node?

- SSD sequential read: ~3 GB/s
- 1 TB / 3 GB/s = *333 seconds* ≈ 5.5 minutes

*What if it's Parquet and we only need 3 of 100 columns?*

- Column pruning: read 3% of the data = 30 GB
- 30 GB / 3 GB/s = *10 seconds*
- Columnar storage turned a 5-minute scan into a 10-second scan

== Worked example — shuffling 100 GB

*Question*: How long to shuffle 100 GB across a 10-node cluster?

- 10 Gbps network = ~1 GB/s per link
- Each node sends ~10 GB, receives ~10 GB
- Network time: 10 GB / 1 GB/s = *10 seconds*
- But: serialization at ~2 GB/s = 5 s, disk spill = 10 s, deserialization = 5 s
- Total: ~*30 seconds* (not 10 — the pipeline doesn't fully overlap)

#text(size: 16pt, fill: luma(100))[Rule of thumb: multiply the network estimate by 3× for a realistic shuffle time.]

== Worked example — parallel scan

*Question*: 1 TB scan, 10 nodes, each with SSD at 3 GB/s?

- Each node reads 100 GB / 3 GB/s = *33 seconds*
- Coordination overhead: ~2 s for task scheduling
- Total: ~*35 seconds*

*Same scan, 100 nodes?*

- Each node reads 10 GB = *3.3 seconds*
- Coordination: ~5 s (more nodes = more metadata)
- Total: ~*8 seconds* — coordination is already half the time

== The straggler problem

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(y, width, label, color) = {
      rect((0, y), (width, y + 0.6), fill: color, stroke: 0.5pt, radius: 0.05)
      content((-0.4, y + 0.3), anchor: "east", text(size: 9pt)[#label])
    }

    bar(5, 8, [Task 1], rgb("#c8e6c9"))
    bar(4, 7, [Task 2], rgb("#c8e6c9"))
    bar(3, 9, [Task 3], rgb("#c8e6c9"))
    bar(2, 7.5, [Task 4], rgb("#c8e6c9"))
    bar(1, 15, [Task 5 🐌], rgb("#ffcdd2"))

    line((15, 0.5), (15, 6), stroke: (paint: red, thickness: 1.5pt, dash: "dashed"))
    content((15.5, 3.5), anchor: "west", text(size: 9pt, fill: red)[job finishes \ here])

    line((9.5, 0.5), (9.5, 6), stroke: (paint: rgb("#1565c0"), thickness: 1pt, dash: "dotted"))
    content((9.8, 6.3), text(size: 9pt, fill: rgb("#1565c0"))[4 of 5 done])

    content((7.5, -0.5), text(size: 9pt, fill: luma(120))[wall-clock time is determined by the slowest task])
  })
)

- One slow task delays the *entire* job — all other nodes sit idle
- Causes: data skew, disk contention, GC pause, noisy neighbor, network congestion
- Mitigation: speculative execution, smaller partitions, skew handling

== Why "just add more nodes" fails

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((1, 0), [Driver], fill: rgb("#bbdefb")),
    node((0, 1), [W], fill: rgb("#c8e6c9")),
    node((0.5, 1), [W], fill: rgb("#c8e6c9")),
    node((1, 1), [W], fill: rgb("#c8e6c9")),
    node((1.5, 1), [W], fill: rgb("#c8e6c9")),
    node((2, 1), [W], fill: rgb("#c8e6c9")),
    edge((1, 0), (0, 1), "->", stroke: luma(160)),
    edge((1, 0), (0.5, 1), "->", stroke: luma(160)),
    edge((1, 0), (1, 1), "->", stroke: luma(160)),
    edge((1, 0), (1.5, 1), "->", stroke: luma(160)),
    edge((1, 0), (2, 1), "->", stroke: luma(160)),
  )
)

Three scaling walls:

+ *Amdahl's law*: serial fraction caps the speedup
+ *Coordination overhead*: more nodes = more metadata, more shuffles, more barriers
+ *Straggler tail*: more nodes = higher probability of one slow node

== The estimation checklist

Before running a query or designing a pipeline, ask:

- How many *bytes* will be read? (Not rows — bytes.)
- How many *bytes* will cross the network? (Shuffles, broadcast.)
- What's the *serial* fraction? (Driver logic, single-partition operations.)
- What's the *slowest component*? (That's your bottleneck.)

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  If your estimate and the actual runtime differ by 10×, something is wrong — investigate.
]
