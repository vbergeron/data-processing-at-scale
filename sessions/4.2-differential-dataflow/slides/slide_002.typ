== Modeling Changes as Deltas

- `(record, +1)` for inserts, `(record, -1)` for deletes
- Updates as delete + insert
- Compaction: cancellation of inverse diffs
