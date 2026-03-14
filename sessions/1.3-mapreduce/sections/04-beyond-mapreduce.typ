#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Beyond MapReduce

== From MapReduce to DAGs

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  align: center,
  [
    *MapReduce chain*
    #fletcher.diagram(
      spacing: (1.5cm, 1cm),
      node-stroke: 0.8pt,
      node((0, 0), [M], fill: rgb("#c8e6c9")),
      node((1, 0), [R], fill: rgb("#bbdefb")),
      node((2, 0), [M], fill: rgb("#c8e6c9")),
      node((3, 0), [R], fill: rgb("#bbdefb")),
      edge((0, 0), (1, 0), "->"),
      edge((1, 0), (2, 0), "->", [disk]),
      edge((2, 0), (3, 0), "->"),
    )
  ],
  [
    *DAG execution*
    #fletcher.diagram(
      spacing: (1.5cm, 1cm),
      node-stroke: 0.8pt,
      node((0, 0), [Scan], fill: rgb("#c8e6c9")),
      node((0, 1), [Scan], fill: rgb("#c8e6c9")),
      node((1, 0), [Filter], fill: rgb("#e3f2fd")),
      node((1.5, 0.5), [Join], fill: rgb("#fff9c4")),
      node((2.5, 0.5), [Agg], fill: rgb("#bbdefb")),
      edge((0, 0), (1, 0), "->"),
      edge((1, 0), (1.5, 0.5), "->"),
      edge((0, 1), (1.5, 0.5), "->"),
      edge((1.5, 0.5), (2.5, 0.5), "->"),
    )
  ],
)

#v(0.5em)

- A *DAG* (directed acyclic graph) can express arbitrary operator pipelines
- Intermediate data flows directly between operators — no mandatory disk writes
- The engine decides *where* to shuffle and *where* to pipeline

== The generation shift

#table(
  columns: 4,
  align: (left, center, center, center),
  table.header([*Engine*], [*Model*], [*In-memory?*], [*Appeared*]),
  [Hadoop MapReduce], [Map + Reduce], [No], [2006],
  [Apache Spark], [DAG of RDDs], [Yes], [2014],
  [Apache Flink], [Streaming DAG], [Yes], [2015],
  [Google Dataflow], [Unified batch + stream], [Yes], [2015],
  [DuckDB], [Single-node DAG], [Yes], [2019],
)

- Each generation kept the *ideas* (parallelism, fault tolerance, locality)
- And fixed the *problems* (no caching, rigid model, disk-bound)

== Data locality — move compute to data

#align(center,
  fletcher.diagram(
    spacing: (3cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Node 1 \ has blocks A, B], fill: rgb("#c8e6c9")),
    node((1, 0), [Node 2 \ has blocks C, D], fill: rgb("#c8e6c9")),
    node((2, 0), [Node 3 \ has blocks E, F], fill: rgb("#c8e6c9")),
    node((0, 1), [Task A, B], fill: rgb("#bbdefb")),
    node((1, 1), [Task C, D], fill: rgb("#bbdefb")),
    node((2, 1), [Task E, F], fill: rgb("#bbdefb")),
    edge((0, 0), (0, 1), "->", stroke: rgb("#1565c0")),
    edge((1, 0), (1, 1), "->", stroke: rgb("#1565c0")),
    edge((2, 0), (2, 1), "->", stroke: rgb("#1565c0")),
  )
)

- Schedule the task on the node that *already has the data*
- Avoids network transfer entirely for the map phase
- Works with HDFS, where data blocks have known locations

== Data locality — when it breaks

- *Cloud object storage* (S3, GCS): data has no fixed location
- Compute and storage are *decoupled* — any node can read any data
- Locality still matters *within* a shuffle: co-locate related keys

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  In the cloud, "data locality" shifts from "where the block lives" to "how much network you cross."
]

== Fault tolerance — two strategies

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Lineage (Spark)*], [*Checkpointing (Flink)*]),
  [How it works], [Re-execute from inputs], [Restore from snapshot],
  [Cost during normal run], [None (just metadata)], [Periodic write],
  [Recovery time], [Proportional to lost work], [Fast (last checkpoint)],
  [Best for], [Batch, short stages], [Streaming, long-running],
)

- *Lineage*: remember how each partition was computed → recompute on failure
- *Checkpointing*: periodically save state → restore from last good snapshot
- Both avoid re-running the *entire* pipeline

== Lineage-based recovery

#align(center,
  fletcher.diagram(
    spacing: (2cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Input A], fill: rgb("#e3f2fd")),
    node((0, 1), [Input B], fill: rgb("#e3f2fd")),
    node((1, 0.5), [Filter], fill: rgb("#c8e6c9")),
    node((2, 0.5), text(fill: red)[Join ✗], fill: rgb("#ffcdd2"), stroke: (paint: red, dash: "dashed")),
    node((3, 0.5), [Agg], fill: rgb("#bbdefb")),
    edge((0, 0), (1, 0.5), "->"),
    edge((0, 1), (1, 0.5), "->"),
    edge((1, 0.5), (2, 0.5), "->"),
    edge((2, 0.5), (3, 0.5), "->"),
  )
)

- The join stage fails — Spark traces back through the *lineage graph*
- Re-reads inputs A and B, re-runs filter, then re-runs join
- The programmer writes nothing — fault tolerance is *built into the model*

== Speculative execution

- *Straggler*: one task runs much slower than the rest (disk issue, noisy neighbor)
- The framework launches a *duplicate* task on another node
- Whichever finishes first wins — the other is killed
- Key requirement: tasks must be *deterministic* and *side-effect-free*

== \

#hero[MapReduce is retired. \ Its ideas run every query you'll ever write.]
