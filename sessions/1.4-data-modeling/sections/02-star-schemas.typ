#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Star Schemas

== The star schema

#align(center,
  fletcher.diagram(
    spacing: (3cm, 3cm),
    node-stroke: 0.8pt,
    node((1, 1), [*`fact_orders`* \ order_id, amount, \ qty, customer_key, \ product_key, date_key], fill: rgb("#fff9c4"), width: 5cm),
    node((0, 0), [`dim_customer` \ name, city, segment], fill: rgb("#bbdefb"), width: 3.5cm),
    node((2, 0), [`dim_product` \ name, category, brand], fill: rgb("#bbdefb"), width: 3.5cm),
    node((0, 2), [`dim_date` \ year, month, day, \ quarter, is_weekend], fill: rgb("#bbdefb"), width: 3.5cm),
    node((2, 2), [`dim_store` \ name, city, region], fill: rgb("#bbdefb"), width: 3.5cm),
    edge((1, 1), (0, 0), "-"),
    edge((1, 1), (2, 0), "-"),
    edge((1, 1), (0, 2), "-"),
    edge((1, 1), (2, 2), "-"),
  )
)

== Fact tables

- Contain the *measurements* — the numbers you aggregate
- One row per *event* or *transaction*: a sale, a click, a shipment
- Typically *narrow* (few columns) but *very tall* (billions of rows)
- Foreign keys point to dimension tables

#v(0.5em)

#table(
  columns: 5,
  align: (center, center, right, right, center),
  table.header([*order_id*], [*date_key*], [*amount*], [*qty*], [*customer_key*]),
  [1001], [20240315], [\$49.99], [2], [C-4821],
  [1002], [20240315], [\$12.50], [1], [C-1137],
  [1003], [20240316], [\$299.00], [1], [C-4821],
)

== Dimension tables

- Contain the *context* — the attributes you filter and group by
- Few rows (thousands to millions), but *wide* (many descriptive columns)
- Change slowly — a product's category rarely changes

#v(0.5em)

#table(
  columns: 4,
  align: (center, left, left, left),
  table.header([*customer_key*], [*name*], [*city*], [*segment*]),
  [C-4821], [Alice], [Paris], [Enterprise],
  [C-1137], [Bob], [Lyon], [SMB],
)

- *Surrogate keys* (C-4821) decouple the schema from source system IDs
- Enables tracking changes over time (*slowly changing dimensions*)

== Why this shape works for analytics

```sql
SELECT d.category, SUM(f.amount)
FROM fact_orders f
JOIN dim_product d ON f.product_key = d.product_key
WHERE f.date_key BETWEEN 20240101 AND 20241231
GROUP BY d.category
```

- The fact table is scanned with a *range filter* on date
- The dimension join is small — often a *broadcast join*
- Aggregation runs on the pre-filtered, joined result

== Wide tables — the extreme denormalization

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    rect((0, 0), (16, 2), fill: rgb("#fff9c4"), stroke: 0.8pt, radius: 0.1)

    let cols = ("order_id", "amount", "qty", "date", "cust_name", "cust_city", "prod_name", "prod_cat", "store_name", "region")
    for (i, col) in cols.enumerate() {
      let x = 0.8 + i * 1.5
      content((x, 1), text(size: 7pt, fill: luma(80))[#col])
      if i < cols.len() - 1 {
        line((x + 0.75, 0.2), (x + 0.75, 1.8), stroke: 0.3pt + luma(180))
      }
    }

    content((8, -0.7), text(size: 10pt)[One table, all columns — *no joins needed*])
  })
)

- All dimension attributes are *flattened into the fact table*
- Queries never join — just scan and aggregate
- Trade-off: massive redundancy (customer name repeated on every order)

== Pre-aggregation patterns

#align(center,
  fletcher.diagram(
    spacing: (3cm, 2cm),
    node-stroke: 0.8pt,
    node((0, 0), [`fact_orders` \ 1B rows], fill: rgb("#fff9c4"), width: 3.5cm),
    node((1, 0), [`agg_daily_sales` \ 365 rows/year], fill: rgb("#c8e6c9"), width: 3.5cm),
    node((2, 0), [`agg_monthly_cat` \ 120 rows/year], fill: rgb("#c8e6c9"), width: 3.5cm),
    edge((0, 0), (1, 0), "->", [GROUP BY date]),
    edge((0, 0), (2, 0), "->", [GROUP BY month, category], bend: 30deg),
  )
)

- *Pre-aggregated tables* (or *materialized views*) store pre-computed summaries
- Dashboard query on `agg_daily_sales`: 365 rows instead of 1 billion
- Trade-off: storage, staleness, maintenance cost

== Choosing the right grain

- The *grain* is the most detailed level of data in the fact table
- Too coarse (daily totals) → can't drill down to individual orders
- Too fine (every click) → table is enormous, queries slow

#v(0.5em)

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Grain*], [*Rows/year*], [*Can answer*]),
  [Individual transaction], [~1B], [Any question],
  [Daily summary per product], [~3.6M], [Daily trends, not individual orders],
  [Monthly summary per category], [~120], [Monthly trends only],
)

- Start at the finest grain you can afford to store and query

== \

#hero[A star schema is not a theory exercise. \ It's an *I/O reduction strategy*.]
