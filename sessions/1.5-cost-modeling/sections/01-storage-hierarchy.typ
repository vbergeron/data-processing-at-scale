#import "../../style.typ": hero
#import "@preview/cetz:0.4.2"

== \

#hero[How long _should_ this query take?]

== The storage hierarchy

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(y, width, label, latency, bw, color) = {
      rect((0, y), (width, y + 0.7), fill: color, stroke: 0.5pt)
      content((-0.3, y + 0.35), anchor: "east", text(size: 10pt)[#label])
      content((width + 0.3, y + 0.35), anchor: "west", text(size: 9pt)[#latency  ·  #bw])
    }

    bar(6, 0.05, [L1 cache], [~1 ns], [~1 TB/s], rgb("#c8e6c9"))
    bar(5, 0.1, [L2 cache], [~4 ns], [~500 GB/s], rgb("#c8e6c9"))
    bar(4, 0.3, [L3 cache], [~10 ns], [~200 GB/s], rgb("#a5d6a7"))
    bar(3, 1, [RAM], [~100 ns], [~50 GB/s], rgb("#bbdefb"))
    bar(2, 3, [NVMe SSD], [~10 μs], [~3 GB/s], rgb("#90caf9"))
    bar(1, 7, [Network (datacenter)], [~500 μs], [~1 GB/s], rgb("#fff9c4"))
    bar(0, 14, [Object storage (S3)], [~50 ms], [~0.5 GB/s], rgb("#ffcdd2"))

    content((7, -0.8), text(size: 9pt, fill: luma(120))[each level: ~10× slower, ~10× larger])
  })
)

== The numbers you should know

#table(
  columns: 4,
  align: (left, right, right, right),
  table.header([*Level*], [*Latency*], [*Bandwidth*], [*Read 1 GB*]),
  [L1 cache], [1 ns], [1 TB/s], [1 ms],
  [RAM], [100 ns], [50 GB/s], [20 ms],
  [NVMe SSD (seq.)], [10 μs], [3 GB/s], [330 ms],
  [NVMe SSD (random)], [10 μs], [50 MB/s], [20 s],
  [Datacenter network], [500 μs], [1 GB/s], [1 s],
  [S3 / GCS], [50 ms], [500 MB/s], [2 s],
)

#v(0.3em)

#text(size: 16pt, fill: luma(100))[
  These numbers are approximate — but the *ratios* between them are what matter.
]

== Why ratios matter more than exact numbers

- Hardware changes every year — the *orders of magnitude* between levels stay stable
- "Is this I/O bound or CPU bound?" only requires knowing which level you're hitting
- A query scanning 1 TB from SSD: ~330 s. From S3: ~2000 s. That's a *6× difference* you can predict without running anything.

== Sequential vs random access

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let bar(y, width, label, speed, color) = {
      rect((0, y), (width, y + 0.8), fill: color, stroke: 0.5pt)
      content((-0.3, y + 0.4), anchor: "east", text(size: 10pt)[#label])
      content((width + 0.3, y + 0.4), anchor: "west", text(size: 10pt)[#speed])
    }

    bar(3, 12, [SSD sequential], [3 GB/s], rgb("#c8e6c9"))
    bar(2, 0.2, [SSD random (4K blocks)], [50 MB/s], rgb("#ffcdd2"))
    bar(1, 5, [HDD sequential], [200 MB/s], rgb("#a5d6a7"))
    bar(0, 0.05, [HDD random], [1 MB/s], rgb("#ffcdd2"))

    content((6, -0.8), text(size: 9pt, fill: luma(120))[sequential reads are 60–200× faster than random reads on the same device])
  })
)

- *Sequential*: read consecutive bytes — prefetch and caches work perfectly
- *Random*: jump to arbitrary locations — every read pays the full seek latency
- This single distinction explains most storage performance behavior

== The cache line — the CPU's unit of work

- The CPU doesn't read one byte — it reads a *cache line* (64 bytes)
- If the next data you need is in the same cache line → free
- If it's in a different page → full memory latency

#v(0.5em)

#text(size: 16pt, fill: luma(100))[
  This is why *data layout* matters: whether your data is contiguous in memory determines whether the CPU can prefetch it.
]

== \

#hero[The medium isn't slow. \ Your access pattern is.]
