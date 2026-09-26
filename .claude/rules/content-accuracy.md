# Content Accuracy

## Verify before stating

These categories of claims go stale and must be double-checked before writing:

- **Cloud infrastructure guarantees** (consistency models, SLA wording, feature availability) — check the year. Example: S3 consistency changed in December 2020; stating "eventually consistent" after that date is wrong.
- **"No X support"** claims about libraries or formats — check the current release. Example: Feather v2 added compression; Arrow, DuckDB, Parquet specs evolve yearly.
- **Protocol/consensus semantics** — distinguish linearizability, sequential consistency, causal consistency precisely. ZooKeeper reads are *not* linearizable by default; only writes are.

## Flag uncertainty explicitly

If a claim may be version-specific or time-sensitive, add a parenthetical: *(as of vX.Y / year)*.  
Never present a claim confidently if it depends on a release date or a spec version you haven't verified.

## Math syntax in Typst

Typst inline math: `$...$` — not `\$...\$` (LaTeX habit).  
Typst block math: `$ ... $` (with spaces inside).  
The `columns:` parameter in `#table` takes widths only (`auto`, `1fr`, lengths) — never alignment values like `center`.
