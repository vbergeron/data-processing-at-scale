#import "../style.typ": *

#show: lab-theme.with(
  title: [Lab 1.1 — Benchmarking a Single-Node Pipeline to its Breaking Point],
  session: [Session 1.1 — Introduction & Motivation],
  format: [Hands-on lab],
  tools: [Any language (student's choice), SQLite, system monitor (`btop` / `htop` / Activity Monitor / Task Manager)],
)

= Objective

You are going to re-invent a database — badly — and then watch a real one demolish your code. By progressively scaling a synthetic workload from 100K to 100M rows you will see exactly where single-machine processing breaks down and _why_ databases exist.

= Data Model

Two tables:

#table(
  columns: 4,
  align: (left, left, left, left),
  table.header([*Table*], [*Column*], [*Type*], [*Notes*]),
  [customers], [`customer_id`], [UUID], [primary key],
  [customers], [`name`], [TEXT], [first + last],
  [customers], [`city`], [TEXT], [from provided list],
  [orders], [`order_id`], [UUID], [primary key],
  [orders], [`customer_id`], [UUID], [FK → customers],
  [orders], [`amount`], [INT], [cents (e.g.~14999 = \$149.99)],
  [orders], [`ts`], [TIMESTAMP], [random within 2024],
)

= Material

Three text files are provided in the `assets/` folder (downloadable from the course website). Each file contains one entry per line, sorted alphabetically:

- `cities.txt` — 150 world cities
- `first_names.txt` — 98 first names
- `last_names.txt` — 97 last names

With 98 × 97 = 9,506 unique full name combinations, you can fill 10,000 customers with minimal collisions. You are free to use your own lists instead.

= Walkthrough

== Step 1 — Data Generation

=== 1.1 — Customer generator

