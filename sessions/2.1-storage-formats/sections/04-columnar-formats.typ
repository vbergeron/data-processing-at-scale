#import "../../style.typ": hero, pause

= Columnar Formats

== The insight — row-oriented

Array of objects: every record is self-contained.

```json
[
  {"id": 1,  "name": "Alice", "amount": 19.99,   "currency": "EUR"},
  {"id": 2,  "name": "Bob",   "amount": 7.50,    "currency": "EUR"},
  {"id": 3,  "name": "Alice", "amount": 340.00,  "currency": "EUR"},
  {"id": 4,  "name": "Carol", "amount": 0.99,    "currency": "EUR"},
  {"id": 5,  "name": "Bob",   "amount": 1250.00, "currency": "USD"},
  {"id": 6,  "name": "Carol", "amount": 88.00,   "currency": "USD"},
  {"id": 7,  "name": "Alice", "amount": 15.00,   "currency": "USD"},
  {"id": 8,  "name": "Bob",   "amount": 4200.00, "currency": "GBP"},
  {"id": 9,  "name": "Carol", "amount": 530.50,  "currency": "GBP"},
  {"id": 10, "name": "Alice", "amount": 2.00,    "currency": "GBP"}
]
```

To read `amount`, you must parse *every byte of every record*.

== The insight — column-oriented

Object of arrays: each field is stored as one contiguous block.

```json
{
  "id":       [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  "name":     ["Alice","Bob","Alice","Carol","Bob",
               "Carol","Alice","Bob","Carol","Alice"],
  "amount":   [19.99, 7.50, 340.00, 0.99, 1250.00, 
               88.00, 15.00, 4200.00, 530.50, 2.00],
  "currency": ["EUR","EUR","EUR","EUR","USD","USD","USD","GBP","GBP","GBP"]
}
```

To read `amount`, you seek to *one* contiguous region and read only those bytes.

== Why columnar wins for analytics

Analytical queries touch few columns across many rows:

```sql
SELECT currency, SUM(amount) FROM transactions
WHERE date > '2024-01-01'
GROUP BY currency
```


- Only 3 columns used out of potentially dozens
- *Projection pruning*: read only `currency`, `amount`, `date`
- *Predicate pushdown*: skip row groups where `date <= '2024-01-01'`

== Why columnar compresses better

Shannon's entropy formula:

$ H = - sum_i p_i log_2 p_i $

Fewer distinct values → higher $p_i$ → lower $H$ → fewer bits needed.

- *Column* `["EUR","EUR","EUR","EUR","USD","USD","USD","GBP","GBP","GBP"]` — low $H$, compresses well
- *Row* `{id, name, amount, currency}` — high $H$, compresses poorly



== Dictionary encoding — low cardinality columns

`currency` has few distinct values — store a lookup table instead of repeating strings.

```
raw:        ["EUR","EUR","EUR","EUR","USD","USD","USD","GBP","GBP","GBP"]
dictionary: {0: "EUR", 1: "USD", 2: "GBP"}
codes:      [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]
```

10 strings → 10 small integers + 3 strings. Compression ratio grows with repetition.

== Delta encoding — monotonic or slowly changing columns

`user_id` increases by small, regular steps — store differences instead of absolute values.

```
raw:     [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010]
delta:   [1001,   +1,   +1,   +1,   +1,   +1,   +1,   +1,   +1,   +1]
delta²:  [1001,   +1,    0,    0,    0,    0,    0,    0,    0,    0]
rle:     base=1001, delta=1, count=10   ← 3 values total
```

When deltas are constant, delta-of-delta collapses them to zero — then RLE reduces the whole sequence to 3 numbers. Parquet and Gorilla use this for timestamps: nanosecond precision at fixed cadence compresses to ~1 bit per value.

== Run-length encoding — repeated values

Dictionary codes are already integers — RLE stacks on top naturally.

```
codes:   [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]   ← currency after dict encoding
encoded: [(0, 4), (1, 3), (2, 3)]           ← (code, count) pairs
```

10 integers → 3 pairs. \
Sorting can have massive impact on compression ratio within row groups.

