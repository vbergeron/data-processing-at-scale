# Project 29 — Extreme Weather Event Attribution

**Extends:** Sessions 3.4 (ClickHouse), 3.2 (windowed aggregations), 4.1 (probabilistic structures)  
**Dataset:** [NOAA Global Surface Summary](../DATASETS.md#noaa-global-surface-summary-of-the-day)  
**Stack:** ClickHouse, Python

## Context

Are extreme weather events becoming more frequent? Answering this requires defining "extreme" relative to historical baselines, detecting events across station networks, and tracking trends over decades. Your job is to build a system that classifies, counts, and attributes extreme weather events.

## Objectives

1. **Ingest** 30+ years of NOAA GSOD data into ClickHouse
2. **Define** extreme events: per-station, per-season thresholds using historical percentiles (t-digest for approximate quantiles)
3. **Detect** compound events: simultaneous extremes across nearby stations (spatial correlation)
4. **Track** trends: is the frequency of extreme events per region per decade increasing? Apply statistical tests.

## Questions You Should Be Able to Answer

- How do you define "extreme" for a station in the tropics vs one in Scandinavia?
- Show a compound event your system detected. How many stations were affected simultaneously?
- What is the trend in extreme event frequency over the last 30 years? Is it statistically significant?
- How does t-digest compare to exact percentiles for computing your thresholds? Where does the approximation matter most?
