#import "../../style.typ": hero

= Query Execution Models

== \

#hero[How fast can a CPU *actually* process data \ once it hits memory?]

== Pull-based execution

The consumer drives execution. Each operator exposes a `next()` method; the root calls `next()` on its child, which calls `next()` on its child, and so on until a row surfaces from the scan.

```
Aggregate.next()
  └─ Filter.next()
       └─ Scan.next()   ← produces one row
```

Control flows *top-down* (the request) and data flows *bottom-up* (the row). Every row crosses every operator boundary as a separate virtual function call — at 100M rows × 5 operators that is 500M dispatches just for routing.

This is the Volcano model (Graefe, 1994), used by most databases until the 2010s and by Spark's pre-2.0 RDD API.

== Push-based execution

The producer drives execution. Each operator implements `produce()` / `consume(row)`. The scan calls `consume(row)` on its parent, which immediately calls `consume(row)` on its parent, and so on.

```
Scan.produce()
  → Filter.consume(row)
       → Aggregate.consume(row)   ← row processed end-to-end
```

Control and data both flow *bottom-up* in one pass. There are no `next()` calls crossing operator boundaries — the whole pipeline becomes a single nested call stack, which the JIT can inline into one tight loop.

Spark's Whole-Stage Code Generation uses push semantics internally, even though the external DataFrame API remains pull-style at the stage boundary.

== Pull = iterators, push = continuations

These are not new ideas — they are standard programming abstractions.

*Pull* maps directly to the *iterator* pattern:

```scala
trait Iterator[A] { def hasNext: Boolean; def next(): A }
```

The caller decides when to consume the next element. Scala's `Iterator`, Java's `Iterator`, Python's generators — all pull.

*Push* maps directly to *continuation-passing style* (CPS):

```scala
// instead of returning a value, call the next function with it
def process(row: Row, k: Row => Unit): Unit = k(transform(row))
```

`consume(row)` is a continuation — it tells the operator "here is your input, keep going." The pipeline is a chain of nested continuations, which is exactly what the JIT sees and inlines.

The duality is fundamental: any pull pipeline can be mechanically rewritten as a push pipeline by converting `next()` returns into `consume()` calls — which is precisely what Spark's code generator does at compile time.

== Vectorized execution

Process a *batch* of rows at a time (typically 1024–8192) rather than one row.

Each operator receives a *column batch* — arrays of values for each column — and applies the operation to the whole array using tight loops.

Tight loops = *SIMD*: the CPU can apply the same operation to 4–16 values in a single instruction (AVX2, AVX-512).

Cache behavior improves dramatically: a 1024-row int column fits in 4 KB — one cache line.

ClickHouse and DuckDB are built on this model. Spark's Parquet reader uses vectorized decoding.

== Compiled / JIT execution

Rather than interpreting a plan at runtime, *generate and compile native code* for the specific query.

The generated code is a single tight loop over the data, with no virtual calls, no boxing, no operator boundaries visible to the CPU.

Spark implements this as *Whole-Stage Code Generation* (Tungsten), introduced in Spark 2.0. The query plan is compiled to a single Java/JVM bytecode class at runtime.

Example: `SELECT sum(price * quantity) FROM orders WHERE region = 'EU'`

Generated code applies filter, multiply, and aggregate in one pass — no intermediate collections.

== What this means in practice

#table(
  columns: (auto, auto, auto, auto, 1fr),
  [*Model*], [*Unit*], [*Virtual calls*], [*SIMD*], [*Best for*],
  [Pull / Volcano], [1 row],    [Many], [None],    [Simplicity],
  [Vectorized],     [~1K rows], [Few],  [Yes],     [I/O bound, analytics],
  [JIT / compiled], [All rows], [None], [Partial], [CPU bound, aggregations],
)

Spark combines: *vectorized Parquet reading* (IO layer) + *compiled execution* (operator layer). The two complement each other.
