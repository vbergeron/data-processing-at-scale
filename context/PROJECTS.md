# Projects

30 project subjects across 15 datasets. Pick one per team.

Difficulty legend: 🟢 accessible · 🟡 intermediate · 🔴 advanced · ⚫ expert

> Difficulty is calibrated assuming students have access to frontier LLMs (Claude, GPT-4, etc.).
> Projects rated 🟢 are nearly trivial with LLM assistance.
> Projects that remain 🔴/⚫ involve novel library integration, live data, or correctness reasoning that LLMs cannot reliably solve.

---

## GH Archive

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [1](projects/1-github-analytics.md) | **Star-Farming Ring Detection** — detect coordinated starring rings from temporal + graph signals, score inflated repos | Kafka, Flink, ClickHouse | 🟡🟡🔴 |
| [2](projects/2-github-health.md) | **Bus Factor Analysis** — contributor concentration in PySpark *and* DuckDB, find the crossover point | PySpark, DuckDB, Parquet | 🟡🟡🟢 |

## NYC Taxi

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [3](projects/3-taxi-spark.md) | **Urban Pulse: Event Detection** — model the city's rhythm from taxi flow, detect and attribute real-world events from perturbations | PySpark, Parquet | 🟡🟡🟡 |
| [4](projects/4-taxi-geospatial.md) | **Fare Anomaly Detection** — statistical baselines per route with temporal drift detection and adaptive windows | ClickHouse, Python | 🟡🟡🟡 |

## Wikimedia EventStreams

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [5](projects/5-wikipedia-streaming.md) | **Vandalism Detection** — score edits for vandalism likelihood using session-based behavioral signals | Kafka, Flink | 🟡🟡🟢 |
| [6](projects/6-wikipedia-graph.md) | **Knowledge Graph Evolution** — incremental maintenance of link graph metrics as edits arrive | Python, PostgreSQL/DuckDB | 🟡🟡🔴 |

## Stack Exchange

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [7](projects/7-stackoverflow-incremental.md) | **Incremental Analytics** — maintain answer quality scores without recomputation, reason about monotonicity | Python, PostgreSQL/DuckDB | 🟡🟡🔴 |
| [8](projects/8-stackoverflow-expertise.md) | **Distributed Faceted Search with Embedded Lucene** — Lucene indexes inside `mapPartitions`, BM25 + facets, compare vs SQL | Scala, Spark, Lucene | 🔴🔴🔴 |

## GDELT

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [9](projects/9-gdelt-probabilistic.md) | **Probabilistic Event Tracking** — HyperLogLog, Count-Min Sketch, t-digest on news events, compare exact vs approximate | ClickHouse, Python | 🟡🟢🟡 |
| [10](projects/10-gdelt-streaming.md) | **Escalation Early Warning** — detect deteriorating country-pair relations from rolling Goldstein scores | Kafka, Flink, ClickHouse | 🟡🟡🔴 |

## US Stocks / SEC EDGAR

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [11](projects/11-stocks-timeseries.md) | **Time-Series Analytics** — rolling indicators + materialized view cascade, measure write amplification trade-off | ClickHouse, Python | 🟡🟢🟡 |
| [12](projects/12-stocks-fundamentals.md) | **Financial Statement Pipeline** — temporal as-of join between daily prices and quarterly filings | PySpark, Parquet | 🟡🟡🟢 |

## Ethereum + Sourcify

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [13](projects/13-ethereum-onchain.md) | **Decoded On-Chain Analytics** — join transactions with ABI data, decode function calls, analyze gas patterns | ClickHouse, Python | 🟡🟡🔴 |
| [14](projects/14-ethereum-defi.md) | **DeFi Streaming Monitor** — replay token transfers in Flink, detect volume spikes, handle chain reorgs | Kafka, Flink | 🔴🔴🔴 |

## OpenSky Network

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [15](projects/15-opensky-delays.md) | **Flight Density Analytics with Embedded H3** — hexagonal spatial indexing inside `mapPartitions`, multi-resolution aggregation, corridor detection | Scala, Spark, H3 | 🟡🟡🟢 |
| [16](projects/16-opensky-realtime.md) | **Flight Diversion & Anomaly Detection** — detect circling, U-turns, rapid descent from ADS-B streams | Kafka, Flink, ClickHouse | 🟡🟡🔴 |

