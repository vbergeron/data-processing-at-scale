= Storage Layout & Compression

== Columnar layout on disk

Every column gets its own pair of files: 
- `column.bin` holds the compressed data
- `column.mrk3` holds the *marks* — byte offsets into `.bin` 

#align(center,
  grid(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    column-gutter: 0.2cm,
    align: top + center,
    rect(fill: rgb("#e3f2fd"), inset: 7pt)[
      `ts.bin` \
      #text(size: 9pt, fill: luma(120))[data]
    ],
    rect(fill: rgb("#dceefb"), inset: 7pt)[
      `ts.mrk3` \
      #text(size: 9pt, fill: luma(120))[offsets]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 7pt)[
      `amount.bin` \
      #text(size: 9pt, fill: luma(120))[data]
    ],
    rect(fill: rgb("#dceefb"), inset: 7pt)[
      `amount.mrk3` \
      #text(size: 9pt, fill: luma(120))[offsets]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 7pt)[
      `user_id.bin` \
      #text(size: 9pt, fill: luma(120))[data]
    ],
    rect(fill: rgb("#dceefb"), inset: 7pt)[
      `user_id.mrk3` \
      #text(size: 9pt, fill: luma(120))[offsets]
    ],
    rect(fill: rgb("#fff3e0"), inset: 7pt)[
      `primary.idx` \
      #text(size: 9pt, fill: luma(120))[sparse index]
    ],
  )
)


== Compression and encoding

ClickHouse applies two layers: a *codec* (data-type-aware transformation) followed by a general-purpose *compressor*.

#table(
  columns: (auto, 1fr, 1fr),
  [*Column type*], [*Codec*], [*Effect*],
  [Timestamps], [`Delta` + `ZSTD`], [Store differences between consecutive values],
  [Low-cardinality strings], [`LowCardinality`], [Dictionary-encodes the column],
  [Floats], [`Gorilla`], [XOR-based delta — efficient for slowly changing metrics],
  [General], [`LZ4` (default)], [Fast compression / decompression; ~3–5× ratio on typical event data],
  [High compression need], [`ZSTD`], [Slower, but 5–10× ratio; better for cold storage],
)

== The sparse primary index

ClickHouse does not use a B-tree. It stores *one index entry per granule* in `primary.idx`.

#align(center,
  grid(
    columns: (auto, auto, auto, auto),
    column-gutter: 0.5cm,
    align: top + center,
    rect(fill: rgb("#e3f2fd"), inset: 15pt)[
      *\#0-8191* \
      #text(size: 9pt)[min ts: 2024-01-01]
    ],
    rect(fill: rgb("#e3f2fd"), inset: 15pt)[
      *\#8192-16383* \
      #text(size: 9pt)[min ts: 2024-01-02]
    ],
    rect(fill: rgb("#e8f5e9"), inset: 15pt)[
      *\#16384-24575* \
      #text(size: 9pt)[min ts: 2024-01-03]
    ],
    rect(fill: luma(240), inset: 15pt)[
      *\#24576-32767* \
      #text(size: 9pt)[min ts: 2024-01-05]
    ],
  )
)

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
