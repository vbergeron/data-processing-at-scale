== US Stocks / SEC EDGAR

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    - Daily OHLCV (open, high, low, close, volume) for all US stocks
    - Quarterly financial statements
    - ~10–15 GB combined
    - Kaggle (account) or SEC EDGAR (no auth)
  ],
  image("../assets/stocks.jpg", height: 80%),
)

== US Stocks / SEC EDGAR

=== \#11 — Time-Series Analytics

- *Pitch:* Rolling indicators + materialized view cascade, measure write amplification
- *Difficulty:* █████░░░░░

== US Stocks / SEC EDGAR

=== \#12 — Financial Statement Pipeline

- *Pitch:* Temporal as-of join between daily prices and quarterly filings
- *Difficulty:* █████░░░░░
