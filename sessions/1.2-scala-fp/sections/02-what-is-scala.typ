#import "../../style.typ": hero, pause

= What is Scala?

== Scala in one slide

- Merges *OOP* and *FP* — "objects for modules, functions for compute"
- *Strong static type system* with inference
- Extensive, functional *collection library*
- Excellent capabilities for *abstraction*

#pause

Try it now: #link("https://scastie.scala-lang.org/")[scastie.scala-lang.org]

== Scala's positioning

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Strong static typing*], [*Functional purity*]),
  [JavaScript], [✗], [✗],
  [Python], [✗], [✗],
  [TypeScript], [✓], [✗],
  [Java / C], [✓], [✗],
  [Rust / OCaml / F\#], [✓], [✓ (mostly)],
  [Haskell], [✓], [✓✓],
  [*Scala*], [✓], [✓ (your choice)],
)

Scala lets you _choose_ how pure you want to be.

== Compilation backends

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Backend*], [*Use case*], [*Examples*]),
  [JVM bytecode], [Primary — servers, data pipelines], [Spark, backends],
  [JavaScript], [Full-stack type safety], [Tyrian, Laminar],
  [Native (LLVM)], [System-level, native interop], [ScalaNative],
)

For this course: *JVM* — the runtime behind Spark, Kafka, and Flink.

== Scala and the JVM in distributed computing

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Framework*], [*Language*], [*What it does*]),
  [*Spark*], [Scala], [Distributed batch & SQL processing],
  [*Kafka*], [Scala], [Distributed event streaming],
  [*Akka / Pekko*], [Scala], [Actor-based distributed concurrency],
  [*Flink*], [Java (JVM)], [Stateful stream processing],
  [*Druid*], [Java (JVM)], [Real-time OLAP analytics],
  [*Trino / Presto*], [Java (JVM)], [Federated SQL query engine],
)

#pause

The JVM is the de facto runtime for distributed data infrastructure. \
Scala gives you the best API to program on top of it.

== Why Scala for distributed systems?

#table(
  columns: 2,
  align: (left, left),
  table.header([*Distributed need*], [*Scala answer*]),
  [Ship code to data nodes], [Functions are serializable values],
  [No shared mutable state], [Immutability by default],
  [Retry failed tasks safely], [Pure functions — same input, same output],
  [Express data pipelines], [Collection API: `map`, `filter`, `reduce`, `groupBy`],
  [Type-safe serialization], [Case classes with structural equality],
)

#pause

Spark's API _is_ Scala's collection API, running on a cluster.