Write a program that produces `customers.csv` with 10,000 rows:
- `customer_id`: a random UUID v4 (use your language's standard library)
- `name`: a random first name + last name from the provided lists
- `city`: picked uniformly at random from `cities.txt`

Verify: `wc -l customers.csv` should print 10,000 (plus a header if you added one). Open it, spot-check a few rows.

=== 1.2 — Order generator

Write a program that produces `orders.csv` with a _configurable_ row count (CLI argument or constant). Each row:
- `order_id`: a random UUID v4
- `customer_id`: a random UUID picked from the customer file you just generated
- `amount`: random integer in [100, 50000] (i.e.~\$1.00 to \$500.00)
- `ts`: random timestamp within 2024 (uniform random second between `2024-01-01T00:00:00` and `2024-12-31T23:59:59`)

Generate a first file with *100,000 rows*. Verify: `wc -l`, `head -5`, check file size on disk.

=== 1.3 — Sanity checks

- Count distinct `customer_id` values in `orders.csv` — should be close to 10,000.
- Check that `amount` values are in range.
- Note the file sizes. Predict: how big will 10M rows be? 100M?

== Step 2 — Hand-Rolled Aggregate (100K rows)

=== 2.1 — Load customers into memory

Read `customers.csv` and build an in-memory lookup: `customer_id → city`. This is your "index."

Measure: how long does this take? How much memory does it consume? (Check your system monitor — it should be negligible.)

=== 2.2 — Scan, filter, join, aggregate

Read `orders.csv` line by line. For each row:
+ Parse the line (split on delimiter, cast `amount` to int)
+ Filter: skip rows where `amount <= 5000` (i.e.~\$50.00)
+ Look up `city` from the customer hashmap using `customer_id`
+ Accumulate `sum(amount)` into a `city → total_revenue` hashmap

Print the result: revenue per city, sorted by city name.

Measure and record wall-clock time. At 100K rows this should be sub-second in any language.

=== 2.3 — Observe on your system monitor

Open your system monitor on a second terminal or screen. Run the program again. Note:
- *CPU:* one core briefly spikes
- *Memory:* barely moves
- *Disk I/O:* a small read burst, then nothing

Record these observations — you will compare them against later steps.

== Step 3 — Same Query in SQLite (100K rows)

=== 3.1 — Create the database and tables

Create a SQLite database. Define the schema:

```sql
CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    name TEXT,
    city TEXT
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    amount INTEGER,
    ts TEXT
);
```

=== 3.2 — Bulk load the CSVs

Import `customers.csv` and `orders.csv` into the tables. Use SQLite's `.import`, your language's SQLite bindings, or a bulk `INSERT` loop.

Measure how long the import takes. This is overhead your hand-rolled code does not pay — but it is a one-time cost.

=== 3.3 — Run the equivalent query

```sql
SELECT c.city, SUM(o.amount) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.amount > 5000
GROUP BY c.city
ORDER BY c.city;
```

Measure wall-clock time. Compare against step 2.2. At 100K rows, both should be fast.

=== 3.4 — Compare results

Verify that both approaches produce the same numbers. This confirms your hand-rolled code is correct and the comparison is fair.

== Step 4 — Scale to 10M Rows

=== 4.1 — Regenerate orders

Run your order generator with *10,000,000 rows*. Note:
- How long does generation itself take?
- How big is the CSV on disk?

=== 4.2 — Rerun hand-rolled code

Run your step 2 code on the 10M-row file. Measure wall-clock time.

*Observe on your system monitor:*
- *CPU:* one core pinned at 100% for the entire duration
- *Memory:* the two hashmaps are tiny (10K customers, 150 cities), but the file read buffer may grow
- *Disk I/O:* sustained read throughput — how close to your disk's maximum?

Record the time. Compare across languages if others in the room made different choices.

=== 4.3 — Rerun in SQLite

Re-import into SQLite (drop and recreate, or use a fresh DB). Measure import time separately from query time.

Run the same SQL query. Measure.

*Without an index:* SQLite does a full table scan + hash join. It is faster than hand-rolled code because it avoids CSV re-parsing, but it is not spectacular.

=== 4.4 — Add an index

```sql
CREATE INDEX idx_orders_customer ON orders(customer_id);
```

Measure how long index creation takes. Then rerun the query. Compare against 4.3.

*Key insight:* the index is an up-front cost that pays off on every subsequent query. Your hand-rolled code has no equivalent — every run re-reads and re-parses the entire file.

=== 4.5 — Run a second query

Compute something different — top 10 customers by total spend:

```sql
SELECT c.name, SUM(o.amount) AS total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id
ORDER BY total DESC
LIMIT 10;
```

In SQLite this reuses the loaded data and index. Near-instant.

With your hand-rolled code you would have to re-read and re-parse the entire CSV, build a different hashmap, then sort it. Write and run this code. Measure.

*The gap becomes clear:* SQLite pays the import cost once. Your code pays the full parsing cost on every single query.

== Step 5 — Scale to 100M Rows (The Wall)

=== 5.1 — Regenerate orders

Run your order generator with *100,000,000 rows*. Note:
- Generation time
- File size on disk (expect 5–10 GB)
- Does the generator itself start struggling? (Watch memory.)

=== 5.2 — Rerun hand-rolled code

Run your step 2 code.

*Observe on your system monitor:*
- *CPU:* single core at 100% for minutes (interpreted languages) or tens of seconds (compiled)
- *Disk:* sustained sequential read — the bottleneck may shift to I/O if the file does not fit in the OS page cache
- *Memory:* watch for growth if your code buffers lines or allocates intermediate strings

Record wall-clock time. This is now painful enough that you would not want to iterate on it.

=== 5.3 — Load into SQLite

Bulk-insert 100M rows. This takes minutes, but you only do it once.

Create the index. This also takes time (SQLite sorts 100M UUID strings for the B-tree).

=== 5.4 — Run queries in SQLite

Run the same two queries from steps 3.3 and 4.5. Measure.

SQLite handles them in seconds. Your hand-rolled code took minutes. The database wins by an order of magnitude or more.

=== 5.5 — Modify the query, run again

Change the filter from `amount > 5000` to `amount > 20000`. In SQLite: change one number, re-execute, seconds. With hand-rolled code: re-read the entire CSV, re-parse 100M lines, apply the new filter. Full cost again.

*This is the moment:* a database separates _storage_ from _query_. Your hand-rolled code welds them together. Every new question means starting from scratch.

== Step 6 — Push SQLite to its Limits (Foreshadowing)

=== 6.1 — Self-join: concurrent orders

Find pairs of orders from customers in the same city placed within 60 seconds of each other:

```sql
SELECT o1.order_id, o2.order_id, c1.city
FROM orders o1
JOIN orders o2 ON o1.order_id < o2.order_id
JOIN customers c1 ON o1.customer_id = c1.customer_id
JOIN customers c2 ON o2.customer_id = c2.customer_id
WHERE c1.city = c2.city
  AND ABS(unixepoch(o1.ts) - unixepoch(o2.ts)) < 60;
```

Even at 10M rows this query is extremely slow. At 100M it is hopeless.

=== 6.2 — Observe on your system monitor

- *CPU:* pegged at 100%
- *Disk:* massive write bursts as SQLite spills intermediate join results to temp files
- *Memory:* SQLite tries to stay within its cache limit, but temp file I/O dominates

Let it run for a minute or two, then cancel. The point is made.

=== 6.3 — Discussion

SQLite is single-threaded, single-node, and stores everything on one disk. For this query:
- The join is quadratic in the number of orders per city
- No amount of indexing fixes a quadratic join
- You would need to partition by city and parallelize across cores or machines
- This is exactly what distributed engines (Spark, Flink) do

*This is the hook for the rest of the course.*

= Key Takeaways

+ *Don't roll your own database.* Hand-rolled CSV processing is a terrible, unindexed, optimizer-free database. SQLite — a single C library — demolishes it.
+ *Databases separate storage from queries.* Load once, query many times. Hand-rolled code pays the full parsing cost on every question.
+ *Indexes are the first superpower.* An up-front $O(n log n)$ cost that turns every future lookup from $O(n)$ into $O(log n)$.
+ *Even a great single-node database has limits.* Quadratic joins, data that exceeds one disk, queries that need more than one core — these are the problems the rest of this course addresses.
+ *Your system monitor tells you which wall you hit.* CPU, memory, or I/O — the bottleneck determines your next move.
