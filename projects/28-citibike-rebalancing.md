# Project 28 — Citi Bike Fleet Rebalancing Stream

**Extends:** Sessions 3.1 (Kafka), 3.2 (windowed aggregations), 3.3 (pipeline theory)  
**Dataset:** [Citi Bike System Data](../DATASETS.md#citi-bike-system-data)  
**Stack:** Kafka, Flink, Python

## Context

Bike-sharing systems suffer from imbalance: popular destinations fill up while origin stations empty out. Rebalancing trucks move bikes, but they need real-time signals. Your job is to build a streaming pipeline that detects imbalance events and generates rebalancing alerts.

## Objectives

1. **Replay** historical trip data as a stream into Kafka (simulate bike departures and arrivals)
2. **Maintain** a running station state: bike count per station, updated with each departure/arrival event
3. **Detect** imbalance: flag stations that are >90% full or <10% full within a sliding window
4. **Reason** about correctness: is the station state a CRDT? What happens if departure and arrival events arrive out of order?

## Questions You Should Be Able to Answer

- Is station bike count a monotonic computation? How do you handle decrements (departures)?
- What window type and duration did you use for imbalance detection? Why?
- If a departure event arrives before the corresponding arrival event from the previous trip, what happens to your station count?
- Show a station that oscillates between full and empty. How does your alerting handle flapping?