== Using all techniques together

```json
{
  "id":       {"enc": "delta2+rle", "base": 1, 
                                    "delta": 1,
                                    "runs": [[1,10]]},

  "name":     {"enc": "dict",     "dict": ["Alice","Bob","Carol"],
                                  "codes": [0,1,0,2,1,2,0,1,2,0]},

  "amount":   {"enc": "plain",    "values": [19.99,7.5,340.0,0.99,1250.0,
                                             88.0,15.0,4200.0,530.5,2.0]},

  "currency": {"enc": "dict+rle", "dict": ["EUR","USD","GBP"],
                                  "runs": [[0,4],[1,3],[2,3]]}
}
```
== Apache Parquet

#grid(
  columns: (1fr, auto),
  column-gutter: 2cm,
  align: (left + horizon, right + horizon),
  [
    The dominant columnar format in the data ecosystem. \
    Created by Twitter and Cloudera (2013), now an Apache project.

    #v(0.8em)
    Used by: Spark, Flink, Trino, DuckDB, Snowflake, \ BigQuery, Athena, Pandas, Polars, ...
  ],
  image("../assets/parquet-logo.svg", width: 6cm),
)

== Parquet file structure

A Parquet file is organized in three levels:


- *File* → contains one or more *row groups*
- *Row group* → a horizontal slice (typically 128 MB), contains *column chunks*
- *Column chunk* → all values for one column in that row group, split into *pages*


The *footer* contains schema, row group locations, and column statistics.

The reader reads the footer first, then seeks to only the columns and row groups it needs.

== Page encodings — where compression happens

Within a column chunk, values are split into pages (~1 MB). Each page can use a different encoding:


- *Plain*: raw values, no compression
- *Dictionary*: replace values with integer codes (great for low-cardinality strings)
- *Run-length encoding (RLE)*: collapse repeated values (great for sorted data)
- *Delta encoding*: store differences between consecutive values (great for timestamps, IDs)
- *Bit-packing*: use fewer bits when values are small


Encodings are chosen per-column, per-page. The writer picks the best one automatically.


== Column statistics — skip without reading

Each column chunk stores *statistics* in the footer:


- *min / max* value in that chunk
- *null count*
- *distinct count* (optional)


Query: `WHERE amount > 1000`

If a column chunk's max is 500, the entire row group is *skipped*. No bytes read.

This is *predicate pushdown* — the format does filtering for free.

== Nested data in Parquet

Parquet supports nested structures using Dremel's *repetition* and *definition levels*:


```json
{"name": "Alice", "orders": [{"item": "book", "price": 9.99}, 
                             {"item": "pen", "price": 1.50}]}
{"name": "Bob",   "orders": []}
{"name": "Carol", "orders": null}
{"name": "Dave",  "orders": [{"item": "cup",  "price": 3.50}]}
{"name": "Eve",   "orders": [{"item": "hat",  "price": 12.00}, 
                             {"item": "bag", "price": 25.00}]}
```


- *Definition level* (d): how many optional/repeated ancestors are actually present
- *Repetition level* (r): which repeated ancestor restarted (0 = new record)

== Dremel encoding — decoded

Schema: `name` (required), `orders` (repeated group), `item` and `price` (both optional). \
Siblings share the same r/d levels. Max: d#sub[max]=2, r#sub[max]=1.

#table(
  columns: (auto, auto, auto, auto, auto, auto),
  align: (left, left, left, center, center, left),
  table.header([*Record*], [*orders.item*], [*orders.price*], [*r*], [*d*], [*Meaning*]),
  [Alice], [`"book"`], [`9.99`],  [0], [2], [new record, full order],
  [Alice], [`"pen"`],  [`1.50`],  [1], [2], [continued list],
  [Bob],   [—],        [—],       [0], [1], [orders present but empty],
  [Carol], [—],        [—],       [0], [0], [orders is null],
  [Dave],  [`"cup"`],  [`3.50`],  [0], [2], [new record, single order],
  [Eve],   [`"hat"`],  [`12.00`], [0], [2], [new record, first order],
  [Eve],   [`"bag"`],  [`25.00`], [1], [2], [continued list],
)

