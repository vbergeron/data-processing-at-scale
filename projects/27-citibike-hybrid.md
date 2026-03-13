# Project 27 — Citi Bike Demand Hybrid Pipeline

**Extends:** Sessions 2.2 (Spark), 3.1 (Kafka), 3.4 (ClickHouse)  
**Dataset:** [Citi Bike System Data](../DATASETS.md#citi-bike-system-data)  
**Stack:** PySpark (batch), Kafka + ClickHouse (real-time)

## Context

Citi Bike has both historical trip data (batch) and a live station status feed (streaming). Your job is to build a hybrid pipeline: batch-process the trip history for long-term analytics in Spark, then stream live station data through Kafka into ClickHouse for real-time availability monitoring.

## Objectives

1. **Batch path**: load full trip history into Spark, compute station-level analytics (busiest stations, peak hours, average trip duration, seasonal patterns)
2. **Streaming path**: ingest the live GBFS station status feed into Kafka, sink into ClickHouse with materialized views for bike/dock availability
3. **Join** batch insights with live data: compare current demand against historical baselines
4. **Serve** unified analytics from ClickHouse, combining both batch-computed and real-time data

## Questions You Should Be Able to Answer

- How do you reconcile the batch schema (trip records) with the streaming schema (station status snapshots)?
- Show the Spark execution plan for your busiest-stations query. How does partitioning affect it?
- What ClickHouse `ORDER BY` did you choose for the station status table? How does it handle time-range queries?
- If the live feed goes down for 1 hour, what does your system show? How do you recover?