## Reddit (Pushshift)

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [17](projects/17-reddit-analytics.md) | **Toxicity Scoring with Embedded ONNX** — ONNX Runtime inside `mapPartitions`, distributed ML inference on comments | Scala, Spark, ONNX Runtime | 🟡🔴🔴 |
| [18](projects/18-reddit-virality.md) | **Narrative Cross-Pollination Tracker** — detect topic diffusion across subreddits using Bloom filters | Kafka, Flink | 🟡🔴🔴 |

## Spotify

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [19](projects/19-spotify-recommendations.md) | **Playlist Similarity Engine** — exact Jaccard vs MinHash/LSH approximate similarity at scale | PySpark | 🟡🟢🟡 |
| [20](projects/20-spotify-taste.md) | **Genre Boundary Detection** — artist co-occurrence graph, community detection, genre-bridging identification | PySpark | 🟡🟡🟡 |

## OpenStreetMap

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [21](projects/21-osm-crdt.md) | **Collaborative Edit CRDT Analysis** — model editing as a lattice, detect conflicts, reason about convergence | Python, PostgreSQL/DuckDB | 🟡🟡🔴 |
| [22](projects/22-osm-quality.md) | **Consistency Validator with Embedded Prolog** — Prolog inside `mapPartitions`, negation-as-failure on geographic tiles, boundary handling | Scala, Spark, tuProlog | 🔴🔴🔴 |

## Common Crawl

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [23](projects/23-commoncrawl-domains.md) | **Web-Scale Search with Embedded Lucene** — sharded Lucene indexes inside Spark, cross-shard query merging, IDF reconciliation | Scala, Spark, Lucene | 🔴🔴🔴 |
| [24](projects/24-commoncrawl-linkgraph.md) | **Link Graph Incremental Processing** — maintain PageRank across crawl versions using diffs | Python, DuckDB/PostgreSQL | 🟡🟡🔴 |

## Binance (Live Websocket)

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [25](projects/25-crypto-portfolio.md) | **Real-Time Portfolio Tracker** — transactionally consistent portfolio state, exactly-once 2PC sink to PostgreSQL | Kafka, Flink, PostgreSQL | 🔴🔴🔴 |
| [26](projects/26-crypto-orderbook.md) | **Order Book Reconstruction & Arbitrage** — live order book in Flink state, triangular arbitrage detection | Kafka, Flink, ClickHouse | 🔴🔴⚫ |

## Citi Bike

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [27](projects/27-citibike-hybrid.md) | **Demand Hybrid Pipeline** — batch history in Spark + live station feed in Kafka/ClickHouse | PySpark, Kafka, ClickHouse | 🟡🟡🟢 |
| [28](projects/28-citibike-rebalancing.md) | **Fleet Rebalancing Stream** — maintain station bike counts, detect imbalance, reason about non-monotonic state | Kafka, Flink | 🟡🟡🔴 |

## NOAA Weather

| # | Project | Stack | Difficulty |
|---|---------|-------|------------|
| [29](projects/29-noaa-anomaly.md) | **Extreme Weather Event Attribution** — per-station baselines, compound event detection, trend analysis | ClickHouse, Python | 🟡🟡🟢 |
| [30](projects/30-noaa-correlation.md) | **Global Weather Correlation** — pairwise cross-station correlations, O(n²) optimization strategies | PySpark, Parquet | 🟡🟡🟡 |

---

## Difficulty breakdown

| Level | Count | What it means |
|-------|-------|---------------|
| 🟡🟢🟡 | 3 | Accessible — LLMs help with code, but results require real experimentation |
| 🟡🟡🟢 | 6 | Moderate — requires design decisions and benchmarking |
| 🟡🟡🟡 | 4 | Moderate across the board — multi-dimensional challenges |
| 🟡🟡🔴 | 9 | Hard — correctness reasoning or niche domains |
| 🟡🔴🔴 | 2 | Hard — novel integration + experimentation |
| 🔴🔴🔴 | 5 | Very hard — LLMs can't reliably solve the integration |
| 🔴🔴⚫ | 1 | Expert — live mutable state + cross-stream logic |

The three difficulty dots represent: **data engineering** · **system complexity** · **theoretical depth**.
