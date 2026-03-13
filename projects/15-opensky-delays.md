# Project 15 — Flight Density Analytics with Embedded H3 in Spark

**Extends:** Sessions 2.2 (Spark & query execution internals), 1.4 (data modeling), 2.1 (storage formats)  
**Dataset:** [OpenSky Network](../DATASETS.md#opensky-network)  
**Stack:** Scala, Spark, H3 (Uber's hexagonal grid library)

## What is H3?

H3 is Uber's open-source hierarchical hexagonal grid system. It divides the Earth's surface into hexagonal cells at 16 resolution levels (from ~4M km² down to ~0.9 m²). Each cell has a unique 64-bit index. Key properties: hexagons have uniform adjacency (6 neighbors, unlike square grids), minimal area distortion, and hierarchical nesting (a parent hex contains exactly 7 children). The `h3-java` library provides JVM-native bindings — you call `latLngToCell(lat, lng, resolution)` and get back a cell index you can use as a join/group key.

## Context

Flight tracking data is inherently geospatial: every ADS-B position update has a latitude, longitude, and altitude. Analyzing airspace density, traffic corridors, and geographic patterns requires spatial indexing — but lat/lng coordinates don't aggregate cleanly. By embedding H3 inside Spark, you convert raw coordinates into hierarchical hex cells and unlock fast spatial joins, multi-resolution aggregation, and neighbor queries. Your job is to build this pipeline.

## Objectives

1. **Convert** all ADS-B position reports to H3 cell indexes at multiple resolutions (res 4 for continental, res 7 for regional, res 9 for airport-level) inside `mapPartitions`
2. **Aggregate** flight density per hex cell per hour: aircraft count, unique flights, average altitude
3. **Multi-resolution drill-down**: start at res 4 (continental), zoom to res 7 (regional), zoom to res 9 (airport) — show how parent-child hex relationships enable this
4. **Spatial joins**: find hex cells adjacent to airports, compute arrival/departure corridors as hex chains
5. **Compare** H3 aggregation against naive lat/lng rounding and geohash-based approaches: accuracy, performance, visual quality

## Questions You Should Be Able to Answer

- Why hexagons instead of squares? What artifact does a square grid create for distance-based queries?
- How does H3's hierarchical structure enable efficient multi-resolution queries? Show the parent-child relationship.
- What resolution did you choose for airport-level analysis? What is the physical size of those cells?
- How does partitioning Spark data by H3 cell at res 3 affect shuffle size for regional queries?
- Show a flight corridor visualized as a hex chain. How did you compute it?
