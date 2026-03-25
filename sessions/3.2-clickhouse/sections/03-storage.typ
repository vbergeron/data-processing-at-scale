= Storage Layout & Compression

== Columnar layout on disk

Each part is a directory. Every column gets its own files — `column.bin` (compressed data) and `column.mrk3` (marks linking the index to byte offsets).

#align(center,
  grid(
    columns: (auto, auto, auto, auto),
    column-gutter: 0.6cm,
    align: top + center,
    rect(fill: rgb("#e3f2fd"), inset: 10pt)[
      `ts.bin` \
      #text(size: 9pt, fill: luma(120))[timestamps only]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 10pt)[
      `user_id.bin` \
      #text(size: 9pt, fill: luma(120))[user ids only]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 10pt)[
      `amount.bin` \
      #text(size: 9pt, fill: luma(120))[amounts only]
    ],
    rect(fill: rgb("#fff3e0"), inset: 10pt)[
      `primary.idx` \
      #text(size: 9pt, fill: luma(120))[sparse index]
    ],
  )
)

#v(0.8em)

A query `SELECT sum(amount) WHERE ts > yesterday()` reads only `ts.bin` and `amount.bin`. The `user_id` column is never touched. On a wide table with 50 columns, this is a 25–50× reduction in I/O before any filtering.

== Compression and encoding

ClickHouse applies two layers: a *codec* (data-type-aware transformation) followed by a general-purpose *compressor*.

#table(
  columns: (auto, 1fr, 1fr),
  [*Column type*], [*Codec*], [*Effect*],
  [Timestamps], [`Delta` + `ZSTD`], [Store differences between consecutive values — near-zero entropy for monotone sequences],
  [Low-cardinality strings], [`LowCardinality`], [Dictionary-encodes the column; stores integer indices instead of strings],
  [Floats], [`Gorilla`], [XOR-based delta — efficient for slowly changing metrics],
  [General], [`LZ4` (default)], [Fast compression / decompression; ~3–5× ratio on typical event data],
  [High compression need], [`ZSTD`], [Slower, but 5–10× ratio; better for cold storage],
)

#v(0.5em)

Compression ratios of 5–20× are routine. A 200 GB raw dataset commonly fits in 10–40 GB on disk — reducing both storage cost and I/O bandwidth.

== The sparse primary index

ClickHouse does not use a B-tree. It stores *one index entry per granule* (8 192 rows by default) in `primary.idx`.

#align(center,
  grid(
    columns: (auto, auto, auto, auto),
    column-gutter: 0.5cm,
    align: top + center,
    rect(fill: rgb("#e3f2fd"), inset: 8pt)[
      *Granule 0* \
      rows 0–8191 \
      #text(size: 9pt)[min ts: 2024-01-01]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 8pt)[
      *Granule 1* \
      rows 8192–16383 \
      #text(size: 9pt)[min ts: 2024-01-02]
    ],
    rect(fill: rgb("#e8f5e9"), inset: 8pt)[
      *Granule 2* \
      rows 16384–24575 \
      #text(size: 9pt)[min ts: 2024-01-03]
    ],
    rect(fill: luma(240), inset: 8pt)[
      *Granule 3* \
      rows 24576–32767 \
      #text(size: 9pt)[min ts: 2024-01-05]
    ],
  )
)

#v(0.8em)

A query `WHERE ts = '2024-01-03'` reads the index, identifies granule 2 as the candidate, and reads only those 8 192 rows from disk. Granules 0, 1, 3 are skipped entirely — never decompressed.

This is why `ORDER BY` is the primary index: the sparse index is only useful when data is physically sorted by the filter columns.

== Skip indexes

Beyond the primary index, ClickHouse supports secondary *data skipping indexes* — lightweight metadata stored per granule.

#table(
  columns: (auto, 1fr, 1fr),
  [*Type*], [*Stores per granule*], [*Best for*],
  [`minmax`], [Min and max value], [Numeric ranges, timestamps],
  [`set(N)`], [Set of up to N distinct values], [Low-cardinality filtering (`WHERE status = 'error'`)],
  [`bloom_filter`], [Probabilistic membership], [High-cardinality string matching (`WHERE user_id IN (...)`)],
  [`tokenbf_v1`], [Token bloom filter], [Full-text search, log analysis],
)

#v(0.5em)

Skip indexes are *advisory* — they add a granule-level check but never guarantee a match. A false positive costs one extra granule read; a true negative skips it entirely. They complement the primary index; they do not replace it.
