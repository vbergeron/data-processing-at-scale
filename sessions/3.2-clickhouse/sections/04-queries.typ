= Query Execution

== Vectorized execution

ClickHouse processes data in *column-oriented batches* of one granule (8 192 rows) at a time — never one row at a time.

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *Volcano model (Spark, Postgres)* \
      #v(0.5em)
      Pull one row through the full operator tree. \
      One function call per row per operator. \
      CPU branch-heavy, cache-cold. \
      #v(0.4em)
      _Seen in the Spark session: tuple-at-a-time_
    ],
    [
      *Vectorized (ClickHouse)* \
      #v(0.5em)
      Pull one granule (8 192 rows) at a time. \
      Apply each operator to the full column vector. \
      SIMD-friendly, L1/L2 cache stays warm. \
      #v(0.4em)
      _The column fits in cache — no per-row overhead_
    ],
  )
)

#v(0.8em)

On arithmetic-heavy aggregations, vectorized execution is 10–100× faster than tuple-at-a-time. ClickHouse also generates *runtime-compiled code* (via LLVM) for the hot path of complex expressions.

== Reading EXPLAIN

```sql
EXPLAIN indexes = 1
SELECT sum(amount)
FROM events
WHERE ts >= '2024-01-01' AND ts < '2024-02-01';
```

Key fields to read:
- `ReadFromMergeTree` — which table and how many *selected marks* (granules) will be read
- `Condition (ts ...)` — which parts of the index were applied to prune granules
- `Parts: 42/180` — 42 parts matched out of 180 total

Compare `selected_marks` before and after adding an index or changing `ORDER BY`. This is the primary tool for understanding if your schema is working.

== Observability — system.query_log

Every executed query is logged to `system.query_log` (after a short flush delay). The most useful columns:

```sql
SELECT
  query_duration_ms,
  read_rows,
  read_bytes,
  memory_usage,
  query
FROM system.query_log
WHERE type = 'QueryFinish'
ORDER BY query_duration_ms DESC
LIMIT 10;
```

- `read_rows` vs total rows in the table — how much was skipped
- `read_bytes` — actual I/O after decompression; compare with compressed file sizes
- `memory_usage` — peak memory; watch for aggregations that spill

`system.query_log` is the standard ClickHouse performance profiler. Use it in the demo to show the concrete cost of a wrong `ORDER BY`.

== Approximate aggregation

ClickHouse provides *approximate aggregate functions* as first-class citizens — not approximations of exact functions, but purpose-built algorithms with bounded error guarantees.

#table(
  columns: (auto, auto, 1fr),
  [*Function*], [*Algorithm*], [*Use case*],
  [`uniq()`], [HyperLogLog], [Distinct count — ~2% error, fixed memory],
  [`quantile(p)(x)`], [Reservoir sampling], [Approximate percentiles (p50, p95, p99)],
  [`quantileTDigest(p)(x)`], [t-digest], [More accurate at tails; mergeable across shards],
  [`topK(N)(x)`], [Space-Saving], [Top-N most frequent values in a stream],
)

#v(0.5em)

These mirror the probabilistic data structures covered in Session 4.1 — ClickHouse simply ships them as SQL functions. For billion-row tables, `uniq()` over `COUNT(DISTINCT ...)` is often 10× faster with indistinguishable accuracy for dashboards.
