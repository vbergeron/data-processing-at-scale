#import "../../style.typ": hero, pause
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Lazy Evaluation & DAG Execution

== \

#hero[You built MapReduce. \ Spark is what happens when you *generalize* it.]

== From MapReduce to Spark

#align(center,
  grid(
    columns: (auto, auto),
    column-gutter: 2cm,
    align: top + center,
    [
      *MapReduce* — fixed pipeline \
      #v(0.3em)
      #fletcher.diagram(
        spacing: (0pt, 0.65cm),
        node-stroke: 0.8pt,
        node-corner-radius: 4pt,
        node((0, 0), [Input],         fill: rgb("#e3f2fd"), width: 2.6cm, inset: 7pt),
        node((0, 1), [Map ×N],        fill: rgb("#fff3e0"), width: 2.6cm, inset: 7pt),
        node((0, 2), [_disk write_],  fill: rgb("#f5f5f5"), width: 2.6cm, inset: 5pt,
                                      stroke: (dash: "dashed")),
        node((0, 3), [Reduce ×M],     fill: rgb("#fff3e0"), width: 2.6cm, inset: 7pt),
        node((0, 4), [Output],        fill: rgb("#e8f5e9"), width: 2.6cm, inset: 7pt),
        edge((0,0),(0,1), "->"),
        edge((0,1),(0,2), "->"),
        edge((0,2),(0,3), "->"),
        edge((0,3),(0,4), "->"),
      )
    ],
    [
      *Spark* — arbitrary DAG, in-memory \
      #v(0.3em)
      #fletcher.diagram(
        spacing: (1.5cm, 0.65cm),
        node-stroke: 0.8pt,
        node-corner-radius: 4pt,
        node((0, 0), [Scan A],    fill: rgb("#e3f2fd"), width: 2cm, inset: 7pt),
        node((2, 0), [Scan B],    fill: rgb("#e3f2fd"), width: 2cm, inset: 7pt),
        node((0, 1), [Filter],    fill: rgb("#fff3e0"), width: 2cm, inset: 7pt),
        node((2, 1), [Filter],    fill: rgb("#fff3e0"), width: 2cm, inset: 7pt),
        node((1, 2), [Join],      fill: rgb("#fce4ec"), width: 2cm, inset: 7pt),
        node((1, 3), [GroupBy +\ Aggregate], fill: rgb("#e8f5e9"), width: 3.2cm, inset: 7pt),
        edge((0,0),(0,1), "->"),
        edge((2,0),(2,1), "->"),
        edge((0,1),(1,2), "->"),
        edge((2,1),(1,2), "->"),
        edge((1,2),(1,3), "->"),
      )
    ],
  )
)

== Resilient Distributed Datasets

The *RDD* (Resilient Distributed Dataset) is Spark's core abstraction, introduced in the 2012 NSDI paper.

An RDD is:
- *Distributed*: split into partitions spread across executor JVMs
- *Immutable*: operations never modify an RDD; they produce a new one
- *Typed*: `RDD[String]`, `RDD[(K, V)]`, etc. — checked at compile time
- *Resilient*: if a partition is lost, Spark recomputes it by replaying its *lineage* — the sequence of transformations that produced it

== Cluster architecture

#align(center,
  fletcher.diagram(
    spacing: (3.5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 1), [*Driver*\ #text(size: 9pt)[runs `main()`\ builds the DAG\ submits stages]], width: 3cm, inset: 8pt),
    
    node((0, 2), [*Cluster Manager*], fill: rgb("#fff3e0"), width: 3.2cm, inset: 8pt),
    
    node((1, 0), [*Executor*], width: 4cm, inset: 8pt),
    node((1, 1), [*Executor*], width: 4cm, inset: 8pt),
    node((1, 2), [*Executor*], width: 4cm, inset: 8pt),
    
    edge((0,1),(0,2), "->"),
    
    edge((0,1),(1,0), "<->"),
    edge((0,1),(1,1), "<->"),
    edge((0,1),(1,2), "<->"),
    
    edge((0,2),(1,0), "->", stroke: (dash: "dashed")),
    edge((0,2),(1,1), "->", stroke: (dash: "dashed")),
    edge((0,2),(1,2), "->", stroke: (dash: "dashed")),
  )
)

