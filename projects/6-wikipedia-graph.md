# Project 6 — Wikipedia Knowledge Graph Evolution

**Extends:** Sessions 4.2 (differential dataflow), 3.3 (CALM, lattices)  
**Dataset:** [Wikimedia EventStreams](../DATASETS.md#wikimedia-eventstreams)  
**Stack:** Python, PostgreSQL or DuckDB

## Context

Wikipedia pages link to each other, forming a knowledge graph that evolves with every edit. When a link is added or removed, the graph structure changes. Your job is to build an incremental system that maintains graph metrics (PageRank, connected components, link density) as edits arrive, without recomputing from scratch.

## Objectives

1. **Extract** the link graph from Wikipedia edit events (parse wikitext diffs to detect added/removed links)
2. **Compute** graph metrics as a baseline batch job: in-degree distribution, top pages by PageRank, category clustering
3. **Make it incremental**: when a new edit adds or removes links, update the metrics differentially
4. **Reason about monotonicity**: which metrics are monotonic (can be updated as a lattice) and which require coordination?

## Questions You Should Be Able to Answer

- Is in-degree count a monotonic computation if links can be removed?
- How does your incremental PageRank update compare in cost to a full recomputation?
- Show an edit that changes the graph structure. Walk through how your system processes it.
- What happens if two edits to the same page arrive out of order?