r=0 always marks a new top-level record. d encodes how deep the value actually exists.

== Apache Arrow — the in-memory columnar standard

#grid(
  columns: (1fr, auto),
  column-gutter: 2cm,
  align: (left + horizon, right + horizon),
  [
    Arrow is *not a file format* — it's a *memory layout specification*:

    - Defines how columnar data lives *in RAM* across languages
    - Zero-copy sharing between processes — no serialization step
    - Thriving ecosystem of libraries and tools
  ],
  image("../assets/arrow-logo.png", width: 5cm),
)

== Apache Arrow — IPC and the processing model

*Arrow IPC / Feather*: on-disk serialization of Arrow buffers.

- Memory-mappable: the file _is_ the in-memory layout — open and use directly
- No deserialization cost
- Feather v2 supports per-column compression (LZ4 or ZSTD)
- No column statistics → no predicate pushdown

#v(0.5em)
Think of it as: *Parquet for persistence, Arrow for processing*.

== Towards new formats

Parquet was built in the early 2010s for the Hadoop era. Since then, both hardware and workloads have changed:


- *Hardware*: NVMe SSDs, wide SIMD (AVX-512), GPUs
- *Storage*: S3-first stacks where every read is a network call 
- *Workloads*: point lookups, embeddings, images, ML features

== Lance — random access without compromise

Built for AI pipelines on NVMe storage (LanceDB, 2023):


- *Repetition index*: random access in *1–2 IOPS* per lookup, independent of nesting depth (Parquet: hundreds of IOPS)
- *Dual encoding*: "full zip" for fast scans, "miniblock" for random access — same file, two read paths
- *Versioned updates*: append-only log with fast deletes — no rewriting files
- *Native vector search*: built-in ANN index for embedding lookups


Matches Parquet on full scans; dramatically outperforms it on point lookups.

== Apache Vortex (incubating) — a framework, not just a format

Less a single format, more a *framework for composable columnar encodings* (SpiralDB → Apache, 2024):


- *Composable encodings*: FSST for strings, ALP for floats, dictionary for categoricals — mix and match per column
- *SIMD-native decompression*: designed to saturate modern memory bandwidth
- *Compressed execution*: keeps data compressed in Arrow arrays — no decompress-then-process step
- *2–10× faster scans* than Parquet, *100–200× faster random access*


Philosophy: no single compression scheme is best for all data types. Let the format adapt.

== F3 — the academic successor (SIGMOD 2026)

*Future File Format* (F3) — a CMU/Tsinghua project with Wes McKinney (creator of Pandas and Arrow) as co-author:


- *Embedded WASM decoders*: every file carries its own decoding logic — any reader can decode any encoding, forever
- *Decoupled I/O units*: independent of row group size, tuned per storage medium (8 MB default for S3)
- *Flexible dictionary scope*: per-column dictionary granularity instead of Parquet's one-per-row-group
- Published at SIGMOD 2026 — the premier database systems venue


Key insight: the format is *extensible by design* — new encodings are Wasm plugins, not spec changes. The interoperability problem that plagues Parquet v2 adoption is solved architecturally.

== Common themes across new formats

#table(
  columns: 2,
  align: (left, left),
  table.header([*Theme*], [*What it means*]),
  [SIMD & GPU-first design], [Encodings built to exploit vector instructions and parallel hardware],
  [Sub-row-group granularity], [Decompress ~1K values at a time, not ~1 MB pages],
  [Composable lightweight codecs], [Chains of simple encodings (RLE, bit-pack, dictionary) beat one heavyweight codec],
  [AI/ML-native], [First-class support for embeddings, vectors, random access],
  [S3/NVMe-aware I/O], [Tuned for object storage round trips and NVMe parallelism],
)


Research formats to also watch: *BtrBlocks* (TUM — cascaded lightweight compression), *FastLanes* (CWI — compressed execution for DuckDB/Velox).

== \

#hero[Parquet manage the data.\ Who manages the *metadata*?]
