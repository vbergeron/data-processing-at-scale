#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Advanced Operators

== Where to place logic

Flink operator class names are built from *adjectives* that compose independently.

#table(
  columns: (auto, 1fr),
  [*Adjective*], [*What it adds*],
  [_(none)_], [Stateless transformation — `MapFunction`, `FlatMapFunction`, `FilterFunction`],
  [*`Rich`*], [`open()` / `close()` lifecycle — one-time initialisation (DB pool, ML model, config)],
  [*`Keyed`*], [Access to per-key state (`ValueState`, `ListState`, `MapState`) and event-time timers],
  [*`Co`*], [Two input streams joined at the operator level — both sides share the same state],
  [*`Broadcast`*], [One input is replicated to every parallel sub-task — used for shared rules or config],
)

#v(0.6em)

The adjectives stack: `KeyedBroadcastProcessFunction` = *Keyed* (per-key state) + *Broadcast* (shared config) + `ProcessFunction` (timers, side outputs).

There is no fixed list of combinations — `Rich` applies to any function, `Co` and `Broadcast` each add an input. Read the class name and you know exactly which capabilities are in scope.

== Timers in KeyedProcessFunction

```scala
class InactivityAlert extends KeyedProcessFunction[String, Trade, Alert] {
  lazy val lastSeen: ValueState[Long] =
    getRuntimeContext.getState(new ValueStateDescriptor("lastSeen", classOf[Long]))

  override def processElement(t: Trade, ctx: Context, out: Collector[Alert]): Unit =
    lastSeen.update(ctx.timestamp())
    ctx.timerService().registerEventTimeTimer(ctx.timestamp() + 5.minutes.toMillis)

  override def onTimer(ts: Long, ctx: OnTimerContext, out: Collector[Alert]): Unit =
    if ts == lastSeen.value() + 5.minutes.toMillis then
      out.collect(Alert(ctx.getCurrentKey, ts))
}
```

- `registerEventTimeTimer(t)` — fires when the watermark advances past `t`
- `registerProcessingTimeTimer(t)` — fires at wall-clock time; not reproducible on replay
- Timers are checkpointed and survive failures

== Serialization

Flink serializes records in two places: *between operators* (network shuffle) and *into checkpoints* (state). Getting it wrong costs performance or breaks savepoint compatibility.

Flink resolves a `TypeInformation` for every stream at compile time. Four tiers, in preference order:

#table(
  columns: (auto, 1fr, 1fr),
  [*Tier*], [*When*], [*Trade-off*],
  [Flink native], [Primitives, strings, arrays, tuples], [Fastest — zero-copy, no heap allocation],
  [POJO / case class], [All fields public or getter+setter, no-arg constructor], [Efficient field-level serialization; schema evolution supported],
  [Avro / Protobuf], [Explicit annotation or registration], [Schema evolution + cross-language interop],
  [Kryo fallback], [Type not recognised], [Works, but slow — disables optimisations and breaks savepoints],
)

#v(0.4em)

- *Diagnose Kryo at startup* — Flink logs a warning for every Kryo fallback. Treat these as errors in production.
- *Schema evolution* — adding a field to a POJO or Avro type is safe; removing or renaming breaks savepoint deserialisation. Kryo has no schema at all.

== Async I/O

Enriching a stream with an external call (HTTP, DB) synchronously stalls the sub-task for every record. `AsyncDataStream` pipelines multiple requests concurrently.

```scala
class AsyncPriceEnricher extends RichAsyncFunction[Trade, EnrichedTrade] {
  override def asyncInvoke(trade: Trade, result: ResultFuture[EnrichedTrade]): Unit =
    priceService.getAsync(trade.symbol).thenAccept { price =>
      result.complete(List(trade.enrich(price)).asJava)
    }
}

AsyncDataStream.unorderedWait(
  trades,
  new AsyncPriceEnricher(),
  1000, TimeUnit.MILLISECONDS, // per-record timeout
  100                          // max concurrent requests
)
```

- `unorderedWait` — results emitted as soon as ready; maximum throughput
- `orderedWait` — results emitted in input order; higher latency

== Broadcast state

Broadcast solves a specific problem: you have a stream of *events* (high-volume, partitioned) and a stream of *rules or config* (low-volume, changes rarely) that every sub-task needs a full copy of.

