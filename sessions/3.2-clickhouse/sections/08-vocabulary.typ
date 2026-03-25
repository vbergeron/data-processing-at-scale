#import "../../style.typ": hero

= Wrap-Up

== Key vocabulary

#table(
  columns: (auto, 1fr),
  [*Term*], [*Definition*],
  [OLAP], [Online Analytical Processing — column-oriented, scan-heavy, aggregation-first workloads],
  [Part], [Immutable sorted directory of column files written by a single INSERT batch in ClickHouse],
  [Granule], [The atomic read unit in ClickHouse (~8 192 rows); the sparse primary index has one entry per granule],
  [Sparse primary index], [One index entry per granule — small, always fits in RAM, enables granule skipping],
  [ORDER BY], [In ClickHouse, defines the physical sort order and is the primary index — the most important schema decision],
  [MergeTree], [Base storage engine in ClickHouse; variants define behavior during background merges],
  [ReplacingMergeTree], [Deduplicates by primary key on merge; deduplication is asynchronous — `FINAL` or `argMax` needed for consistency],
  [AggregatingMergeTree], [Stores and merges intermediate aggregate state (`*State` / `*Merge` functions)],
  [Vectorized execution], [Processes one column-batch (granule) per operator call — SIMD-friendly, cache-warm],
  [Skip index], [Per-granule metadata (minmax, set, bloom filter) enabling additional granule pruning],
  [Materialized view], [A trigger on INSERT that incrementally aggregates new data into a target table],
  [`*State` / `*Merge`], [Function pair for incremental aggregation: `sumState` accumulates, `sumMerge` finalizes],
  [Projection], [An alternative physical sort of a table stored inline; ClickHouse selects automatically per query],
  [Arrow Flight SQL], [gRPC protocol for columnar query results over Apache Arrow — zero-copy end-to-end],
  [Tiered storage], [Storage policy routing parts across NVMe / block store / S3 by age or access frequency],
)

== One sentence to remember

ClickHouse is built without compromise: *columnar, analytical, and append-only*.
