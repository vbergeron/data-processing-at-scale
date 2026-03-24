#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Flink State & Fault Tolerance

== Keyed state vs operator state

State in Flink is always scoped to an operator instance.

#table(
  columns: (auto, 1fr, 1fr),
  [*Type*], [*Scope*], [*Use case*],
  [Keyed state], [One cell per key, per sub-task. Requires `keyBy`.], [Per-user counts, running totals, session tracking],
  [Operator state], [One cell per sub-task. No key required.], [Kafka partition offsets, broadcast config],
)

#v(0.6em)

Keyed state is the common case. Each key's state lives on the sub-task that owns that key — never a remote lookup. Session 3.2 covers state backends and advanced patterns in depth.

== Keyed state in code

```scala
class CountPerUser extends KeyedProcessFunction[String, Event, String] {
  lazy val count: ValueState[Long] = getRuntimeContext
    .getState(new ValueStateDescriptor("count", classOf[Long]))

  override def processElement(e: Event, ctx: Context, out: Collector[String]): Unit = {
    val c = Option(count.value()).getOrElse(0L) + 1
    count.update(c)
    out.collect(s"${e.userId}: $c")
  }
}
```

- `ValueState[T]` — a single mutable cell per key
- `getRuntimeContext.getState(...)` — registers the state with Flink so it is included in checkpoints
- State survives failures: on recovery Flink restores the cell to its last checkpointed value

== State backends

Flink stores in-flight state in a pluggable *state backend*:

#table(
  columns: (1fr, 1fr),
  [*HashMapStateBackend*], [*EmbeddedRocksDBStateBackend*],
  [JVM heap — state as Java objects], [Local disk + block cache (RocksDB)],
  [Fast; limited by heap size], [Unbounded state; ~5–10× slower reads],
  [Default for development], [Default for production at scale],
)

Switch to RocksDB when state exceeds available heap, or when you need incremental checkpoints.

== Fault tolerance

Flink periodically takes a *consistent snapshot* of all operator state — a *checkpoint*.

#align(center,
  fletcher.diagram(
    spacing: (2.8cm, 0.8cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 1), [Source], fill: rgb("#e3f2fd"), width: 2cm, inset: 8pt),
    node((1, 1), [Op A], fill: rgb("#fff3e0"), width: 2cm, inset: 8pt),
    node((2, 0), [Op B], fill: rgb("#fff3e0"), width: 2cm, inset: 8pt),
    node((2, 2), [Op C], fill: rgb("#fff3e0"), width: 2cm, inset: 8pt),
    node((3, 1), [Sink], fill: rgb("#e8f5e9"), width: 2cm, inset: 8pt),
    edge((0,1),(1,1), "->", label: text(size: 9pt)[barrier ▶]),
    edge((1,1),(2,0), "->"),
    edge((1,1),(2,2), "->"),
    edge((2,0),(3,1), "->"),
    edge((2,2),(3,1), "->"),
  )
)

The JobManager injects a *checkpoint barrier* into each source stream. Barriers flow with data; when an operator has seen a barrier on every input it snapshots its state and forwards the barrier. On failure, Flink resets all operators to the last completed checkpoint and replays from there.

== Exactly-once semantics

Checkpointing gives exactly-once for *internal state*. Making the *output* exactly-once requires sink cooperation.

#align(center,
  fletcher.diagram(
    spacing: (3cm, 0pt),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), [Kafka \ source], fill: rgb("#e3f2fd"), width: 3cm, inset: 10pt),
    node((1, 0), [Flink \ operators], fill: rgb("#fff3e0"), width: 3cm, inset: 10pt),
    node((2, 0), [Kafka \ sink], fill: rgb("#e8f5e9"), width: 3cm, inset: 10pt),
    edge((0,0),(1,0), "->"),
    edge((1,0),(2,0), "->"),
  )
)

- Source offsets are saved in the checkpoint — replay starts from the right position
- The Kafka sink uses *two-phase commit*: output is written in a transaction and committed only when the checkpoint succeeds
- Result: every record affects the sink *exactly once*, even across failures
