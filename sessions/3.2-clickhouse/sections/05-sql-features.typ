= ClickHouse SQL

== Array functions

`arrayMap`, `arrayFilter`, and `arraySum` operate without unnesting \
`arrayJoin` turns each element into a row.

```sql
SELECT arrayJoin(tags) AS tag, count() AS occurrences
FROM events
GROUP BY tag
ORDER BY occurrences DESC;
```

`arrayJoin` is a lateral unnest — a row with N tags becomes N rows. No secondary table required.

== Approximate aggregation

For billion-row tables, exact distinct counts and percentiles are expensive \
ClickHouse ships purpose-built approximate functions with bounded error guarantees.

```sql
SELECT
    toStartOfDay(ts)         AS day,
    uniq(user_id)            AS approx_dau,    -- HyperLogLog
    quantile(0.95)(duration) AS p95_duration,  -- Reservoir sampling
    topK(10)(page)           AS top_pages      -- Space-Saving
FROM events
GROUP BY day;
```

== Aggregation combinators

ClickHouse aggregation functions accept *combinators* — suffixes that modify their behavior without a subquery.

```sql
SELECT
    vendor_id,
    count()                        AS total_trips,
    countIf(payment_type = 'card') AS card_trips,
    sumIf(fare, tip > 0)           AS tipped_revenue
FROM trips
GROUP BY vendor_id
WITH TOTALS;
```

`-If` applies a filter condition to any aggregate: `avgIf`, `maxIf`, `uniqIf`. `WITH TOTALS` appends a grand-total row. Combinators compose: `uniqArrayIf` is valid.

== SAMPLE

`SAMPLE` reads a deterministic fraction of granules at the storage level — not post-scan filtering.

```sql
SELECT count() / 0.1 AS estimated_total
FROM trips SAMPLE 0.1;
```

`SAMPLE 0.1` skips 90% of granules entirely — unlike `ORDER BY rand() LIMIT N` which scans the full table first. The same fraction always returns the same rows on the same data, making results reproducible.

== ASOF JOIN

`ASOF JOIN` matches each left row to the closest preceding right row on a time column.

```sql
SELECT t.symbol, t.quantity, p.price, t.quantity * p.price AS market_value
FROM trades AS t
ASOF LEFT JOIN prices AS p
    ON  t.symbol = p.symbol
    AND t.ts    >= p.ts;
```

The right table must be sorted by the join key then the time column. \
The inequality (`>=` or `>`) determines which side "closest" means.
