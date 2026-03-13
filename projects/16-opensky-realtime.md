# Project 16 — Flight Diversion & Anomaly Detection

**Extends:** Sessions 3.1 (Flink), 3.2 (windowed aggregations), 3.4 (ClickHouse)  
**Dataset:** [OpenSky Network](../DATASETS.md#opensky-network)  
**Stack:** Kafka, Flink, ClickHouse

## Context

Most flights follow predictable routes. Diversions, circling patterns, and emergency descents are anomalies that stand out in positional data. Your job is to build a Flink streaming pipeline that detects flight anomalies from ADS-B position updates and stores them in ClickHouse for investigation.

## Objectives

1. **Stream** OpenSky state vectors into Kafka (replay historical data or use the live API)
2. **Track** per-flight state in Flink: current position, heading, altitude, speed
3. **Detect anomalies**: circling (repeated heading changes), rapid descent (altitude drop rate), ground stops at non-airport locations, U-turns (180° heading reversal)
4. **Sink** detected anomalies with context (flight history leading to the event) into ClickHouse
5. **Classify** anomaly types and compute frequency per airport/route

## Questions You Should Be Able to Answer

- How do you define "circling" algorithmically? What heading change threshold did you use?
- Show a real diversion your system detected. What was the flight history before the anomaly?
- What is the state size per tracked flight? How do you evict flights that have landed?
- If ADS-B position updates arrive out of order (different ground stations), how does your pipeline handle it?
