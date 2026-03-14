#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Limitations

== \

#hero[What if your computation \ doesn't fit in one Map + Reduce?]

== Multi-stage pipelines

#align(center,
  fletcher.diagram(
    spacing: (2cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [MR Job 1], fill: rgb("#c8e6c9")),
    node((1, 0), [HDFS], fill: rgb("#e3f2fd")),
    node((2, 0), [MR Job 2], fill: rgb("#c8e6c9")),
    node((3, 0), [HDFS], fill: rgb("#e3f2fd")),
    node((4, 0), [MR Job 3], fill: rgb("#c8e6c9")),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, 0), "->"),
  )
)

- Many real computations need *multiple passes*: filter → join → aggregate
- In classic MapReduce: each stage is a *separate job*
- Between stages: write to HDFS, read it back — full I/O round-trip every time

== The chaining tax

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let phase(x, w, label, color) = {
      rect((x, 0), (x + w, 1.5), fill: color, stroke: 0.8pt, radius: 0.1)
      content((x + w/2, 0.75), text(size: 9pt)[#label])
    }

    phase(0, 2, [MR 1], rgb("#c8e6c9"))
    phase(2.2, 1.5, [Write], rgb("#ffcdd2"))
    phase(3.9, 1.5, [Read], rgb("#ffcdd2"))
    phase(5.6, 2, [MR 2], rgb("#c8e6c9"))
    phase(7.8, 1.5, [Write], rgb("#ffcdd2"))
    phase(9.5, 1.5, [Read], rgb("#ffcdd2"))
    phase(11.2, 2, [MR 3], rgb("#c8e6c9"))

    content((6.6, -0.6), text(size: 9pt, fill: luma(120))[Red = wasted I/O — data written to disk just to be read back immediately])
  })
)

- 3-stage pipeline: 2 unnecessary write-read cycles to HDFS
- HDFS replicates 3×, so each intermediate write is *6× the data volume*
- A 10 GB intermediate result becomes 60 GB of disk I/O

== Iterative workloads — the worst case

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Graph \ data], fill: rgb("#e3f2fd")),
    node((1, 0), [MR \ iteration 1], fill: rgb("#c8e6c9")),
    node((2, 0), [MR \ iteration 2], fill: rgb("#c8e6c9")),
    node((3, 0), [MR \ iteration N], fill: rgb("#c8e6c9")),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, 0), "->", [HDFS]),
    edge((2, 0), (3, 0), "->", [HDFS]),
    edge((0, 0), (1, 0), "->", bend: -40deg, stroke: (dash: "dashed", paint: luma(140))),
    edge((0, 0), (2, 0), "->", bend: -50deg, stroke: (dash: "dashed", paint: luma(140))),
    edge((0, 0), (3, 0), "->", bend: -60deg, stroke: (dash: "dashed", paint: luma(140))),
  )
)

- *PageRank*: each iteration reads the full graph + last iteration's scores
- 20 iterations × full I/O = 20 complete reads of the graph from disk
- The graph *doesn't change* — only the scores do, but MapReduce can't tell

== No in-memory caching

- MapReduce treats every job as independent — no shared state between stages
- Even if intermediate data fits in RAM, it *must* go through HDFS
- Modern engines fix this by keeping data *in memory* across stages

== The join problem

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  [
    *Reduce-side join*
    - Both datasets shuffled by join key
    - All data crosses the network
    - Works for any data size
  ],
  [
    *Map-side join*
    - Small table broadcast to every mapper
    - No shuffle needed
    - Only works if one side fits in memory
  ],
)

#v(0.5em)

- MapReduce has no built-in join — you implement it yourself
- Choosing the wrong join strategy can turn a 5-minute job into a 5-hour job
- Modern engines (Spark) pick the join strategy automatically via an optimizer

== What MapReduce got right

Despite the limitations, MapReduce introduced ideas that *every* engine still uses:

- *Fault tolerance* through deterministic re-execution
- *Data locality* — move compute to data
- *Horizontal scaling* — add machines, not bigger machines
- *Simple programming model* — just map and reduce

#v(0.5em)

#text(size: 16pt, fill: luma(100))[The model is too rigid. The ideas are permanent.]

== \

#hero[Can we keep the ideas \ and drop the limitations?]
