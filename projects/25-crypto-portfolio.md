# Project 25 — Real-Time Cryptocurrency Portfolio Tracker

**Extends:** Sessions 3.1 (Flink), 3.2 (stateful processing, checkpointing), 3.3 (pipeline theory)  
**Dataset:** [Binance Public Market Data](../DATASETS.md#binance-public-market-data-live-websocket)  
**Stack:** Kafka, Flink, PostgreSQL (OLTP state), Python

## Context

A portfolio tracker must maintain consistent balances as trades stream in: no double-counting, no missed trades, correct P&L at all times. This is an OLTP problem — transactional correctness matters — embedded in a high-throughput streaming pipeline. Your job is to build a Flink pipeline that ingests live market data, processes simulated portfolio trades, and maintains a consistent portfolio state.

## Objectives

1. **Ingest** live Binance trade streams for 10+ trading pairs into Kafka
2. **Simulate** a portfolio: generate buy/sell orders against the live price feed (rule-based: buy on dip, sell on spike)
3. **Maintain** portfolio state in Flink keyed state: per-asset holdings, average entry price, realized/unrealized P&L — updated transactionally with each trade
4. **Sink** portfolio snapshots to PostgreSQL with exactly-once guarantees (Flink 2PC sink)
5. **Handle** failure: kill Flink mid-trade, restart from checkpoint, verify portfolio state is consistent (no duplicate trades, no missing trades)

## Questions You Should Be Able to Answer

- How does Flink's checkpointing guarantee that portfolio state is exactly-once? Walk through a failure scenario.
- What keyed state do you maintain per asset? How large is the state after 24h?
- How does the 2-phase commit sink to PostgreSQL work? What happens if PostgreSQL is temporarily unavailable?
- Show a checkpoint/restart cycle. Prove that the portfolio balance before and after restart is consistent.
- How would you add a second portfolio (different trading strategy) without duplicating the Kafka ingestion?
