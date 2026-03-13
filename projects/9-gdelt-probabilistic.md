# Project 9 — Global News Event Tracking with Probabilistic Structures

**Extends:** Sessions 4.1 (probabilistic data structures), 3.4 (ClickHouse), 2.1 (storage formats)  
**Dataset:** [GDELT Project](../DATASETS.md#gdelt-project)  
**Stack:** Python, ClickHouse, (optionally Kafka for ingestion)

## Context

The GDELT Project monitors news media worldwide and records structured events: who did what to whom, where, and when. With hundreds of millions of events, exact analytics become expensive. Your job is to build a system that uses probabilistic data structures to answer approximate queries efficiently, and compare accuracy/performance against exact computation.

## Objectives

1. **Ingest** 1–3 months of GDELT 2.0 event data into ClickHouse
2. **Implement exact analytics** as a baseline: unique actors per country per day, most frequent event types, geographic distribution of conflict events
3. **Implement probabilistic alternatives**: HyperLogLog for distinct counts, Count-Min Sketch for frequency estimation, quantile sketches for tone/sentiment distribution
4. **Compare** exact vs approximate: measure accuracy (relative error), memory usage, and query speed

## Expected Deliverables

- A ClickHouse table with at least 1 month of GDELT data loaded (~15 GB)
- 3 analytical queries implemented both exactly and with probabilistic structures
- A systematic comparison: accuracy, memory, and latency for each approach
- A presentation explaining how each probabilistic structure works internally and when the approximation is acceptable

## Questions You Should Be Able to Answer

- What is the relative error of your HyperLogLog estimate vs the exact count? How does it change with the sketch size?
- In what scenario would you *not* use a Bloom filter? When is a false positive unacceptable?
- How does Count-Min Sketch handle hash collisions? What happens to accuracy as the stream grows?
- ClickHouse has built-in `uniq()` (HyperLogLog) and `quantile()` (t-digest). How do they compare to your implementation?
- If you needed <1% error on distinct counts, how large would your sketch need to be?
