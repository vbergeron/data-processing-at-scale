#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 2.2 — Reading and Optimizing Spark Query Plans],
  session: [Session 2.2 — Apache Spark & Query Execution Internals],
  format: [Instructor-led hands-on demo],
  tools: [PySpark (local mode), Spark UI],
)

= Objective

Teach students to read Spark query plans and understand what the engine actually does. Show how the Catalyst optimizer transforms logical plans into physical execution, and how small changes in code produce radically different plans.

= Setup

- PySpark in local mode (no cluster needed)
- Dataset: Parquet files from Demo 2.1 (~10M rows), plus a small dimension table
- Spark UI accessible at `localhost:4040`

= Walkthrough

== Step 1 — Logical vs physical plan

Write a simple aggregation query using the DataFrame API:
- `df.filter(...).groupBy(...).agg(...)`
- Show `explain(True)` output: parsed → analyzed → optimized → physical
- Walk through each stage — what did the optimizer change?

== Step 2 — Predicate pushdown

Filter on a Parquet column:
- Show the physical plan: `PushedFilters` in the scan node
- Compare with a filter that _can't_ be pushed down (e.g., UDF-based)
- Check Spark UI metrics: rows read vs rows output

== Step 3 — Join strategies

Join the large table with a small dimension table:
- Default: Spark chooses broadcast hash join (small table fits in memory)
- Force a sort-merge join via config — show the shuffle stages appear
- Force a shuffle hash join — compare
- Show each plan side by side in `explain()`
- Spark UI: compare shuffle bytes, task count, stage duration

== Step 4 — The shuffle

Write a repartition + aggregation that triggers a full shuffle:
- Show the exchange node in the plan
- Spark UI: observe shuffle write/read bytes
- Demonstrate partition skew: one partition has 10x the data
- Fix with salting or `repartition()` — show the plan change

== Step 5 — Whole-stage code generation

Show `WholeStageCodegen` in the plan:
- Compare a query with codegen enabled vs disabled (`spark.sql.codegen.wholeStage=false`)
- Observe the performance difference
- Explain: Spark compiles the entire stage into a single Java method — no virtual dispatch between operators

== Step 6 — Catalyst pitfalls

Show cases where the optimizer makes poor choices:
- Stale or missing statistics → wrong join strategy
- Overly complex expressions that prevent pushdown
- When `cache()` helps vs when it hurts

= Key Takeaways

- Always read the plan before optimizing — intuition about SQL performance often misleads
- Predicate pushdown and join strategy selection are the two highest-impact optimizations
- Shuffles dominate execution time — minimizing them is the primary tuning lever
- Whole-stage codegen is what makes Spark competitive with compiled engines
- The optimizer is powerful but not omniscient — understanding its limits matters
