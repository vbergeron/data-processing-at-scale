# Project 24 — Web Link Graph Incremental Processing

**Extends:** Sessions 4.2 (differential dataflow), 3.3 (CALM, lattices)  
**Dataset:** [Common Crawl](../DATASETS.md#common-crawl)  
**Stack:** Python, DuckDB or PostgreSQL

## Context

The web is a directed graph: pages link to other pages. Common Crawl provides a host-level link graph derived from each crawl. When a new crawl is released monthly, the graph changes — new links appear, old ones disappear. Your job is to maintain graph metrics incrementally across crawl versions.

## Objectives

1. **Load** the Common Crawl host-level link graph for 2 consecutive crawls
2. **Compute** graph metrics as a batch baseline: in-degree distribution, top domains by PageRank, strongly connected components
3. **Compute the diff** between crawls: new links, removed links, changed in-degrees
4. **Update metrics incrementally** using the diff — without reprocessing the entire graph

## Questions You Should Be Able to Answer

- Is in-degree a monotonic computation across crawl versions? What about PageRank?
- How large is the diff between two consecutive crawls compared to the full graph?
- Show a case where your incremental update produces a different result than batch recomputation. Or prove it can't.
- Express your crawl diff as `(edge, +1/-1)` pairs. How do these deltas propagate through your PageRank computation? Which operators amplify the delta set and why?
- What is the computational cost of incremental PageRank vs full recomputation? Where's the crossover point?
