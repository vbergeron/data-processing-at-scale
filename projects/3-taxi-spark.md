# Project 3 — NYC Urban Pulse: Event Detection from Taxi Flow

**Extends:** Sessions 2.2 (Spark & query execution), 2.1 (file formats), 1.4 (data modeling)  
**Dataset:** [NYC TLC Trip Record Data](../DATASETS.md#nyc-tlc-trip-record-data)  
**Stack:** PySpark, Parquet

## Context

Every taxi trip is a data point about how the city moves. 200M+ trips per year encode rush hour tides, event surges, weather shutdowns, and transit disruptions — but you have to extract the signal. Your job is to build a Spark pipeline that models the city's **normal rhythm** as a spatiotemporal baseline, then detects **perturbations** — moments where taxi flow deviates sharply from the expected pattern — and attributes them to real-world events.

## Objectives

1. **Build the city's heartbeat**: aggregate pickups and dropoffs per taxi zone per 30-minute window. Compute baseline profiles per zone per day-of-week per time-slot (e.g., "Penn Station, Tuesday 5:30pm" has a normal range)
2. **Detect perturbations**: flag zone-windows where pickup or dropoff count deviates >3σ from the baseline. Classify as surge (unusually high) or drought (unusually low)
3. **Cluster perturbations** spatially and temporally: a single event (e.g., a concert at MSG) shows as simultaneous surges across adjacent zones — group them into a single detected event
4. **Attribute events**: cross-reference detected perturbations with known events (NYE, marathons, snowstorms, Yankee games, transit strikes). How many real events does your system find? Build a timeline
5. **Discover unknown events**: identify perturbations that don't match any event you know about. Investigate — what actually happened?
6. **Optimize** the pipeline: the baseline computation requires a full pass over the data, the detection is a second pass. Show execution plans, caching strategy, and partition design

## Questions You Should Be Able to Answer

- Show 3 events your system detected correctly. What did the perturbation look like in the data?
- Show 1 perturbation you couldn't explain. What could it be?
- How do you distinguish a concert ending (localized spike) from a snowstorm (city-wide drought)?
- What zone has the most volatile baseline? Why?
- How does your partition strategy (by date? by zone?) affect the baseline computation performance?
