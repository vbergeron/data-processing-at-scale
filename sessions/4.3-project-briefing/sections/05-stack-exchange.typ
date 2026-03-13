== Stack Exchange

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    - Complete dump of all Stack Exchange sites since 2008
    - ~20 GB uncompressed (Stack Overflow subset)
    - Free download from Internet Archive
  ],
  image("../assets/stackexchange.jpg", height: 80%),
)

== Stack Exchange

=== \#7 — Incremental Analytics

- *Pitch:* Maintain answer quality scores without recomputation, reason about monotonicity
- *Difficulty:* ███████░░░

== Stack Exchange

=== \#8 — Distributed Faceted Search with Embedded Lucene

- *Pitch:* Lucene indexes inside Spark `mapPartitions`, BM25 + facets
- *Requires:* Spark (Scala) + Lucene — JVM embedding
- *Difficulty:* █████████░
