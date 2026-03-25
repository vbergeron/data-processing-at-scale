= Materialized Views & Projections

== Materialized views — incremental pre-aggregation

A ClickHouse materialized view is a *trigger on insert*, not a scheduled refresh. When rows land in the source table, the MV fires, aggregates the new batch, and writes the result to a target table.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#align(center,
  diagram(
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    spacing: (1.6cm, 1cm),
    node((0,0), [`INSERT`], fill: rgb("#e3f2fd"), shape: rect),
    edge((0,0), (1,0), "->"),
    node((1,0), [source table \ `events`], fill: rgb("#fff3e0"), shape: rect),
    edge((1,0), (2,0), "->"),
    node((2,0), [Materialized View \ `mv_events_hourly`], fill: rgb("#fce4ec"), shape: rect),
    edge((2,0), (3,0), "->"),
    node((3,0), [target table \ `events_hourly`], fill: rgb("#e8f5e9"), shape: rect),
  )
)

== Materialized views and aggregation

Key constraint: *the MV only sees the inserted batch*, not the full table. This means the aggregate function must be *combinable* across partial results.

- `SUM`, `COUNT`, `MIN`, `MAX` — combinable: `SUM(SUM(x))` = `SUM(x)` over the union
- `AVG`, `MEDIAN` — *not* directly combinable: `AVG(AVG(x)) ≠ AVG(x)` without knowing batch sizes


== Materialized views and AggregatingMergeTree 

For non-trivially combinable aggregates, use `AggregatingMergeTree` with `*State` functions.

`AggregatingMergeTree` stores *intermediate aggregate state* as binary blobs. States from different parts merge correctly during compaction.

== Materialized views and AggregatingMergeTree 

```sql
-- Target table: stores intermediate state
CREATE TABLE events_hourly (
  hour     DateTime,
  views    AggregateFunction(count, UInt64),
  revenue  AggregateFunction(sum,   Float64),
  uniq_u   AggregateFunction(uniq,  UInt64)
) ENGINE = AggregatingMergeTree
ORDER BY hour;

```

== Materialized views and AggregatingMergeTree 

```sql
-- Materialized view: fires on every insert into `events`
CREATE MATERIALIZED VIEW mv_events_hourly TO events_hourly AS
SELECT
  toStartOfHour(ts)   AS hour,
  countState()        AS views,
  sumState(amount)    AS revenue,
  uniqState(user_id)  AS uniq_u
FROM events;
```

== Materialized views and AggregatingMergeTree 

```sql
-- Query: merge states at read time
SELECT hour, countMerge(views), sumMerge(revenue), uniqMerge(uniq_u)
FROM events_hourly
GROUP BY hour
ORDER BY hour;
```

`*State` functions accumulate binary intermediate state. `*Merge` functions combine those states at query time — even across parts that were written at different times.

== Projections — multiple sort orders, one table

A *projection* is an alternative physical layout of a table, stored as hidden parts alongside the main data. 

== Projections — multiple sort orders, one table

```sql
-- Main table: sorted by (date, user_id) — good for date-range queries
CREATE TABLE events (...) ENGINE = MergeTree ORDER BY (date, user_id);

-- Projection: sorted by (user_id, date) — good for per-user queries
ALTER TABLE events ADD PROJECTION proj_by_user (
  SELECT * ORDER BY (user_id, date)
);

-- Catchup: materialize the projection
ALTER TABLE events MATERIALIZE PROJECTION proj_by_user;
```

== Projections — pre-aggregation

Projections can also include a `GROUP BY` clause, turning them into an embedded pre-aggregation layer — no separate target table needed.

```sql
ALTER TABLE events ADD PROJECTION proj_daily_revenue (
  SELECT
    toStartOfDay(ts) AS day,
    user_id,
    sum(amount)      AS total_amount,
    count()          AS num_events
  GROUP BY day, user_id
);
ALTER TABLE events MATERIALIZE PROJECTION proj_daily_revenue;
```

== Projections — multiple sort orders, one table

ClickHouse automatically rewrites matching queries to read from the projection instead of scanning the raw data. The projection is updated synchronously on every insert — no trigger logic to manage.

```sql
-- This query hits the projection, not the raw table
SELECT day, sum(total_amount) FROM events GROUP BY day;
```

== Projections — multiple sort orders, one table

#table(
  columns: (auto, 1fr, 1fr),
  [], [*Materialized views*], [*Projections*],
  [Storage], [Separate, explicit], [Hidden table],
  [Schema], [Arbitrary], [Reordering or subset],
  [Update], [Triggered on insert], [Synchronous],
  [Query routing], [Explicit query against the target table], [Implictly optimized],
  [TTL], [Independent], [Inherits],
  [JOINs in definition], [Supported], [Not supported],
  [WHERE in definition], [Supported], [Not supported],
  [Chaining], [Supported], [Not supported],
  [LW Deletes], [Supported], [Not supported],
)
