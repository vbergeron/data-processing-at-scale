= Materialized Views & Projections

== Materialized views — incremental pre-aggregation

A ClickHouse materialized view is a *trigger on insert*, not a scheduled refresh. When rows land in the source table, the MV fires, aggregates the new batch, and writes the result to a target table.

#align(center,
  grid(
    columns: (auto, auto, auto, auto, auto),
    column-gutter: 0.5cm,
    align: horizon,
    rect(fill: rgb("#e3f2fd"), inset: 8pt)[INSERT \ new rows],
    [→],
    rect(fill: rgb("#fff3e0"), inset: 8pt)[source table \ `events`],
    [→],
    rect(fill: rgb("#e8f5e9"), inset: 8pt)[MV target \ `events_hourly`],
  )
)

#v(0.8em)

Key constraint: *the MV only sees the inserted batch*, not the full table. This means the aggregate function must be *combinable* across partial results.

- `SUM`, `COUNT`, `MIN`, `MAX` — combinable: `SUM(SUM(x))` = `SUM(x)` over the union
- `AVG`, `MEDIAN` — *not* directly combinable: `AVG(AVG(x)) ≠ AVG(x)` without knowing batch sizes

For non-trivially combinable aggregates, use `AggregatingMergeTree` with state functions.

== AggregatingMergeTree — the correct pattern

`AggregatingMergeTree` stores *intermediate aggregate state* as binary blobs. States from different parts merge correctly during compaction.

```sql
-- Target table: stores intermediate state
CREATE TABLE events_hourly (
  hour     DateTime,
  views    AggregateFunction(count, UInt64),
  revenue  AggregateFunction(sum,   Float64),
  uniq_u   AggregateFunction(uniq,  UInt64)
) ENGINE = AggregatingMergeTree
ORDER BY hour;

-- Materialized view: fires on every insert into `events`
CREATE MATERIALIZED VIEW mv_events_hourly TO events_hourly AS
SELECT
  toStartOfHour(ts)   AS hour,
  countState()        AS views,
  sumState(amount)    AS revenue,
  uniqState(user_id)  AS uniq_u
FROM events;

-- Query: merge states at read time
SELECT hour, countMerge(views), sumMerge(revenue), uniqMerge(uniq_u)
FROM events_hourly
GROUP BY hour
ORDER BY hour;
```

`*State` functions accumulate binary intermediate state. `*Merge` functions combine those states at query time — even across parts that were written at different times.

== Projections — multiple sort orders, one table

A *projection* is an alternative physical layout of a table, stored as hidden parts alongside the main data. ClickHouse automatically selects the best projection per query.

```sql
-- Main table: sorted by (date, user_id) — good for date-range queries
CREATE TABLE events (...) ENGINE = MergeTree ORDER BY (date, user_id);

-- Projection: sorted by (user_id, date) — good for per-user queries
ALTER TABLE events ADD PROJECTION proj_by_user (
  SELECT * ORDER BY (user_id, date)
);
ALTER TABLE events MATERIALIZE PROJECTION proj_by_user;
```

#v(0.5em)

#table(
  columns: (1fr, 1fr),
  [*Materialized views*], [*Projections*],
  [Separate target table; explicit schema], [Hidden; shares the source table definition],
  [Can pre-aggregate; shape can differ from source], [Must be a permutation or subset of source columns],
  [Asynchronous (batch trigger)], [Synchronous — written atomically with the insert],
  [More flexible], [Simpler — no extra DDL for the target],
)
