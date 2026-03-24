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

Keyed state is the common case. Each key's state lives on the sub-task that owns that key — never a remote lookup.

== State backends

Flink stores in-flight state in a pluggable *state backend*:

#table(
  columns: (1fr, 1fr),
  [*HashMapStateBackend*], [*EmbeddedRocksDBStateBackend*],
  [JVM heap — state as Java objects], [Local disk + block cache (RocksDB)],
  [Fast random access], [~5–10× slower reads; incremental checkpoints],
  [Limited by heap; GC pressure at scale], [State can exceed available RAM],
  [Default for development], [Default for production at scale],
)

`MapState` with RocksDB stores each map entry as a separate RocksDB key — only the accessed entry is deserialised. With `HashMapStateBackend` the entire map is deserialised on every access.


== ValueState

A single typed cell per key. The simplest and most common state primitive.

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

- `.value()` — reads current value; returns `null` if uninitialised
- `.update(v)` — writes a new value
- `.clear()` — deletes the cell (frees memory; TTL can also do this automatically)

== ListState

An ordered list of values per key. Flink serialises the list efficiently — no need to read-modify-write the full list for append-only patterns.

```scala
lazy val buffer: ListState[Event] =
  getRuntimeContext.getListState(
    new ListStateDescriptor("buffer", classOf[Event])
  )

// append without reading the full list
buffer.add(event)

// read all buffered events for this key
buffer.get().asScala.foreach(process)

// replace the entire list
buffer.update(newList.asJava)
```

Use case: buffer events within a custom window, then emit when a timer fires.

== MapState

A key→value map per Flink key. Avoids deserialising the full structure when you only need one entry.

```scala
lazy val positions: MapState[String, Long] =
  getRuntimeContext.getMapState(
    new MapStateDescriptor("positions", classOf[String], classOf[Long])
  )

// per-symbol net quantity inside a per-user keyed operator
val qty = Option(positions.get(symbol)).getOrElse(0L)
positions.put(symbol, qty + delta)
```

- `.get(k)` — point lookup; returns `null` if absent
- `.put(k, v)`, `.remove(k)`, `.contains(k)`, `.entries()` — standard map operations
- With RocksDB backend, each entry is stored as a separate key — only the accessed entry is deserialised

Use case: per-user portfolio positions (`userId` → `Map(symbol → netQty)`).

== State TTL

Without expiry, state for inactive keys accumulates indefinitely. `StateTtlConfig` evicts entries automatically.

```scala
val ttl = StateTtlConfig
  .newBuilder(Time.hours(24))
  .setUpdateType(StateTtlConfig.UpdateType.OnCreateAndWrite)
  .setStateVisibility(StateTtlConfig.StateVisibility.NeverReturnExpired)
  .cleanupInBackground()
  .build()

val descriptor = new ValueStateDescriptor("count", classOf[Long])
descriptor.enableTimeToLive(ttl)
```

- `OnCreateAndWrite` — TTL resets on each `.update()` call; idle keys expire
- `NeverReturnExpired` — expired cells read as `null`, not stale data
- `cleanupInBackground()` — RocksDB compaction removes expired entries without a separate sweep

TTL is the primary defence against unbounded state growth in long-running jobs.

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

The JobManager injects a *checkpoint barrier* into each source stream. Barriers flow with data; when an operator has seen a barrier on *every* input it snapshots its state and forwards the barrier. On failure, Flink resets all operators to the last completed checkpoint and replays from there.

#text(size: 9pt, fill: luma(120))[Parallel inputs require barrier alignment — the operator buffers records from faster inputs until the barrier arrives on all channels, ensuring a globally consistent cut.]

== Savepoints vs checkpoints

#table(
  columns: (1fr, 1fr),
  [*Checkpoint*], [*Savepoint*],
  [Triggered automatically by Flink], [Triggered manually: `flink savepoint <jobId>`],
  [For failure recovery], [For deliberate lifecycle events],
  [Deleted when superseded], [Retained indefinitely — you manage them],
  [Opaque binary format], [Portable — survives operator reordering with stable UIDs],
)

== Zero-downtime upgrade with savepoints

+ Assign stable `uid`s to all operators: `.uid("window-agg")`
+ Trigger a savepoint: `flink savepoint <jobId>`
+ Cancel the job
+ Deploy the new version: `flink run --fromSavepoint <path>`

State is restored key-by-key; operators that no longer exist are ignored; new operators start with empty state.

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
