# Datasets

Public datasets used across the projects. All are freely available and downloadable without authentication.

---

## GH Archive

- **URL:** https://www.gharchive.org/
- **Description:** Hourly JSON archives of all public GitHub events (PushEvent, IssueEvent, PullRequestEvent, etc.) since 2011.
- **Size:** ~50–150 MB per hour (gzipped JSON), ~1–3 GB/day. A single month is ~50–90 GB uncompressed.
- **Recommended subset:** 1 week to 1 month of data (~5–15 GB compressed).
- **Format:** Newline-delimited JSON (`.json.gz`)
- **Access:** Direct HTTP download, one file per hour: `https://data.gharchive.org/2024-01-01-0.json.gz`
- **Used in:** [Project 1 — GitHub Event Analytics](projects/1-github-analytics.md), [Project 2 — Open Source Health Metrics](projects/2-github-health.md)

---

## NYC TLC Trip Record Data

- **URL:** https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- **Description:** Every taxi and for-hire vehicle trip in New York City. Includes pickup/dropoff locations, timestamps, fares, tips, passenger count.
- **Size:** ~1–2 GB per month (Parquet). Full yellow taxi history (2009–2024) is ~300 GB.
- **Recommended subset:** 6–12 months of yellow taxi data (~10–20 GB Parquet).
- **Format:** Parquet
- **Access:** Direct HTTP download from the NYC open data portal.
- **Used in:** [Project 3 — Taxi Trip Batch Processing](projects/3-taxi-spark.md), [Project 4 — Geospatial Demand Analytics](projects/4-taxi-geospatial.md)

---

## Wikimedia EventStreams

- **URL:** https://stream.wikimedia.org/
- **Documentation:** https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams
- **Description:** Real-time Server-Sent Events (SSE) stream of all changes across all Wikimedia projects (Wikipedia, Wiktionary, etc.). Includes edits, page creations, log actions.
- **Size:** ~5,000–15,000 events/minute depending on time of day. Can be recorded for offline replay.
- **Recommended approach:** Record 24–48h of events to a file for reproducible processing (~2–5 GB).
- **Format:** SSE with JSON payloads
- **Access:** Open SSE endpoint, no authentication. Also available via Kafka: `kafka.wikimedia.org`
- **Used in:** [Project 5 — Wikipedia Edit Stream Processing](projects/5-wikipedia-streaming.md), [Project 6 — Knowledge Graph Evolution](projects/6-wikipedia-graph.md)

---

## Stack Exchange Data Dump

- **URL:** https://archive.org/details/stackexchange
- **Description:** Complete dump of all Stack Exchange sites. Stack Overflow alone includes all questions, answers, comments, votes, users, tags, and badges since 2008.
- **Size:** Stack Overflow: ~60 GB (compressed XML). Smaller sites (e.g., dba.stackexchange.com) are ~500 MB–2 GB.
- **Recommended subset:** Stack Overflow Posts + Votes + Users (~20 GB uncompressed) or a smaller site for faster iteration.
- **Format:** 7z-compressed XML files
- **Access:** Free download from Internet Archive.
- **Used in:** [Project 7 — Stack Overflow Incremental Analytics](projects/7-stackoverflow-incremental.md), [Project 8 — Distributed Faceted Search with Embedded Lucene](projects/8-stackoverflow-expertise.md)

---

## GDELT Project

- **URL:** https://www.gdeltproject.org/
- **Documentation:** https://blog.gdeltproject.org/gdelt-2-0-our-global-world-in-realtime/
- **Description:** Monitors the world's broadcast, print, and web news media in over 100 languages. Records events (who did what to whom, where, when) and sentiment. Updated every 15 minutes.
- **Size:** GDELT 2.0 Event Database: ~500 MB/day (CSV). Full history since 1979 is ~1 TB.
- **Recommended subset:** 1–3 months of GDELT 2.0 events (~15–45 GB CSV).
- **Format:** Tab-separated CSV, zipped
- **Access:** Direct HTTP download, files updated every 15 minutes.
- **Used in:** [Project 9 — Global News Event Tracking](projects/9-gdelt-probabilistic.md), [Project 10 — Geopolitical Event Streaming](projects/10-gdelt-streaming.md)

---

## Kaggle Finance — US Stock Market (Daily / Intraday)

- **URL:** https://www.kaggle.com/datasets/jacksoncrow/stock-market-dataset
- **Alternative (larger):** https://www.kaggle.com/datasets/borismarjanovic/price-volume-data-for-all-us-stocks-etfs
- **SEC EDGAR filings:** https://www.sec.gov/dera/data/financial-statement-data-sets
- **Description:** Historical daily OHLCV (Open, High, Low, Close, Volume) data for all US-listed stocks and ETFs. SEC EDGAR provides quarterly financial statement data for all public companies.
- **Size:** Daily OHLCV for all US stocks: ~5–10 GB. SEC EDGAR filings: ~1 GB/quarter.
- **Recommended subset:** Full daily OHLCV history + 2–3 years of SEC filings (~10–15 GB combined).
- **Format:** CSV
- **Access:** Free download from Kaggle (account required) or SEC EDGAR (no auth).
- **Used in:** [Project 11 — Stock Market Time-Series Analytics](projects/11-stocks-timeseries.md), [Project 12 — Financial Statement Pipeline](projects/12-stocks-fundamentals.md)

