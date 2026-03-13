#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 1.4 — Designing a Star Schema and Comparing Join Strategies in PostgreSQL],
  session: [Session 1.4 — Data Modeling at Scale],
  format: [Instructor-led hands-on demo],
  tools: [PostgreSQL, `EXPLAIN ANALYZE`],
)

= Objective

Contrast normalized and denormalized modeling approaches using PostgreSQL. Show how join strategies change with data volume and why denormalization becomes necessary at scale.

= Setup

- PostgreSQL instance with a retail dataset:
  - Normalized: `orders`, `order_items`, `products`, `customers`, `stores` (5 tables, 3NF)
  - Denormalized: `sales_facts` + dimension tables (star schema)
  - Fully flat: single wide `sales_flat` table
- Dataset sizes: 1M, 10M, 50M order items
- `EXPLAIN ANALYZE` for all queries

= Walkthrough

== Step 1 — The normalized model

Run an analytical query (revenue per product category per region per month):
- Show the 4-table join required
- `EXPLAIN ANALYZE`: observe nested loop vs hash join selection
- Note the query plan complexity and execution time

== Step 2 — The star schema

Same query on the star schema:
- Fact table + 2 dimension lookups
- `EXPLAIN ANALYZE`: simpler plan, fewer joins
- Compare execution times — marginal improvement at small scale

== Step 3 — Scale to 50M rows

Re-run both queries at 50M rows:
- Normalized model: join explosion, temp files on disk, minutes of execution
- Star schema: still manageable — fact table scan + small dimension hash joins
- Flat table: fastest scan, but show the storage cost and update anomalies

== Step 4 — Pre-aggregation

Create a materialized view for monthly aggregates:
- Query drops from seconds to milliseconds
- Discuss the trade-off: freshness vs speed
- When to use materialized views vs on-the-fly aggregation

= Key Takeaways

- Normalization optimizes for writes and consistency; denormalization optimizes for read performance
- At scale, joins become the dominant cost — star schemas minimize them
- Pre-aggregation (materialized views) trades storage and freshness for query speed
- There is no universal "best" model — it depends on the access patterns
