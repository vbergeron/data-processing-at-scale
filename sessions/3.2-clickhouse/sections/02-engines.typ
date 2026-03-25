= The MergeTree Engine Family

== MergeTree

ClickHouse's primary storage engine. The name is literal: data is written in sorted, immutable *parts*, and a background process continuously *merges* them.

Every engine in the family — `ReplacingMergeTree`, `AggregatingMergeTree`, `CollapsingMergeTree` — is `MergeTree` with a specific behavior plugged into the merge step.

#v(0.6em)

*Relationship to LSM trees*

MergeTree shares the core idea with Log-Structured Merge trees (used in RocksDB, Cassandra, LevelDB): writes are cheap because they are sequential appends, and reads amortize the cost of background compaction. The key difference is that MergeTree is *column-oriented* — each part stores data column-by-column rather than row-by-row — and compaction is driven by *analytical query patterns* (sort order, aggregation state) rather than by key range maintenance.

== The write path

ClickHouse writes are *append-only*. Every `INSERT` creates one or more immutable, sorted *parts* on disk. Parts are never modified — only merged.

#align(center,
  grid(
    columns: (auto, auto, auto, auto, auto),
    column-gutter: 0.5cm,
    align: horizon,
    rect(fill: rgb("#e3f2fd"), inset: 8pt)[INSERT \ batch],
    [→],
    rect(fill: rgb("#fff3e0"), inset: 8pt)[part_1 \ sorted],
    rect(fill: rgb("#fff3e0"), inset: 8pt)[part_2 \ sorted],
    rect(fill: rgb("#e8f5e9"), inset: 8pt)[merged part \ sorted],
  )
)

#v(0.8em)

- Each part is a directory of column files, a primary index, and metadata
- Background *merges* consolidate many small parts into fewer large ones
- The merge process is where engine-specific logic runs (deduplication, aggregation, rollup...)
- Inserts should be *batched* — many tiny inserts create too many parts and slow merges

== ORDER BY — the most important schema decision

`ORDER BY` determines the *physical sort order* of every part. ClickHouse builds a *sparse primary index* over this order.

```sql
CREATE TABLE events (
  ts       DateTime,
  user_id  UInt64,
  action   String,
  amount   Float64
) ENGINE = MergeTree
ORDER BY (ts, user_id);
```

- ClickHouse stores one index entry per *granule* (~8 192 rows by default)
- Queries filtering on the leading `ORDER BY` columns skip irrelevant granules entirely
- A date-range query on `(ts, user_id)` is fast — a user-id filter alone must scan everything

*ORDER BY is not a preference — it is the primary index.* Choose based on your most frequent query filters, not on what feels natural.

== The engine family

The engine defines what happens *during a merge*. All engines share the same columnar storage and sparse index.

#table(
  columns: (1fr, 1fr),
  [*Engine*], [*Merge behavior*],
  [`MergeTree`], [No special logic — just compaction and sorting],
  [`ReplacingMergeTree`], [Deduplicates by primary key; keeps the latest version],
  [`CollapsingMergeTree`], [Cancels rows with opposite `sign` values — efficient deletes],
  [`VersionedCollapsingMergeTree`], [Same as Collapsing, but safe with out-of-order data],
  [`AggregatingMergeTree`], [Merges intermediate aggregation states — backbone of materialized views],
  [`SummingMergeTree`], [Sums numeric columns on merge — lightweight pre-aggregation],
  [`GraphiteMergeTree`], [Time-series retention and rollup (Graphite protocol)],
)

== ReplacingMergeTree — the common pitfall

`ReplacingMergeTree` deduplicates rows with the same primary key, keeping the row with the highest version (or the last inserted if no version column).

```sql
CREATE TABLE users (
  user_id UInt64,
  name    String,
  version UInt64
) ENGINE = ReplacingMergeTree(version)
ORDER BY user_id;
```

*Deduplication is asynchronous.* Merges happen in the background — a query may still return duplicates until a merge has run.

Two patterns to handle this:
- `SELECT … FINAL` — forces deduplication at query time; correct but up to 2× slower
- `argMax(name, version)` — pick the latest value in the application layer; fast, no `FINAL` needed

`FINAL` is fine for low-frequency or dashboard queries; avoid it on hot paths.
