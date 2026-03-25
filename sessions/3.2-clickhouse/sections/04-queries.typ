= Query Execution

== Vectorized execution

ClickHouse processes data in *column-oriented batches* of one granule (8 192 rows) at a time.

#v(0.5em)

- Pull one granule (8 192 rows) at a time.
- Apply each operator to the full column vector.
- SIMD-friendly, L1/L2 cache stays warm.
- The column fits in cache — no per-row overhead

#v(0.5em)

On arithmetic-heavy aggregations, vectorized execution is 10–100× faster than tuple-at-a-time. \
ClickHouse also generates *runtime-compiled code* (via LLVM) for the hot path of complex expressions.

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

