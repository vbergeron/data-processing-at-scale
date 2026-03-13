== Recomputation vs Incremental Maintenance

- Full recomputation: O(total data)
- Incremental maintenance: O(change size)
- When the difference is orders of magnitude

== Modeling Changes as Deltas

- `(record, +1)` for inserts, `(record, -1)` for deletes
- Updates as delete + insert
- Compaction: cancellation of inverse diffs

== Differential Dataflow

- Processing only the deltas
- Partially ordered timestamps and iteration
- Composing incremental operators into a pipeline

== Monotonic vs Non-Monotonic Operators

- Count, sum, union: trivially incremental
- Top-K, threshold, negation: require care
- Connection to CALM (callback to session 3.4)

== Applications

- Materialized views
- Incremental ETL
- Live dashboards

== Demo

*Building an incremental computation engine that maintains views via deltas*
