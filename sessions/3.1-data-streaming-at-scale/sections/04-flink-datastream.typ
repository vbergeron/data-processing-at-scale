#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Apache Flink

== Apache Flink

#align(center + horizon, image("../assets/flink-logo.png", width: 35%))

== Architecture

#align(center, image("../assets/flink-processes.svg", width: 70%))

== DataStream API

A Flink job is a *graph of operators* connected by data streams.

```scala
val env = StreamExecutionEnvironment.getExecutionEnvironment

val events: DataStream[Event] = env
  .fromSource(fileSource, WatermarkStrategy.noWatermarks(), "events")

events
  .filter(_.amount > 0)
  .keyBy(_.userId)
  .process(new CountPerUser())
  .print()

env.execute("user-count")
```

Nothing runs until `env.execute()` — Flink builds a job graph first, then submits it to the JobManager.

== keyBy — partitioning a stream

`keyBy` hashes each record to a logical key and routes it to the sub-task responsible for that key.

#align(center,
  fletcher.diagram(
    spacing: (3cm, 0.7cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), [Source \ sub-task 0], fill: rgb("#e3f2fd"), width: 2.8cm, inset: 8pt),
    node((0, 1), [Source \ sub-task 1], fill: rgb("#e3f2fd"), width: 2.8cm, inset: 8pt),
    node((1, 0), [Process \ key A, C], fill: rgb("#e8f5e9"), width: 2.8cm, inset: 8pt),
    node((1, 1), [Process \ key B, D], fill: rgb("#e8f5e9"), width: 2.8cm, inset: 8pt),
    edge((0,0),(1,0), "->"),
    edge((0,0),(1,1), "->"),
    edge((0,1),(1,0), "->"),
    edge((0,1),(1,1), "->"),
  )
)

All records with the same key land on the same sub-task — state for that key is always local, never remote. `keyBy` is the Flink equivalent of a shuffle, but records continue flowing without materializing to disk.

== Watermark strategy

Before windowing, Flink needs to know *which field carries the event timestamp* and *how much out-of-order lag to tolerate*.

```scala
val strategy = WatermarkStrategy
  .forBoundedOutOfOrderness[Event](Duration.ofSeconds(5))
  .withTimestampAssigner((event, _) => event.ts)

val timestamped = events.assignTimestampsAndWatermarks(strategy)
```

- `forBoundedOutOfOrderness(d)` — advances the watermark to `max(seen_ts) - d`; records older than the watermark are considered late
- `withTimestampAssigner` — extracts the event-time field from each record
- A larger `d` → more correct results (fewer late records dropped), but higher latency

== Windowed aggregation

With timestamps assigned, attach a window and an aggregation function.

```scala
timestamped
  .keyBy(_.userId)
  .window(TumblingEventTimeWindows.of(Time.minutes(1)))
  .aggregate(new SumAggregator())
```

- `.keyBy` — routes each record to the sub-task that owns its key (state stays local)
- `.window(...)` — choose the assigner: `TumblingEventTimeWindows`, `SlidingEventTimeWindows`, or `EventTimeSessionWindows`
- `.aggregate` / `.process` — called once per closed window; result flows downstream

== Allowed lateness

The watermark closes a window — but late records can still trickle in. `.allowedLateness` keeps the window accumulator alive for a grace period and *re-emits* an updated result for each late arrival.

```scala
timestamped
  .keyBy(_.userId)
  .window(TumblingEventTimeWindows.of(Time.minutes(1)))
  .allowedLateness(Time.seconds(30))
  .sideOutputLateData(lateTag)
  .aggregate(new SumAggregator())
```

Two independent knobs:

#table(
  columns: (1fr, 1fr),
  [*Watermark lag*], [*Allowed lateness*],
  [How long before the window closes], [How long after closing to accept corrections],
  [Controls first-result latency], [Controls correction window],
  [Records inside lag → included], [Records inside lateness → trigger re-emit],
)

After allowed lateness expires, any further late record goes to the *side output* — never silently dropped.

== Side outputs

A side output is a secondary typed stream branching off any operator. The main path is unaffected.

```scala
val lateTag = OutputTag[Trade]("late-trades")

val result = trades
  .keyBy(_.symbol)
  .window(TumblingEventTimeWindows.of(Time.minutes(1)))
  .allowedLateness(Time.seconds(30))
  .sideOutputLateData(lateTag)
  .aggregate(new NotionalAggregator())

// Main output — on-time aggregated results
result.addSink(mainSink)

// Side output — truly late records, routed separately
result.getSideOutput(lateTag).addSink(lateAuditSink)
```

Side outputs are not limited to late data. Any `ProcessFunction` or `KeyedProcessFunction` can call `ctx.output(tag, value)` to split a stream by any condition — invalid records, high-value alerts, debug traces — without forking the pipeline.

== Flink SQL

The DataStream API and Flink SQL compile to the same execution graph.

```sql
CREATE TABLE events (
  user_id STRING,
  amount  DOUBLE,
  ts      TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH ('connector' = 'filesystem', 'path' = 'data/input/', 'format' = 'json');

SELECT user_id, COUNT(*) AS cnt
FROM events
GROUP BY user_id, TUMBLE(ts, INTERVAL '1' MINUTE);
```

== DataStream API vs Flink SQL

#table(
  columns: (1fr, 1fr),
  [*DataStream API*], [*Flink SQL*],
  [Full control over operators and state], [Declarative — less code, same optimizer],
  [Custom `ProcessFunction`, side outputs], [Limited to what SQL can express],
  [Required for complex CEP and graph algorithms], [Preferred for joins, aggregations, projections],
)
