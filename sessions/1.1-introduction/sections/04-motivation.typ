#import "../../style.typ": hero

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

- 1 KB/μs = 1 GB/s — same throughput, different scale
- At 1 GB/s, reading 1 PB takes *11.6 days*
- At 1 GB/s, reading 1 EB takes *31.7 years*
- Throughput is how you reason about data regardless of scale
- Even at excellent throughput, growing data makes wall-clock time explode

== Why not just get a bigger machine?

- Moore's Law is flattening — transistor density gains are slowing down
- Vertical scaling has diminishing returns and is a single point of failure
- *But* — when data fits on one machine, vertical scaling wins economically
- *Rule of thumb:* below \~10 TB, a single beefy server is probably the right call
- Most companies don't actually have big data

== So we distribute

- When one machine isn't enough, we spread work across many
- But inter-server communication is slow: a network round-trip costs millions of CPU cycles
- The core tension: parallelism gives throughput, coordination has a price
- This tension is the subject of this course

== \

#hero[Can software ease the pains of hardware?]
