# Project 2 — Open Source Bus Factor Analysis

**Extends:** Sessions 2.2 (Spark & query execution), 1.4 (data modeling), 4.2 (incremental computation)  
**Dataset:** [GH Archive](../DATASETS.md#gh-archive)  
**Stack:** PySpark, DuckDB, Parquet

## Context

The "bus factor" of a project is the number of contributors who would need to leave before the project stalls. A bus factor of 1 is a critical risk. Your job is to build the same analytics pipeline in **both PySpark and DuckDB**, compute contributor concentration metrics across thousands of repositories, and find the data size crossover where distributed processing starts winning.

## Objectives

1. **Ingest** 1+ month of GH Archive data, model as a contributor-repository bipartite graph
2. **Compute** bus factor per repository: how many contributors account for 80% of commits? Gini coefficient of commit distribution
3. **Identify** at-risk projects: high-star repositories with bus factor ≤ 2
4. **Implement the same pipeline in DuckDB**: same queries, same output, single-node execution
5. **Benchmark both engines** at 1 month, 3 months, and 6 months of data: wall-clock time, peak memory, shuffle/IO volume. Find the crossover point where Spark's distribution overhead pays off
6. **Optimize** the Spark pipeline for skewed contributor-repo joins (some repos have millions of events)

## Questions You Should Be Able to Answer

- At what data size does Spark start beating DuckDB on your hardware? Why does the crossover happen there?
- Show the execution plan in both engines for the same query. Where do they differ?
- How do you handle the extreme skew in repository sizes? Show what happens without skew handling.
- Name 3 popular projects your system identified as at-risk. Do the results match reality?
- If DuckDB is faster for your dataset size, why would a company still use Spark?