---

## Ethereum Public Dataset (Blockchain ETL)

- **URL:** https://github.com/blockchain-etl/ethereum-etl
- **BigQuery:** `bigquery-public-data.crypto_ethereum`
- **Description:** Every transaction, block, log, token transfer, and contract trace on the Ethereum blockchain since genesis (July 2015). Includes sender/receiver addresses, gas used, value transferred, and contract interactions.
- **Size:** Full export is multi-TB. Transactions alone: ~2 GB/month (CSV/Parquet). A 3-month export is ~5–10 GB.
- **Recommended subset:** 3–6 months of transactions + token transfers (~10–20 GB).
- **Format:** CSV or Parquet (via `ethereum-etl` CLI export)
- **Access:** Free export via `ethereum-etl` CLI against a public node, or direct BigQuery queries (free tier: 1 TB/month).
- **Used in:** [Project 13 — Decoded On-Chain Analytics](projects/13-ethereum-onchain.md), [Project 14 — DeFi Activity Stream Processing](projects/14-ethereum-defi.md)

---

## Sourcify (Verified Smart Contracts)

- **URL:** https://sourcify.dev/
- **Repository:** https://repo.sourcify.dev/
- **Description:** Open repository of verified Ethereum smart contract source code. Maps deployed bytecode to human-readable Solidity source, ABI, and metadata. Covers Ethereum mainnet and many L2/testnets.
- **Size:** Full repository: ~50–100 GB. Metadata JSON index: ~5–10 GB.
- **Recommended subset:** All verified contracts on Ethereum mainnet (~10–20 GB source + metadata).
- **Format:** JSON (metadata, ABI), Solidity source files
- **Access:** Free, bulk download via the repository URL tree or IPFS.
- **Used in:** [Project 13 — Decoded On-Chain Analytics](projects/13-ethereum-onchain.md), [Project 14 — DeFi Activity Stream Processing](projects/14-ethereum-defi.md)

---

## OpenSky Network

- **URL:** https://opensky-network.org/
- **Data access:** https://opensky-network.org/datasets/
- **Description:** Real-time and historical ADS-B flight tracking data. Every commercial flight worldwide with position updates every second. Includes callsign, origin/destination, altitude, velocity, and coordinates.
- **Size:** Monthly bulk dumps ~10–30 GB. Historical flight tables (~5 GB/month). Live API available for real-time data.
- **Recommended subset:** 1–3 months of flight state vectors or the flights table (~10–20 GB).
- **Format:** CSV (bulk), REST API (live)
- **Access:** Free registration required. Bulk downloads via Zenodo/Impala shell.
- **Used in:** [Project 15 — Flight Density Analytics with Embedded H3](projects/15-opensky-delays.md), [Project 16 — Flight Diversion & Anomaly Detection](projects/16-opensky-realtime.md)

---

## Reddit (Pushshift Archive)

- **URL:** https://academictorrents.com/details/56aa49f9653ba545f48df2e33679f014d2829c10
- **Alternative:** https://the-eye.eu/redarcs/
- **Description:** Full archive of all Reddit comments and submissions since 2005. Includes subreddit, author, score, timestamp, body text, and metadata. Billions of rows across all subreddits.
- **Size:** Full comment archive: ~2 TB compressed. A single month of comments: ~5–15 GB compressed (NDJSON). Individual subreddit dumps are much smaller.
- **Recommended subset:** 1–3 months of all comments (~15–40 GB) or full history of a large subreddit.
- **Format:** Newline-delimited JSON, zstd-compressed
- **Access:** Free download via Academic Torrents or mirror sites.
- **Used in:** [Project 17 — Toxicity Scoring with Embedded ONNX](projects/17-reddit-analytics.md), [Project 18 — Narrative Cross-Pollination Tracker](projects/18-reddit-virality.md)

---

## Spotify Million Playlist Dataset

- **URL:** https://www.aicrowd.com/challenges/spotify-million-playlist-dataset-challenge
- **Description:** 1 million user-created Spotify playlists containing 66 million track entries across 2 million unique tracks. Includes playlist metadata, track names, artists, albums, and playlist ordering.
- **Size:** ~5 GB (JSON)
- **Recommended subset:** Full dataset (manageable size).
- **Format:** JSON (sliced into 1,000-playlist files)
- **Access:** Free download from AICrowd (account required).
- **Used in:** [Project 19 — Playlist Similarity Engine](projects/19-spotify-recommendations.md), [Project 20 — Music Taste Analytics](projects/20-spotify-taste.md)

