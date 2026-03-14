#import "../../style.typ": hero
#import "@preview/cetz:0.4.2"

= Access Patterns & Storage Layout

== Row-oriented storage

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let colors = (rgb("#bbdefb"), rgb("#c8e6c9"), rgb("#fff9c4"), rgb("#ffcdd2"))
    let labels = ("id", "name", "city", "amount")

    for row in range(4) {
      for col in range(4) {
        let x = col * 2.5
        let y = (3 - row) * 1.2
        rect((x, y), (x + 2.3, y + 1), fill: colors.at(col), stroke: 0.5pt, radius: 0.05)
        if row == 0 {
          content((x + 1.15, y + 0.5), text(size: 9pt, weight: "bold")[#labels.at(col)])
        } else {
          content((x + 1.15, y + 0.5), text(size: 9pt)[row #row])
        }
      }
    }

    line((-0.3, -0.5), (10.5, -0.5), stroke: 0.8pt, mark: (end: ">"))
    content((5, -1), text(size: 9pt, fill: luma(120))[disk / memory layout: row 1 columns, then row 2 columns, ...])
  })
)

- All columns of one row stored *contiguously*
- Great for `SELECT * WHERE id = 42` — one seek, one read
- Terrible for `SELECT SUM(amount)` — must read *every column* of *every row*

== Columnar storage

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let colors = (rgb("#bbdefb"), rgb("#c8e6c9"), rgb("#fff9c4"), rgb("#ffcdd2"))
    let labels = ("id", "name", "city", "amount")

    for col in range(4) {
      for row in range(4) {
        let x = col * 3.5
        let y = (3 - row) * 1.0
        rect((x, y), (x + 3.2, y + 0.8), fill: colors.at(col), stroke: 0.5pt, radius: 0.05)
        if row == 0 {
          content((x + 1.6, y + 0.4), text(size: 9pt, weight: "bold")[#labels.at(col)])
        } else {
          content((x + 1.6, y + 0.4), text(size: 9pt)[val #row])
        }
      }
    }

    line((-0.3, -0.5), (14.5, -0.5), stroke: 0.8pt, mark: (end: ">"))
    content((7, -1), text(size: 9pt, fill: luma(120))[disk / memory layout: all ids, then all names, then all cities, ...])
  })
)

- All values of one column stored *contiguously*
- `SELECT SUM(amount)` reads *only* the amount column — skips the rest
- On a 100-column table, reading 3 columns = *97% less I/O*

== Column pruning in action

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let cols = ("id", "name", "city", "age", "email", "amount", "date", "status")
    let read = (false, false, false, false, false, true, true, false)

    for (i, col) in cols.enumerate() {
      let x = i * 2
      let color = if read.at(i) { rgb("#c8e6c9") } else { rgb("#e0e0e0") }
      rect((x, 0), (x + 1.8, 3), fill: color, stroke: 0.5pt, radius: 0.05)
      content((x + 0.9, 1.5), text(size: 8pt)[#col])
    }

    content((7.8, -0.7), text(size: 9pt, fill: luma(120))[`SELECT SUM(amount) WHERE date > ...` — only green columns read])
  })
)

- *Column pruning*: the engine skips columns not referenced in the query
- Combined with *predicate pushdown*: filter before reading irrelevant rows
- Parquet, ORC, Arrow — all columnar formats exploit this

== Compression — why columnar wins again

#table(
  columns: 3,
  align: (left, center, center),
  table.header([*Column*], [*Cardinality*], [*Compression ratio*]),
  [`status` (3 values)], [Very low], [50–100×],
  [`country` (200 values)], [Low], [10–20×],
  [`amount` (continuous)], [High], [2–4×],
  [`uuid` (unique)], [Max], [~1× (no gain)],
)

- Same-type values compress *much better* than mixed-type rows
- Dictionary encoding, run-length encoding, delta encoding — all exploit column homogeneity
- A 1 TB dataset often compresses to *100–200 GB* in Parquet

== Row vs columnar — decision matrix

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Row-oriented*], [*Columnar*]),
  [Point lookups by key], [Fast], [Slow],
  [Full-row inserts], [Fast (append)], [Complex (per-column)],
  [Analytical aggregations], [Slow (reads all columns)], [Fast (reads only needed)],
  [Compression], [Low (mixed types)], [High (homogeneous)],
  [Used by], [PostgreSQL, MySQL, SQLite], [Parquet, ORC, ClickHouse, DuckDB],
)

== What's wrong here?

- You store 500 GB of IoT sensor data in PostgreSQL (row-oriented)
- Dashboard query: `SELECT AVG(temperature) FROM readings WHERE ts > '2024-01-01'`
- Table has 50 columns — the query touches *2 of them*
- PostgreSQL reads *all 50 columns* from every row — 25× more I/O than needed

#v(0.5em)

Fix: export to Parquet or use a columnar engine (DuckDB, ClickHouse)

== \

#hero[Don't ask "how fast is the disk?" \ Ask "how much of the disk am I reading?"]