The Cluster Manager provisions executor JVMs; the Driver then dispatches tasks and collects results *directly* via RPC — the Cluster Manager is no longer in the loop. The driver *never touches data*.

== Kubernetes

Each executor runs in its own *pod* — ephemeral, isolated, deleted when the task completes.

*Dynamic allocation* (`spark.dynamicAllocation.enabled = true`): the driver requests new executor pods as pending tasks grow, and releases idle pods. No fixed pool to pre-provision.

*Driver placement*:
- *Client mode*: driver runs on the submitting machine, executor pods connect back — good for interactive sessions, requires network access from the cluster
- *Cluster mode*: driver itself runs as a pod — fully in-cluster, preferred for production jobs submitted via CI or a scheduler (Argo, Airflow)

== Transformations vs actions

Every Spark operation is either a *transformation* or an *action*.

*Transformations* — describe what to compute, produce a new RDD/DataFrame, execute nothing:
- `map`, `filter`, `groupBy`, `join`, `select`, `withColumn`

*Actions* — trigger execution, return a result or write output:
- `count`, `collect`, `show`, `write`, `save`

Nothing runs until an action is called. The driver builds the full plan first.

== Why lazy evaluation?

Building the plan before running it allows the optimizer to:

- Eliminate columns never referenced downstream (*projection pruning*)
- Push filters as close to the source as possible (*predicate pushdown*)
- Reorder joins based on table sizes (*join reordering*)
- Fuse consecutive operations into a single pass (*pipelining*)

A row-at-a-time system executing eagerly cannot do any of this — each operation commits its output before the next one has a chance to react.

== The DAG

Each transformation adds a node to the DAG. Nodes carry:

- The operation type and its parameters
- A reference to parent node(s)
- The *partitioning scheme* of the output

Spark walks this DAG during planning, identifies *shuffle boundaries*, and groups everything between two shuffles into a *stage*.

Within a stage, all operations are *pipelined* — no intermediate materialization.

== Stages and tasks

A *stage* is a maximal sequence of operations that can run without a shuffle.

A *task* is one stage applied to one partition. If a stage processes 200 partitions, it creates 200 tasks, each running on one executor core.

Stage boundaries are always caused by *wide dependencies* — operations where a row can go to any output partition (shuffle). Narrow dependencies (one input partition → one output partition) never create a stage boundary.

