# Project 26 — Real-Time Order Book Reconstruction & Arbitrage Detection

**Extends:** Sessions 3.1 (Flink), 3.2 (stateful processing, checkpointing), 4.1 (probabilistic structures)  
**Dataset:** [Binance Public Market Data](../DATASETS.md#binance-public-market-data-live-websocket)  
**Stack:** Kafka, Flink, ClickHouse, Python

## Context

An order book is a live, mutable data structure: bids and asks arrive, update, and cancel at thousands of messages per second. Reconstructing and maintaining it from a stream of depth updates is a stateful processing challenge. Detecting arbitrage opportunities across trading pairs adds a cross-stream coordination problem. Your job is to build this as a Flink pipeline with ClickHouse for historical analytics.

## Objectives

1. **Ingest** Binance depth update streams for 5+ trading pairs into Kafka
2. **Reconstruct** the live order book in Flink keyed state: maintain sorted bid/ask sides, apply incremental depth updates, detect and handle out-of-sequence updates
3. **Compute** real-time metrics: bid-ask spread, order book depth at each price level, imbalance ratio (bid volume vs ask volume)
4. **Detect** cross-pair arbitrage: triangular arbitrage opportunities (e.g., BTC→ETH→USDT→BTC) by joining multiple order book states
5. **Sink** order book snapshots and detected opportunities into ClickHouse for post-hoc analysis

## Questions You Should Be Able to Answer

- How do you handle a depth update that arrives out of sequence? What is your reconciliation strategy?
- What is the state size of maintaining 5 live order books in Flink? How does it grow over time?
- Show a triangular arbitrage opportunity your system detected. Was it real or already closed by the time you detected it?
- How do you join state across multiple keyed streams (different trading pairs) in Flink? What operator do you use?
- If a Flink checkpoint takes 5 seconds, how many order book updates are in-flight? What happens to them on recovery?
