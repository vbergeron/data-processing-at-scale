== Citi Bike

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    - Every Citi Bike trip in NYC since 2013 + real-time station status
    - ~10 GB CSV (trip history) + live JSON feed
    - Free download, no authentication
  ],
  image("../assets/citibike.jpg", height: 80%),
)

== Citi Bike

=== \#27 — Demand Hybrid Pipeline

- *Pitch:* Batch history in Spark + live station feed in Kafka/ClickHouse
- *Difficulty:* █████░░░░░

== Citi Bike

=== \#28 — Fleet Rebalancing Stream

- *Pitch:* Maintain station bike counts, detect imbalance, reason about non-monotonic state
- *Difficulty:* ███████░░░
