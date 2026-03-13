# Project 12 — Financial Statement Pipeline

**Extends:** Sessions 2.2 (Spark & query execution), 1.4 (data modeling), 2.1 (file formats)  
**Dataset:** [US Stock Market + SEC EDGAR](../DATASETS.md#kaggle-finance--us-stock-market-daily--intraday)  
**Stack:** PySpark, Parquet

## Context

Investors combine market data (prices, volumes) with fundamental data (revenue, earnings, assets) from SEC filings. These datasets have very different shapes and granularities. Your job is to build a Spark pipeline that joins them, computes valuation metrics, and optimizes the execution for large-scale analysis.

## Objectives

1. **Ingest** OHLCV price data and SEC EDGAR quarterly filings, normalize into a common schema
2. **Join** market and fundamental data: compute P/E ratios, price-to-book, dividend yield at each filing date
3. **Analyze** at least 3 questions: undervalued sectors, earnings surprise impact on price, revenue growth vs stock performance
4. **Optimize** the join: different granularities (daily prices vs quarterly filings) require an as-of join — compare approaches

## Questions You Should Be Able to Answer

- How do you handle the temporal join between daily prices and quarterly filings? What join strategy did Spark use?
- Show the execution plan for your most expensive query. Where are the shuffles?
- What file format and partitioning scheme did you choose for the joined dataset? Why?
- If SEC filings arrive late or are amended, how does your pipeline handle corrections?
