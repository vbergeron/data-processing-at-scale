== Binance (Live Websocket)

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    - Real-time trades and order book updates for all trading pairs
    - ~5–15 GB (24–72h recording for replay)
    - Public websocket, no API key required
  ],
  image("../assets/binance.jpg", height: 80%),
)

== Binance (Live Websocket)

=== \#25 — Real-Time Portfolio Tracker

- *Pitch:* Transactionally consistent portfolio state, exactly-once 2PC sink
- *Difficulty:* █████████░

== Binance (Live Websocket)

=== \#26 — Order Book Reconstruction & Arbitrage

- *Pitch:* Live order book in Flink state, triangular arbitrage detection
- *Difficulty:* ██████████
