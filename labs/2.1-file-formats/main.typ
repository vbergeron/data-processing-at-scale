#import "../style.typ": *

#show: lab-theme.with(
  title: [Lab 2.1 — What Does My Query Actually Read?],
  session: [Session 2.1 — Storage Formats & Distributed File Systems],
  format: [Individual hands-on lab],
  tools: [Python 3.11+, DuckDB 1.x — PyArrow optional (Exercise 4)],
)

= Objective

Measure the concrete cost of file format choices. You will convert the same
dataset into four formats, run identical queries on each, and observe how much
data the engine actually reads. You will then deliberately break and restore
predicate pushdown to understand what prevents it.

By the end you should be able to answer: _given a workload, which format
minimises I/O — and why?_

= Setup

== Install

You can run all queries in this lab either with the DuckDB CLI or the Python API — pick whichever you prefer.

*DuckDB CLI* — download the single binary from #link("https://duckdb.org/docs/installation/")[duckdb.org/docs/installation] and run:
```bash
duckdb          # interactive shell
```

*Python API*:
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install duckdb
```

The SQL is identical in both. CLI users can prefix any query with `.mode line` to get readable output, and use `.quit` to exit. Exercise 4 (bonus) additionally requires `pip install pyarrow` (Python only).

== Dataset

One month of NYC Yellow Taxi trips (~50 MB Parquet, ~3 million rows):

```bash
mkdir -p data
curl -L -o data/yellow_tripdata_2024-01.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
```

Fallback if the URL is unavailable: replace `2024-01` with `2023-12` — the schema is identical.

== Generating the comparison formats

```sql
COPY (SELECT * FROM 'data/yellow_tripdata_2024-01.parquet')
  TO 'data/trips.csv'             (FORMAT CSV, HEADER true);
COPY (SELECT * FROM 'data/yellow_tripdata_2024-01.parquet')
  TO 'data/trips.ndjson'          (FORMAT JSON);
COPY (SELECT * FROM 'data/yellow_tripdata_2024-01.parquet')
  TO 'data/trips_snappy.parquet'  (FORMAT PARQUET, COMPRESSION snappy);
COPY (SELECT * FROM 'data/yellow_tripdata_2024-01.parquet')
  TO 'data/trips_zstd.parquet'    (FORMAT PARQUET, COMPRESSION zstd);
```

Run these statements in the DuckDB CLI or wrap them in `con.execute(...)` calls in Python.

Columns used in the exercises: `fare_amount` (float), `payment_type` (integer), `trip_distance` (float), `tpep_pickup_datetime` (timestamp).

= Exercise 1 — File sizes and compression ratio

Run `ls -lh data/trips.*` and compare the sizes of the four files.

== Questions

+ Which format is largest? Why do field names repeated on every row make it worse than CSV?
+ Parquet Zstd is smaller than Parquet Snappy. What does Zstd trade to achieve that?
+ The original download (`yellow_tripdata_2024-01.parquet`) may be a different
  size from your `trips_snappy.parquet`. Why might two Parquet files with the
  same data differ in size?

= Exercise 2 — Bytes read: projection pruning

We run a 2-column aggregation on a 19-column table.

== Task

Run this query on each of the three formats and look for `Bytes Read` in the scan node:

```sql
EXPLAIN ANALYZE
SELECT payment_type, AVG(fare_amount)
FROM 'data/trips.csv'
GROUP BY payment_type ORDER BY payment_type;
```

Repeat with `'data/trips.ndjson'` and `'data/trips_snappy.parquet'` and compare the three plans.

== Questions

+ CSV reads the whole file regardless of how many columns you select. Explain why.
+ Parquet reads a fraction of the file. Which file-format concept enables this?
+ If the table had 100 columns and your query used 2, how would the ratio change for each format?

= Exercise 3 — Predicate pushdown

== Part A — Pushdown working

Run this query and inspect the plan:

```sql
EXPLAIN ANALYZE
SELECT COUNT(*) FROM 'data/trips_snappy.parquet'
WHERE fare_amount > 50;
```

Look for `Filters:` and `Row Groups:` in the Parquet scan node.
Note how many row groups are *read* vs *total*.

*Before running: predict* — out of ~3 million rows, how many do you expect to have `fare_amount > 50`?

== Part B — Breaking pushdown

Now wrap the column in a function and observe what changes:

```sql
EXPLAIN ANALYZE
SELECT COUNT(*) FROM 'data/trips_snappy.parquet'
WHERE ROUND(fare_amount, 0) > 50;
```

Compare the plan output for both queries: note whether `Filters:` appears in the scan node and how many row groups are read.

== Part C — Other patterns that break pushdown

Test the following predicates. For each, record whether the filter is pushed
into the scan:

```python
predicates = [
    "fare_amount + 0 > 50",           # arithmetic on column
    "CAST(fare_amount AS INTEGER) > 50",  # cast
    "fare_amount > 50 AND fare_amount IS NOT NULL",  # compound
    "fare_amount BETWEEN 50 AND 200",  # range
]
```

== Questions

+ Why can DuckDB skip row groups for `fare_amount > 50` but not for
  `ROUND(fare_amount, 0) > 50`?
+ What metadata does the Parquet file store that makes row-group skipping possible?
+ `BETWEEN 50 AND 200` — does it push? What two statistics does the engine need
  to decide whether a row group can be skipped?

= Exercise 4 (bonus) — Parquet footer inspection

Requires `pip install pyarrow`. PyArrow exposes the full Parquet metadata without running a query.
Scala users can use Arrow Java instead: #link("https://arrow.apache.org/docs/java/ipc.html")[arrow.apache.org/docs/java/ipc.html].

```python
import pyarrow.parquet as pq

meta = pq.read_metadata("data/trips_snappy.parquet")
print(f"Row groups : {meta.num_row_groups}")
print(f"Total rows : {meta.num_rows:,}")
print()

# Inspect statistics for fare_amount in row group 0
rg = meta.row_group(0)
for i in range(rg.num_columns):
    col = rg.column(i)
    if "fare" in col.path_in_schema:
        stats = col.statistics
        print(f"Column     : {col.path_in_schema}")
        print(f"Min        : {stats.min}")
        print(f"Max        : {stats.max}")
        print(f"Null count : {stats.null_count}")
        print(f"Encoding   : {col.encodings}")
```

Run this for all row groups and answer:

+ How many row groups does the file have?
+ What is the global max of `fare_amount`? Does this match the anomalous taxi
  fares NYC is known for?
+ Is `fare_amount` dictionary-encoded? Why or why not (think about cardinality)?
+ Find a column that *is* dictionary-encoded. Which one and why?

= Key Takeaways

- Columnar formats (Parquet) read only the columns your query uses. Row formats
  (CSV, NDJSON) always scan every byte.
- Predicate pushdown uses per-column statistics stored in the footer to skip
  entire row groups *before reading any data values*.
- Pushdown is silently disabled by any transformation on the filtered column.
  The engine cannot infer the output range of an arbitrary function.
- File size and I/O cost are related but not identical: Zstd compresses better
  than Snappy but may decompress slower — the right choice depends on your
  CPU/IO balance.