== Narrow vs wide dependencies

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.5cm,
    [
      #align(center)[*Narrow* — 1 input → 1 output partition \ no shuffle]
      #v(0.5em)
      #align(center,
        fletcher.diagram(
          spacing: (2.5cm, 0.8cm),
          node-stroke: 0.8pt,
          node-corner-radius: 4pt,
          node((0, 0), [P#sub[0]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((0, 1), [P#sub[1]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((0, 2), [P#sub[2]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((1, 0), [P#sub[0]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          node((1, 1), [P#sub[1]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          node((1, 2), [P#sub[2]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          edge((0,0),(1,0), "->"),
          edge((0,1),(1,1), "->"),
          edge((0,2),(1,2), "->"),
        )
      )
      #v(0.5em)
      #align(center)[`map`, `filter`, `union`]
    ],
    [
      #align(center)[*Wide* — 1 input → any output partition \ shuffle]
      #v(0.5em)
      #align(center,
        fletcher.diagram(
          spacing: (2.5cm, 0.8cm),
          node-stroke: 0.8pt,
          node-corner-radius: 4pt,
          node((0, 0), [P#sub[0]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((0, 1), [P#sub[1]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((0, 2), [P#sub[2]], fill: rgb("#e3f2fd"), width: 1.4cm, inset: 8pt),
          node((1, 0), [P#sub[0]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          node((1, 1), [P#sub[1]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          node((1, 2), [P#sub[2]], fill: rgb("#e8f5e9"), width: 1.4cm, inset: 8pt),
          edge((0,0),(1,0), "->"),
          edge((0,0),(1,1), "->"),
          edge((0,0),(1,2), "->"),
          edge((0,1),(1,0), "->"),
          edge((0,1),(1,1), "->"),
          edge((0,1),(1,2), "->"),
          edge((0,2),(1,0), "->"),
          edge((0,2),(1,1), "->"),
          edge((0,2),(1,2), "->"),
        )
      )
      #v(0.5em)
      #align(center)[`groupBy`, `join`, `distinct`]
    ],
  )
)

== What triggers a shuffle

Operations with wide dependencies:
- `groupBy` / `groupByKey`
- `join` (unless one side is broadcast)
- `repartition` / `coalesce` (increasing partition count)
- `distinct`
- Window functions with `PARTITION BY`

Operations with narrow dependencies (no shuffle):
- `map`, `filter`, `flatMap`
- `union`
- `coalesce` (reducing partition count, no network transfer)
- Broadcast joins

== The DataFrame API

DataFrames and Datasets are built on top of RDDs — they add a schema and give Spark enough structure to optimize. The execution model underneath is the same.

```scala
val orders = spark.read.parquet("orders/")
// orders: DataFrame with schema (id: Long, region: String, amount: Double)

val result = orders
  .filter($"region" === "EU")
  .groupBy($"region")
  .agg(sum($"amount").as("total"))
```

Operations are expressed as *column expressions* (not opaque lambdas) — Spark can inspect, rewrite, and optimize the full plan.

== Dataset[T]

`Dataset[T]` wraps a DataFrame with a compile-time type — the schema is enforced by the Scala type system, not just at runtime.

```scala
case class Order(id: Long, region: String, amount: Double)

val orders: Dataset[Order] = spark.read.parquet("orders/").as[Order]

val result: Dataset[(String, Double)] = orders
  .filter(_.region == "EU")      // typed lambda — loses optimizer visibility
  .groupByKey(_.region)
  .mapValues(_.amount)
  .reduceGroups(_ + _)
```

Typed lambdas (`_.region == "EU"`) are opaque to the optimizer — prefer column expressions (`$"region" === "EU"`) even on `Dataset[T]` to keep the optimizer in the loop.

== Spark SQL

`spark.sql` accepts a plain SQL string and parses it into the same logical plan as the DataFrame API.

```scala
orders.createOrReplaceTempView("orders")

val result = spark.sql("""
  SELECT region, sum(amount) AS total
  FROM orders
  WHERE region = 'EU'
  GROUP BY region
""")
```

SQL strings are parsed into the same logical plan as the equivalent DataFrame chain — same optimizer, same physical plan, same generated bytecode.

== One plan, three syntaxes

All three APIs compile to the same *unresolved logical plan*:

#table(
  columns: (auto, 1fr),
  [*API*], [*Use when*],
  [DataFrame], [Programmatic composition, conditional logic, reusable plan fragments],
  [Dataset\[T\]], [Domain model already exists, type safety at boundaries matters],
  [Spark SQL], [Ad-hoc exploration, non-engineer authors, readability],
)

Choosing between them is a matter of *ergonomics*, not performance. The same unresolved logical plan is produced regardless of which syntax you use — we will see how it gets optimized next.

== Scala vs Python

Both languages have full Spark APIs. The trade-offs are real.

*PySpark (Python):*
- Larger data science ecosystem — pandas, scikit-learn, matplotlib
- Easier onboarding, Jupyter-native workflow
- Python UDFs: cross-process serialization via pickle — 10–100× slower than JVM code
- Pandas UDFs (Arrow-based): much faster, still cross-process
- No compile-time column checking — `$"reigon"` fails at runtime

*Spark with Scala:*
- JVM-native — no process boundary, no serialization overhead
- UDFs stay inside the JVM, code generation uninterrupted
- Compile-time type checking on the JVM side
- Same JVM as the executor: jar deployed, no language bridge

*Rule of thumb*: use Python for exploration and pipelines that stay in SQL/DataFrame; use Scala when you need custom UDFs, tight performance, or type safety at scale.
