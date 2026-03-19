#import "../../style.typ": hero

= DataFrames & Spark SQL

== \

#hero[RDDs give you control. \ DataFrames give you *optimization*. \ Spark SQL gives you both.]

== The API evolution

*RDD (2012)*: low-level, untyped distributed collection. Flexible but the optimizer cannot see inside closures.

```scala
rdd.filter(row => row.getInt(2) > 0).map(row => (row.getString(0), row.getDouble(1)))
```

Catalyst cannot optimize the lambda — it is opaque Java bytecode.

*DataFrame (2015)*: structured, schema-aware. Operations are expressed as relational algebra trees that Catalyst can inspect and rewrite.

```scala
df.filter($"price" > 0).select($"region", $"revenue")
```

*Dataset\[T\] (2015)*: typed compile-time safety + Catalyst optimization for DataFrame-style operations.

*Spark SQL (ongoing)*: pure SQL string parsed directly into a logical plan — same optimizer, same physical plan.

== DataFrames are lazy relational plans

Every DataFrame operation returns a new DataFrame with an updated logical plan — nothing executes.

```scala
val orders = spark.read.parquet("orders/")
val eu = orders.filter($"region" === "EU")
val agg = eu.groupBy($"product").agg(sum($"revenue"))
```

`agg` is just a plan tree: `Aggregate(Project(Filter(Scan(orders))))`. No data has been read.

Calling `agg.show()` triggers Catalyst to optimize and Tungsten to execute.

== Column expressions

DataFrame columns are *expression trees*, not values:

```scala
$"price" * $"qty"              // Multiply(UnresolvedAttribute(price), UnresolvedAttribute(qty))
$"region" === "EU"             // EqualTo(UnresolvedAttribute(region), Literal("EU"))
when($"status" === "active", 1).otherwise(0)
```

These are first-class objects — they can be composed, passed around, and inspected by the optimizer. A Scala lambda cannot be.

== Spark SQL

SQL strings are parsed by Catalyst's ANTLR grammar into the same logical plan:

```sql
SELECT region, sum(price * qty) AS revenue
FROM orders
WHERE price > 0
GROUP BY region
```

Equivalent to the DataFrame expression above. The optimizer sees the same plan either way.

You can mix SQL and DataFrame:

```scala
orders.createOrReplaceTempView("orders")
val result = spark.sql("SELECT region, sum(revenue) FROM orders GROUP BY region")
result.filter($"region" =!= "UNKNOWN")
```

== When to use which API

*SQL*: ad-hoc exploration, queries written by non-engineers, readability.

*DataFrame*: programmatic composition, conditional logic, iterative plan construction.

*Dataset\[T\]*: when type safety matters and the domain model is well-defined. Note: typed map/filter operations lose Catalyst optimizability — prefer typed columns over lambdas.

*RDD*: last resort — custom partitioners, non-relational algorithms (graph traversal, ML iterations over raw bytes). Rarely needed.

== UDFs — and why to avoid them

User-Defined Functions allow custom logic:

```scala
val clean = udf((s: String) => s.trim.toLowerCase)
df.withColumn("name", clean($"raw_name"))
```

But:
- Catalyst cannot optimize *inside* a UDF — it is a black box
- Scala UDFs: break code generation at the boundary but stay on JVM
- Python UDFs (`pyspark.udf`): serialize rows to Python, execute in Python, deserialize back — 10–100× slower
- *Pandas UDFs* (Apache Arrow): batch-oriented, much faster than row-wise Python UDFs, but still cross-process

Always prefer built-in functions (`functions.*`) over UDFs. If you must use a UDF, prefer Scala/Java UDFs and make them as narrow as possible.
