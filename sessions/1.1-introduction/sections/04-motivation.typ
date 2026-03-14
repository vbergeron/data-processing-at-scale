#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

== Data Processing at Scale

#hero[Data Processing at Scale]

== What big data made possible

- *Web search* — indexing and ranking the entire internet in milliseconds
- *Recommendations* — Netflix, Spotify, ByteDance's TikTok: personalized feeds from billions of items
- *Live traffic routing* — GPS recalculating paths from millions of drivers in real time
- *Fraud detection* — scoring millions of card transactions per second
- *Genomics* — sequencing cost from \$100M to \$100, powered by parallel processing

== The data explosion

#table(
  columns: 4,
  align: (left, right, right, right),
  table.header(
    [*Year*], [*Global data*], [*Largest HDD*], [*Drives needed*],
  ),
  [2010], [2 ZB], [2 TB], [1 billion],
  [2015], [15 ZB], [10 TB], [1.5 billion],
  [2020], [59 ZB], [20 TB], [3 billion],
  [2025], [175 ZB], [36 TB], [4.9 billion],
)

#text(size: 8pt, fill: luma(120))[
  Sources: IDC Global DataSphere (Statista); Wikipedia _History of hard disk drives_
]

== Throughput — the unifying measure

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(y, width, label, time, color) = {
      rect((0, y), (width, y + 0.7), fill: color, stroke: 0.5pt)
      content((-0.3, y + 0.35), anchor: "east", text(size: 10pt)[#label])
      content((width + 0.3, y + 0.35), anchor: "west", text(size: 10pt)[#time])
    }

    bar(3, 0.1, [1 GB], [1 second], rgb("#c8e6c9"))
    bar(2, 1, [1 TB], [17 minutes], rgb("#a5d6a7"))
    bar(1, 4, [1 PB], [11.6 days], rgb("#fff9c4"))
    bar(0, 12, [1 EB], [31.7 years], rgb("#ffcdd2"))

    content((6, -0.8), text(size: 9pt, fill: luma(120))[at 1 GB/s sustained throughput])
  })
)

- Throughput is how you reason about data regardless of scale
- Even at excellent throughput, growing data makes wall-clock time explode

== Why not just get a bigger machine?

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  align: center,
  [
    *Vertical scaling*
    #cetz.canvas(length: 1cm, {
      import cetz.draw: *

      let box(x, y, w, h, label, color) = {
        rect((x - w/2, y), (x + w/2, y + h), fill: color, stroke: 0.8pt, radius: 0.1)
        content((x, y + h/2), text(size: 10pt)[#label])
      }

      box(0, 6, 2.5, 1.2, [Server], rgb("#bbdefb"))
      line((0, 5.6), (0, 5), stroke: 0.8pt, mark: (end: ">"))
      box(0, 3, 3.2, 1.6, [Bigger Server], rgb("#90caf9"))
      line((0, 2.6), (0, 2), stroke: 0.8pt, mark: (end: ">"))
      box(0, 0, 4, 1.8, [Even Bigger 💰], rgb("#64b5f6"))
    })
  ],
  [
    *Horizontal scaling*
    #cetz.canvas(length: 1cm, {
      import cetz.draw: *

      let srv(x, y) = {
        rect((x - 1, y), (x + 1, y + 1.2), fill: rgb("#c8e6c9"), stroke: 0.8pt, radius: 0.1)
        content((x, y + 0.6), text(size: 10pt)[Server])
      }

      srv(0, 6)
      line((0, 5.6), (0, 5), stroke: 0.8pt, mark: (end: ">"))
      srv(-1.3, 3)
      srv(1.3, 3)
      line((0, 2.6), (0, 2), stroke: 0.8pt, mark: (end: ">"))
      srv(-2.6, 0)
      srv(0, 0)
      srv(2.6, 0)
    })
  ],
)

- Moore's Law is flattening — diminishing returns, single point of failure
- *But*: below \~10 TB, a single beefy server is probably the right call
- Most companies don't actually have big data

== So we distribute

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [Worker 1], fill: rgb("#c8e6c9")),
    node((1, 0), [Worker 2], fill: rgb("#c8e6c9")),
    node((2, 0), [Worker 3], fill: rgb("#c8e6c9")),
    node((1, 1), [Coordinator], fill: rgb("#bbdefb")),
    edge((1, 1), (0, 0), "<->", stroke: (dash: "dashed")),
    edge((1, 1), (1, 0), "<->", stroke: (dash: "dashed")),
    edge((1, 1), (2, 0), "<->", stroke: (dash: "dashed")),
    edge((0, 0), (1, 0), "<->", stroke: (paint: luma(180), dash: "dashed")),
    edge((1, 0), (2, 0), "<->", stroke: (paint: luma(180), dash: "dashed")),
  )
)

- Parallelism gives throughput, but coordination has a price
- A network round-trip costs *millions* of CPU cycles
- This tension is the subject of this course

== \

#hero[Can software ease the pains of hardware?]