#align(center,
  fletcher.diagram(
    spacing: (3cm, 0.9cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), [Events \ (partitioned)], fill: rgb("#e3f2fd"), width: 3cm, inset: 8pt),
    node((0, 1), [Config / rules \ (broadcast)], fill: rgb("#fff3e0"), width: 3cm, inset: 8pt),
    node((1, 0), [sub-task 0 \ state: full config], fill: rgb("#e8f5e9"), width: 3.2cm, inset: 8pt),
    node((1, 1), [sub-task 1 \ state: full config], fill: rgb("#e8f5e9"), width: 3.2cm, inset: 8pt),
    edge((0,0),(1,0), "->"),
    edge((0,0),(1,1), "->"),
    edge((0,1),(1,0), "->", stroke: (dash: "dashed")),
    edge((0,1),(1,1), "->", stroke: (dash: "dashed")),
  )
)

```scala
val configDescriptor = new MapStateDescriptor(
  "account-config", classOf[AccountId], classOf[AccountConfig]
)
val broadcastConfig = configStream.broadcast(configDescriptor)

eventStream
  .connect(broadcastConfig)
  .process(new AccountMatchProcessor())
```

- `processBroadcastElement` — updates `BroadcastState`; called on config changes
- `processElement` — reads `BroadcastState`; called for every event

== Keyed broadcast state

`KeyedBroadcastProcessFunction` adds *keyed state* on top of broadcast — each sub-task has both a full copy of the config and per-key state for the events it owns.

```scala
eventStream
  .keyBy(_.accountId)           // partition events by account
  .connect(broadcastConfig)
  .process(new NotificationProcessor())
```

Inside `NotificationProcessor`:
- `processBroadcastElement` — updates shared `BroadcastState` (config for all accounts)
- `processElement` — reads `BroadcastState` *and* keyed `ValueState` / `MapState` (state specific to this account)

This is the pattern used in chainwatch: `CommandRequest` messages are broadcast to all sub-tasks; `BlockEvent` records are keyed by `accountId`, so per-account state stays local.

#text(size: 9pt, fill: luma(120))[Note: in `processBroadcastElement`, keyed state is *read-only*. Write only from the keyed side.]

== Testing operators — the harness

Unit-test a Flink operator in plain JUnit/munit with no cluster. The test harness wraps the operator, controls watermarks, and captures outputs.

```scala
// KeyedCoProcessFunction (two keyed inputs)
val harness = new KeyedTwoInputStreamOperatorTestHarness(
  new KeyedCoProcessOperator(new NotificationProcessor()),
  (e: BlockEvent.Matched) => e.account.id,
  (c: CommandRequest)     => c.account.id,
  TypeInformation.of(classOf[Account.ID])
)
harness.open()
harness.processElement1(StreamRecord(blockEvent))
harness.processElement2(StreamRecord(commandRequest))
harness.processWatermark(new Watermark(ts))   // advance event time, fire timers

val out  = harness.extractOutputValues().asScala
val late = harness.getSideOutput(lateTag).asScala
```

For `BroadcastProcessFunction`, use `TwoInputStreamOperatorTestHarness` wrapping `CoBroadcastWithNonKeyedOperator` — same push/extract pattern, no key selector needed.

== Testing operators — MiniCluster

For integration tests that need a full topology (source → operators → sink) or to verify checkpoint-restore behaviour, use `MiniCluster` — runs inside the JVM, no Docker.

```scala
//> using dep org.apache.flink:flink-test-utils:2.2.0

val env = StreamExecutionEnvironment.createLocalEnvironment(parallelism = 2)
env.enableCheckpointing(500)

val source = env.fromCollection(testEvents)
val result = CollectSink.values  // thread-safe static collector

source
  .keyBy(_.userId)
  .process(new CountPerUser())
  .addSink(new CollectSink())

env.execute()
assertEquals(result.toSet, expected)
```

Use the harness for *operator logic* (fast, deterministic, no I/O). Use MiniCluster for *topology correctness* — parallelism effects, serialisation round-trips, checkpoint round-trips. Keep MiniCluster tests in a separate module; they are 10–100× slower.
