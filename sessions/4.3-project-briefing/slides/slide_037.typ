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
