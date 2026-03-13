# Project 11 — Stock Market Time-Series Analytics

**Extends:** Sessions 3.4 (ClickHouse), 4.1 (probabilistic data structures)  
**Dataset:** [US Stock Market](../DATASETS.md#kaggle-finance--us-stock-market-daily--intraday)  
**Stack:** ClickHouse, Python

## Context

Stock market data is inherently time-series: prices, volumes, and indicators evolve tick by tick. Your job is to load historical OHLCV data into ClickHouse and build a **materialized view cascade** — a chain of views that pre-aggregate at increasing granularities — then measure the trade-off between write amplification and query speed.

## Objectives

1. **Model** OHLCV data in ClickHouse with a time-series-optimized schema (`ORDER BY (symbol, date)`)
2. **Compute** rolling analytics: 20/50/200-day moving averages, Bollinger bands, volume anomalies
3. **Build a materialized view chain** (at least 3 levels):
   - Level 1: per-symbol daily aggregates (raw → daily OHLCV with moving averages)
   - Level 2: per-sector weekly rollups (daily → weekly sector performance)
   - Level 3: market-wide monthly summary (weekly → monthly market indicators)
4. **Measure write amplification**: insert 1 month of raw data, measure total bytes written across all MV levels. Compare against querying raw data directly
5. **Cross-market queries**: find correlated stock pairs, sector rotation patterns — compare query speed on raw table vs materialized views
6. **Compare** ClickHouse `arrayReduce` / array functions vs window functions for batch rolling computations

## Questions You Should Be Able to Answer

- What is the write amplification factor of your MV chain? (total MV bytes / raw data bytes)
- At what query frequency does pre-aggregation via MVs pay for itself vs querying raw data?
- Show a query that is 10x+ faster on the MV chain vs the raw table. Show one where the difference is negligible.
- Why is `ORDER BY (symbol, date)` better than `ORDER BY (date, symbol)` for your queries?
- What happens to MV consistency if an insert fails midway? Does ClickHouse guarantee atomicity across the chain?
