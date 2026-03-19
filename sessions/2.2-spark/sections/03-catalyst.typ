#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= The Catalyst Optimizer

== \

#hero[The optimizer is why \ Spark SQL is faster \ than hand-written RDDs.]

== What Catalyst is

Catalyst is Spark's query optimizer. It takes a *logical plan* (what you asked for) and produces a *physical plan* (how to execute it).

It is implemented in Scala using *algebraic trees* and *pattern-matching rules*. Each optimization pass is a function `Tree → Tree`. New rules can be added by plugins.

Catalyst runs entirely on the driver, before any data moves.

== The four-phase pipeline

#align(center,
  fletcher.diagram(
    spacing: (1cm, 0pt),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), [SQL], width: 4cm, inset: 9pt),
    node((1, 0), [*Analysis*],             width: 3.8cm, inset: 9pt),
    node((2, 0), [*Optimizer*],   width: 3.8cm, inset: 9pt),
    node((3, 0), [*Planner*],    width: 3.8cm, inset: 9pt),
    node((4, 0), [*Codegen*],     width: 3.8cm, inset: 9pt),
    node((5, 0), [JVM],          width: 3.8cm, inset: 9pt),
    edge((0,0),(1,0), "->"),
    edge((1,0),(2,0), "->"),
    edge((2,0),(3,0), "->"),
    edge((3,0),(4,0), "->"),
    edge((4,0),(5,0), "->"),
  )
)

- *Analysis*: resolve column names and types; catch schema errors before execution
- *Logical optimizer*: rule-based rewrites — predicate pushdown, constant folding, subquery elimination
- *Physical planner*: select operators and join strategies; cost-based when statistics are available
- *Code generation*: emit a single JVM class per pipeline stage (Tungsten)

== Logical plan

The logical plan is a tree of *relational algebra* operators:

- `Filter(condition, child)`
- `Project(expressions, child)`
- `Join(left, right, condition, joinType)`
- `Aggregate(groupingKeys, aggregates, child)`
- `Scan(relation, filters, projections)`

The logical plan is *schema-aware* but *implementation-agnostic*. It does not know whether data is in Parquet or CSV, or how many partitions it has.

== Logical optimization rules

*Predicate pushdown*: move `Filter` nodes as close to the `Scan` as possible.

Before: `Filter(age > 30, Join(users, orders, ...))`
After: `Join(Filter(age > 30, users), orders, ...)`

Less data enters the join — this is typically the single biggest win.

*Projection pruning*: drop columns that are never referenced downstream. Avoids deserializing unused bytes from Parquet row groups.

*Constant folding*: evaluate `2 + 3` at plan time, not at row evaluation time.

*Boolean simplification*: `x AND TRUE → x`, `x OR FALSE → x`.

== Physical planning — join strategies

For each logical `Join`, Catalyst must choose a physical strategy:

*Broadcast hash join (BHJ)*: broadcast the smaller table to all executors, build a hash table in memory, probe with every row of the larger table. No shuffle. Requires the smaller side to fit in memory (`spark.sql.autoBroadcastJoinThreshold`, default 10 MB).

*Sort-merge join (SMJ)*: shuffle both sides so matching keys land on the same partition, sort both sides, then merge. Scales to any data size. Requires two shuffles if inputs are not already sorted.

*Shuffle hash join (SHJ)*: shuffle both sides like SMJ, but build a hash table instead of sorting. Works when one side fits in partition memory.

== Physical planning — cost-based optimization

When statistics are available (via `ANALYZE TABLE` or collected during planning), Catalyst uses *cost-based optimization* (CBO) to:

- Estimate the size of each intermediate result
- Choose the probe side vs build side of a hash join
- Decide whether to broadcast based on estimated size (not just table-level stats)
- Reorder joins in a sequence to minimize intermediate data

CBO requires column-level statistics. Without them, Catalyst falls back to heuristics — which is why `ANALYZE TABLE` matters on large datasets.

== Reading a query plan

`df.explain(mode = "formatted")` shows:

```
*(3) HashAggregate(keys=[region], functions=[sum(revenue)])
+- Exchange hashpartitioning(region, 200)         // shuffle boundary
   +- *(2) HashAggregate(...)                     // partial agg, same stage
      +- *(2) Filter (price > 0)
         +- FileScan parquet [region,price,qty]
            PushedFilters: [GreaterThan(price,0)] // sent to Parquet reader
```

Key things to identify:
- `*()` around an operator → inside a Whole-Stage CodeGen stage
- `Exchange` → shuffle boundary between stages
- `PushedFilters` → filters sent to the Parquet reader (skip row groups)
- `BroadcastExchange` → broadcast join, no shuffle for the smaller side

== Reading a query plan — join identification

```
*(5) SortMergeJoin [user_id], [user_id], Inner
:- *(2) Sort [user_id ASC]
:  +- Exchange hashpartitioning(user_id, 200)
:     +- *(1) FileScan parquet orders
+- *(4) Sort [user_id ASC]
   +- Exchange hashpartitioning(user_id, 200)
      +- *(3) FileScan parquet users
```

Two `Exchange` nodes → two shuffles. Both sides are being repartitioned on `user_id` so matching keys co-locate. If `users` were small enough, Catalyst would replace this with a `BroadcastHashJoin` and eliminate both shuffles.
