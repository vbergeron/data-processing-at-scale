# Project 7 — Stack Overflow Incremental Analytics

**Extends:** Sessions 4.2 (differential dataflow), 3.3 (CALM theorem, lattices), 1.4 (data modeling)  
**Dataset:** [Stack Exchange Data Dump](../DATASETS.md#stack-exchange-data-dump)  
**Stack:** Python, PostgreSQL or DuckDB, (optionally Materialize or a custom incremental engine)

## Context

Stack Overflow has 20+ million questions, 30+ million answers, and hundreds of millions of votes accumulated over 15+ years. Computing analytics (top answerers, trending tags, answer quality scores) from scratch is expensive. Your job is to build an incremental pipeline that maintains these analytics as new data arrives, without recomputing from scratch.

## Objectives

1. **Model** the Stack Overflow data (Posts, Votes, Users, Tags) as a star schema or denormalized model
2. **Compute** at least 3 analytics: e.g., top answerers per tag (by score), tag popularity over time, average time-to-accepted-answer per tag
3. **Make it incremental**: when new posts/votes arrive, update the analytics without scanning the full dataset
4. **Reason about correctness**: prove (or argue) that your incremental computation produces the same result as a full recomputation

## Expected Deliverables

- A data model with clear design justification
- A batch computation of the 3 analytics as a baseline
- An incremental update mechanism that processes a delta (e.g., 1 day of new posts/votes) and updates the results
- A correctness comparison: incremental result vs full recomputation
- A presentation connecting your approach to CALM/lattice theory from the course

## Questions You Should Be Able to Answer

- Is your aggregation monotonic? Can it be expressed as a lattice merge?
- What happens if a vote is retracted (a non-monotonic event)? How do you handle it incrementally?
- Show a case where incremental and batch results diverge — or prove they can't
- How much faster is the incremental update vs full recomputation? Where does the speedup come from?
- Model your pipeline as a chain of differential dataflow operators: what are the `(record, diff)` pairs at each stage? Where do deltas amplify and where do they contract?
- If you had to make this distributed across 3 nodes, what would need coordination and what wouldn't?
