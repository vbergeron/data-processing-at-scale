# Project 30 — Global Weather Correlation Pipeline

**Extends:** Sessions 2.2 (Spark & query execution), 1.4 (data modeling), 2.1 (file formats)  
**Dataset:** [NOAA Global Surface Summary](../DATASETS.md#noaa-global-surface-summary-of-the-day)  
**Stack:** PySpark, Parquet

## Context

Weather patterns are correlated across regions: a heatwave in one area often coincides with drought in another. Your job is to build a Spark pipeline that computes cross-station correlations over decades of data, identifies teleconnection patterns, and optimizes the computation for scale.

## Objectives

1. **Ingest** NOAA GSOD data into Parquet, partitioned by year, with station metadata as a dimension table
2. **Compute** pairwise temperature correlations between stations within geographic regions and across continents
3. **Identify** teleconnection patterns: station pairs with high correlation despite large geographic distance
4. **Optimize** the pipeline: the naive pairwise approach is O(n²) — use geographic filtering, sampling, or dimensionality reduction to make it tractable

## Questions You Should Be Able to Answer

- How many station pairs exist? Why can't you compute all pairwise correlations?
- Show the Spark execution plan for your correlation computation. Where is the bottleneck?
- What filtering or approximation strategy did you use to reduce the O(n²) problem? What is the accuracy trade-off?
- How does partitioning by year vs by station affect the performance of your temporal correlation queries?