---

## OpenStreetMap Changesets

- **URL:** https://planet.openstreetmap.org/
- **Changesets:** https://planet.openstreetmap.org/replication/changesets/
- **Description:** The full map of Earth, collaboratively edited. Changeset history records every edit with timestamp, user, bounding box, tags, and comments. The replication feed provides incremental diffs every minute.
- **Size:** Full planet file: ~70 GB compressed (PBF). Changeset metadata: ~5 GB compressed. Daily replication diffs: ~100–500 MB.
- **Recommended subset:** Changeset metadata dump + 1–3 months of replication diffs (~5–10 GB).
- **Format:** XML/PBF (planet), XML/ORC (changesets), OsmChange XML (diffs)
- **Access:** Free download, no authentication.
- **Used in:** [Project 21 — Collaborative Edit CRDT Analysis](projects/21-osm-crdt.md), [Project 22 — Consistency Validator with Prolog](projects/22-osm-quality.md)

---

## Common Crawl

- **URL:** https://commoncrawl.org/
- **Index:** https://index.commoncrawl.org/
- **Description:** Monthly crawl of the entire public web. Each crawl covers 2–3 billion pages. The URL index and metadata are usable for analytics without downloading the full page content.
- **Size:** Full crawl: ~400 TB. URL index: ~250 GB per crawl. Columnar index (Parquet): ~10–20 GB.
- **Recommended subset:** Columnar index for a single crawl (~10–20 GB Parquet) or the URL index filtered to specific domains.
- **Format:** WARC (pages), Parquet/CSV (index)
- **Access:** Free download from S3 (requester-pays) or direct HTTP.
- **Used in:** [Project 23 — Web-Scale Multimodal Search with Lucene](projects/23-commoncrawl-domains.md), [Project 24 — Web Link Graph Incremental Processing](projects/24-commoncrawl-linkgraph.md)

---

## Binance Public Market Data (Live Websocket)

- **URL:** https://www.binance.com/en/binance-api
- **Websocket docs:** https://developers.binance.com/docs/binance-spot-api-docs/web-socket-streams
- **Description:** Real-time public market data for all trading pairs on Binance: individual trades, order book updates (depth), candlestick/kline data, ticker statistics. No authentication required for public streams.
- **Size:** Live stream: ~50K–200K messages/minute depending on market activity. Individual trade stream for BTC/USDT alone: ~5K messages/minute. Recording 24h of top-50 pairs: ~5–10 GB.
- **Recommended approach:** Record 24–72h of multi-pair trade and depth streams for reproducible processing (~5–15 GB).
- **Format:** JSON over websocket (live), NDJSON (recorded)
- **Access:** Public websocket, no API key required for market data streams. `wss://stream.binance.com:9443/ws`
- **Used in:** [Project 25 — Real-Time Portfolio Tracker](projects/25-crypto-portfolio.md), [Project 26 — Order Book Analytics](projects/26-crypto-orderbook.md)

---

## Citi Bike System Data

- **URL:** https://citibikenyc.com/system-data
- **Trip data:** https://s3.amazonaws.com/tripdata/index.html
- **Description:** Every Citi Bike trip in NYC since 2013 (start/end station, time, duration, user type). Real-time station status feed provides live bike/dock availability across ~2,000 stations.
- **Size:** Trip history: ~10 GB total (CSV). Real-time feed: JSON endpoint updated every minute.
- **Recommended subset:** Full trip history + real-time feed for a live component (~10 GB batch + live stream).
- **Format:** CSV (trips), JSON (live feed via GBFS)
- **Access:** Free download, no authentication.
- **Used in:** [Project 27 — Demand Hybrid Pipeline](projects/27-citibike-hybrid.md), [Project 28 — Fleet Rebalancing Stream](projects/28-citibike-rebalancing.md)

---

## NOAA Global Surface Summary of the Day

- **URL:** https://www.ncei.noaa.gov/access/search/
- **Bulk download:** https://www.ncei.noaa.gov/data/global-summary-of-the-day/
- **Description:** Daily weather observations from ~10,000 stations worldwide since 1929. Includes temperature, dew point, pressure, wind speed, visibility, precipitation, and weather phenomena.
- **Size:** ~30 GB total (CSV). ~300 MB/year.
- **Recommended subset:** 10–30 years of global data (~3–10 GB).
- **Format:** CSV (one file per station per year)
- **Access:** Free download, no authentication.
- **Used in:** [Project 29 — Climate Anomaly Detection](projects/29-noaa-anomaly.md), [Project 30 — Global Weather Correlation Pipeline](projects/30-noaa-correlation.md)
