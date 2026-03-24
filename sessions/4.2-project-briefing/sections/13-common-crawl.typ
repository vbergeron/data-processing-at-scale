== Common Crawl

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    - Monthly crawl of the entire public web (2–3 billion pages per crawl)
    - ~10–20 GB Parquet (columnar index for one crawl)
    - Free from S3 (requester-pays) or direct HTTP
  ],
  image("../assets/commoncrawl.jpg", height: 80%),
)

== Common Crawl

=== \#23 — Web-Scale Search with Embedded Lucene

- *Pitch:* Sharded Lucene indexes inside Spark, cross-shard query merging
- *Requires:* Spark (Scala) + Lucene — JVM embedding
- *Difficulty:* █████████░

== Common Crawl

=== \#24 — Link Graph Incremental Processing

- *Pitch:* Maintain PageRank across crawl versions using diffs
- *Difficulty:* ███████░░░
