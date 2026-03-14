#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

== \

#hero[How do you process data \ that doesn't fit on one machine?]

== The idea

- You have 10 TB of web logs. One machine reads at 500 MB/s → *5.5 hours*
- 100 machines, each reading 100 GB → *3 minutes*
- But how do you *coordinate* the work and *aggregate* the results?

== The MapReduce programming model

#align(center,
  fletcher.diagram(
    spacing: (2cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Input \ splits], fill: rgb("#e3f2fd"), width: 2.5cm),
    node((1, 0), [*Map*], fill: rgb("#c8e6c9"), width: 2.5cm),
    node((2, 0), [Shuffle \ & Sort], fill: rgb("#fff9c4"), width: 2.5cm),
    node((3, 0), [*Reduce*], fill: rgb("#bbdefb"), width: 2.5cm),
    node((4, 0), [Output], fill: rgb("#e3f2fd"), width: 2.5cm),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, 0), "->"),
  )
)

- *Map*: transform each record independently → emit `(key, value)` pairs
- *Shuffle*: group all values by key, transfer across the network
- *Reduce*: aggregate values for each key → produce final output

== Word count — the "Hello World" of MapReduce

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  [
    *Map function*
    ```
    map(doc):
      for word in doc.split():
        emit(word, 1)
    ```
  ],
  [
    *Reduce function*
    ```
    reduce(word, counts):
      emit(word, sum(counts))
    ```
  ],
)

#v(0.5em)

- The programmer writes *only* map and reduce
- The framework handles partitioning, scheduling, fault tolerance, and I/O
- Constraint: map and reduce must be *pure functions* — no shared state

== Word count — data flow

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let col1 = 0
    let col2 = 5
    let col3 = 10
    let col4 = 15

    content((col1, 5.5), text(size: 11pt, weight: "bold")[Input])
    content((col2, 5.5), text(size: 11pt, weight: "bold")[Map output])
    content((col3, 5.5), text(size: 11pt, weight: "bold")[Shuffled])
    content((col4, 5.5), text(size: 11pt, weight: "bold")[Reduced])

    rect((col1 - 1.5, 0), (col1 + 1.5, 5), fill: rgb("#e3f2fd"), stroke: 0.8pt, radius: 0.1)
    content((col1, 3.5), text(size: 9pt)[`"the cat`])
    content((col1, 2.7), text(size: 9pt)[` sat on`])
    content((col1, 1.9), text(size: 9pt)[` the mat"`])

    rect((col2 - 1.5, 0), (col2 + 1.5, 5), fill: rgb("#c8e6c9"), stroke: 0.8pt, radius: 0.1)
    content((col2, 4.2), text(size: 9pt)[`(the, 1)`])
    content((col2, 3.5), text(size: 9pt)[`(cat, 1)`])
    content((col2, 2.8), text(size: 9pt)[`(sat, 1)`])
    content((col2, 2.1), text(size: 9pt)[`(on, 1)`])
    content((col2, 1.4), text(size: 9pt)[`(the, 1)`])
    content((col2, 0.7), text(size: 9pt)[`(mat, 1)`])

    rect((col3 - 1.5, 0), (col3 + 1.5, 5), fill: rgb("#fff9c4"), stroke: 0.8pt, radius: 0.1)
    content((col3, 4.2), text(size: 9pt)[`the → [1, 1]`])
    content((col3, 3.5), text(size: 9pt)[`cat → [1]`])
    content((col3, 2.8), text(size: 9pt)[`sat → [1]`])
    content((col3, 2.1), text(size: 9pt)[`on  → [1]`])
    content((col3, 1.4), text(size: 9pt)[`mat → [1]`])

    rect((col4 - 1.5, 0), (col4 + 1.5, 5), fill: rgb("#bbdefb"), stroke: 0.8pt, radius: 0.1)
    content((col4, 4.2), text(size: 9pt)[`(the, 2)`])
    content((col4, 3.5), text(size: 9pt)[`(cat, 1)`])
    content((col4, 2.8), text(size: 9pt)[`(sat, 1)`])
    content((col4, 2.1), text(size: 9pt)[`(on, 1)`])
    content((col4, 1.4), text(size: 9pt)[`(mat, 1)`])

    line((col1 + 1.7, 2.5), (col2 - 1.7, 2.5), stroke: 0.8pt, mark: (end: ">"))
    line((col2 + 1.7, 2.5), (col3 - 1.7, 2.5), stroke: 0.8pt, mark: (end: ">"))
    line((col3 + 1.7, 2.5), (col4 - 1.7, 2.5), stroke: 0.8pt, mark: (end: ">"))
  })
)

== Parallel execution

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 1.5cm),
    node-stroke: 0.8pt,
    node((0, 0), [Split 1], fill: rgb("#e3f2fd")),
    node((0, 1), [Split 2], fill: rgb("#e3f2fd")),
    node((0, 2), [Split 3], fill: rgb("#e3f2fd")),
    node((1, 0), [Map 1], fill: rgb("#c8e6c9")),
    node((1, 1), [Map 2], fill: rgb("#c8e6c9")),
    node((1, 2), [Map 3], fill: rgb("#c8e6c9")),
    node((2, 0), [Reduce A–M], fill: rgb("#bbdefb")),
    node((2, 2), [Reduce N–Z], fill: rgb("#bbdefb")),
    edge((0, 0), (1, 0), "->"),
    edge((0, 1), (1, 1), "->"),
    edge((0, 2), (1, 2), "->"),
    edge((1, 0), (2, 0), "->", stroke: luma(160)),
    edge((1, 0), (2, 2), "->", stroke: luma(160)),
    edge((1, 1), (2, 0), "->", stroke: luma(160)),
    edge((1, 1), (2, 2), "->", stroke: luma(160)),
    edge((1, 2), (2, 0), "->", stroke: luma(160)),
    edge((1, 2), (2, 2), "->", stroke: luma(160)),
  )
)

- Input is split into *chunks* — one per mapper
- Each mapper runs independently on its chunk — *embarrassingly parallel*
- Every mapper sends data to *every reducer* — this is the shuffle

== The key insight

#hero[
  The programmer thinks about *one record*. \
  The framework handles *a million machines*.
]

== MapReduce in the real world

#table(
  columns: 2,
  align: (left, left),
  table.header([*Problem*], [*Map / Reduce*]),
  [Word count], [Emit `(word, 1)` / Sum counts],
  [Inverted index], [Emit `(word, doc_id)` / Collect doc lists],
  [Sort], [Emit `(key, record)` / Identity reduce],
  [Log analysis], [Parse + filter / Aggregate by status code],
  [Join (reduce-side)], [Tag + emit by join key / Match tagged records],
)

- The model is *general* — any computation that fits the key-value contract
- But not every computation fits naturally...

== \

#hero[The shuffle is where the money goes.]
