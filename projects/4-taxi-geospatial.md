# Project 4 — NYC Taxi Fare Anomaly Detection

**Extends:** Sessions 3.4 (ClickHouse), 4.1 (probabilistic structures), 1.4 (data modeling)  
**Dataset:** [NYC TLC Trip Record Data](../DATASETS.md#nyc-tlc-trip-record-data)  
**Stack:** ClickHouse, Python

## Context

Taxi fare fraud takes many forms: phantom rides, detour inflation, meter tampering. Your job is to build an analytics system in ClickHouse that establishes baseline fare profiles per route and flags statistical outliers. The twist: baselines are **non-stationary** — fare patterns shift with seasons, COVID lockdowns, fuel prices, and policy changes. Your system must detect when the baseline itself has drifted and adapt.

## Objectives

1. **Model** trip data in ClickHouse with an `ORDER BY` optimized for zone-pair lookups
2. **Compute** baseline profiles per route: median fare, median duration, fare-per-minute distribution (using t-digest)
3. **Detect anomalies**: trips deviating >3σ from the route baseline, trips with impossible speed (distance/duration), zero-fare trips with long durations
4. **Classify** anomaly types: likely detour, likely meter tampering, likely data error, likely surge pricing
5. **Detect baseline drift**: compare monthly baselines for the same route. Flag routes where the median fare shifted >20% between periods. Distinguish true drift (COVID, policy change) from seasonal variation
6. **Adaptive baselines**: implement rolling baselines (trailing 3-month window) vs fixed baselines (all-time). Compare false positive rates — does the rolling baseline reduce false alarms during known disruptions?

## Questions You Should Be Able to Answer

- Show a route where the fixed baseline produces false positives that the rolling baseline avoids. What caused the drift?
- How does COVID appear in your baseline data? Which routes were most affected?
- What is the distribution of anomaly types? Which is most common?
- Show a specific anomalous trip. Why did your system flag it?
- How does t-digest compare to exact percentiles for route fare distributions? At what sample size does the error become negligible?
