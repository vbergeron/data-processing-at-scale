#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

== Bounded vs unbounded

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *Bounded* — a finite dataset \
      #v(0.5em)
      A file, a table snapshot, a CSV export. \
      You know where it ends before you start. \
      Processing terminates and produces a final result.
    ],
    [
      *Unbounded* — an infinite dataset \
      #v(0.5em)
      A live event feed, a sensor stream, a log tail. \
      There is no last record to wait for. \
      Results must be emitted continuously as data arrives.
    ],
  )
)

#v(1em)

The shift to streaming is a *semantic* choice — it changes when results are needed, not just how fast they are produced.

== Batch → micro-batch → streaming

#align(center,
  fletcher.diagram(
    spacing: (3.5cm, 0pt),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 0), [*Batch* \ #text(size: 10pt, fill: luma(120))[hours]], fill: rgb("#e3f2fd"), width: 4.5cm, inset: 14pt),
    node((1, 0), [*Micro-batch* \ #text(size: 10pt, fill: luma(120))[seconds]], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),
    node((2, 0), [*Streaming* \ #text(size: 10pt, fill: luma(120))[milliseconds]], fill: rgb("#e8f5e9"), width: 4.5cm, inset: 14pt),
    edge((0,0),(1,0), "->"),
    edge((1,0),(2,0), "->"),
  )
)

#v(0.8em)

The trigger model sets a hard floor on achievable latency. No optimizer can reduce it below this value.

- *Batch*: scheduled jobs, MapReduce, Spark in batch mode
- *Micro-batch*: Spark Structured Streaming with timed triggers
- *Streaming*: Apache Flink, event-at-a-time with low-latency watermarks

== Backpressure

*Backpressure* is how a slow consumer signals upstream producers to slow down.

#align(center,
  grid(
    columns: (auto, auto, auto, auto, auto),
    column-gutter: 0.4cm,
    align: horizon,
    [Source], [$→$], rect(fill: rgb("#fff3e0"), inset: 8pt)[Op A \ ✓ fast], [$→$], rect(fill: rgb("#fce4ec"), inset: 8pt)[Op B \ ✗ slow],
  )
)

#v(0.8em)

Three strategies when a consumer can't keep up:

- *Drop*: discard excess records — data loss, at-most-once
- *Block*: pause the producer — safe, but stalls the whole pipeline
- *Buffer*: absorb bursts in a queue — useful for spikes, not sustained overload

Flink uses credit-based blocking — no separate signaling, pressure propagates through the network buffer layer.

== Credit-based flow control

Each downstream input channel has a fixed pool of buffers. The receiver grants one *credit* per free buffer slot. The sender can only transmit as many records as it holds credits.

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.5cm,
    align: top + center,
    [
      *Buffer has space — flowing*
      #v(0.5em)
      #fletcher.diagram(
        spacing: (2.2cm, 0.8cm),
        node-stroke: 0.8pt,
        node-corner-radius: 4pt,
        node((0, 0), [Sender], width: 2cm, inset: 8pt),
        node((1, 0), [#text(size: 9pt)[□ □ ■ ■]], fill: rgb("#e8f5e9"), width: 2cm, inset: 8pt),
        edge((0,0),(1,0), "->", label: text(size: 9pt)[data]),
        edge((1,0),(0,0), "->", bend: 40deg, label: text(size: 9pt)[2 credits]),
      )
    ],
    [
      *Buffer full — blocked*
      #v(0.5em)
      #fletcher.diagram(
        spacing: (2.2cm, 0.8cm),
        node-stroke: 0.8pt,
        node-corner-radius: 4pt,
        node((0, 0), [Sender], width: 2cm, inset: 8pt),
        node((1, 0), [#text(size: 9pt)[■ ■ ■ ■]], fill: rgb("#fce4ec"), width: 2cm, inset: 8pt),
        edge((0,0),(1,0), "--|>", label: text(size: 9pt)[blocked], stroke: (dash: "dashed")),
        edge((1,0),(0,0), "->", bend: 40deg, label: text(size: 9pt)[0 credits]),
      )
    ],
  )
)

#v(0.5em)

When the sender has no credits it blocks, its own input queue fills, and its upstream sender loses credits in turn — pressure propagates all the way back to the source with no dedicated signaling channel.

== Push vs pull

#align(center,
  grid(
    columns: (1fr, 1fr),
    column-gutter: 2cm,
    align: top,
    [
      *Push — forward chaining* \
      #v(0.5em)
      Source emits events as they occur. \
      Downstream operators react immediately. \
      #v(0.5em)
      Minimal latency. \
      Backpressure must be managed explicitly. \
      #v(0.5em)
      _Flink, Kafka consumers, Storm_
    ],
    [
      *Pull — backward chaining* \
      #v(0.5em)
      Downstream requests data when ready. \
      Upstream responds on demand. \
      #v(0.5em)
      Natural backpressure — consumer sets pace. \
      Higher latency — no data until asked. \
      #v(0.5em)
      _Spark, SQL query engines_
    ],
  )
)

== Monotonic computations

A computation is *monotonic* if adding more input can only extend the output — never retract or correct a previously produced result.

#table(
  columns: (1fr, 1fr),
  [*Monotonic*], [*Non-monotonic*],
  [`COUNT(*)` — count only increases], [`AVG()` — can decrease with new data],
  [Set union — elements only added], [Set membership deletion],
  [`MAX`, `MIN` on append-only sources], [Median — can shift in either direction],
)

Monotonicity is the key to distribution: a monotonic computation converges to the correct result regardless of message arrival order.

== The CALM Theorem

*Consistency As Logical Monotonicity* — Hellerstein & Alvaro, 2010.

A program has a consistent, coordination-free distributed implementation *if and only if* it is monotone.

#table(
  columns: (1fr, 1fr),
  [*Monotonic → no coordination needed*], [*Non-monotonic → coordination required*],
  [Nodes may diverge temporarily, but will converge], [Nodes can produce permanently wrong results without sync],
  [`COUNT`, `UNION`, `MAX`], [`DELETE`, `UPDATE`, `AVERAGE`],
)

Design insight: encode non-monotonic intent as monotonic operations. A delete becomes an insert into a tombstone set. A correction becomes a versioned record.

== Idempotency & determinism

Two properties that make distributed pipelines safe to retry.

*Idempotent*: applying the same operation multiple times produces the same result as applying it once.

#v(0.3em)
_"Write key K = V" is idempotent. "Increment counter by 1" is not._

#v(0.6em)

*Deterministic*: given the same input, always produces the same output.

#v(0.3em)
_"Filter events where amount > 100" is deterministic. "Filter events from the last 5 seconds of wall-clock time" is not._

#v(0.6em)

Both properties enable fault tolerance: a failed task can be retried or replayed from a checkpoint without corrupting downstream state.

== Delivery guarantees

#table(
  columns: (auto, 1fr, 1fr),
  [*Guarantee*], [*Meaning*], [*Cost & use case*],
  [At-most-once], [Events may be lost, never duplicated], [No retries — metrics, monitoring, lossy telemetry],
  [At-least-once], [Events may be duplicated, never lost], [Retries on failure — requires idempotent consumers],
  [Exactly-once], [Effect applied exactly once, end-to-end], [Coordination overhead — checkpoints, transactions],
)

#v(0.5em)

"Exactly-once" does not mean an event is *processed* once. It means the *effect on downstream state* is applied once — achieved via idempotent sinks or two-phase commit, not by preventing retries.

== The problem of time

Streaming data has two notions of time that are almost never the same.

#table(
  columns: (1fr, 1fr),
  [*Event time*], [*Processing time*],
  [When the event *occurred* — embedded in the record], [When the event *arrived* at the processor — wall clock],
  [Correct for business logic \ ("all orders before midnight")], [Simpler — no out-of-order records],
  [Requires watermarks to know when a window is complete], [No special mechanism needed],
  [Reproducible on replay], [Different result on replay],
)

#v(0.5em)

Network delays, retries, and mobile clients cause events to arrive *out of order*. A purchase made at 23:59 may arrive at the processor at 00:03. Processing time would assign it to the wrong day.

== Windows

Aggregating an infinite stream requires bounding it into finite chunks — *windows*.

Without windows, a `COUNT(*)` on an unbounded stream never terminates. Windows let you ask: "how many events in the last minute?" instead of "how many events ever?"

#table(
  columns: (auto, 1fr),
  [*Type*], [*Definition*],
  [Tumbling], [Fixed size, no overlap — each event belongs to exactly one window],
  [Sliding], [Fixed size, fixed slide interval — events can belong to multiple windows],
  [Session], [Gap-based — window closes after a period of inactivity per key],
)

== Tumbling windows

#align(center, image("../assets/tumbling-windows.svg", width: 90%))

== Sliding windows

#align(center, image("../assets/sliding-windows.svg", width: 90%))

== Session windows

#align(center, image("../assets/session-windows.svg", width: 90%))

== Watermarks

On a finite dataset, you know when you've seen all the data. On a stream, you never do. A *watermark* is the system's best estimate: "all events with timestamp $t < W$ have now arrived."

#align(center,
  grid(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    column-gutter: 0.3cm,
    align: horizon + center,
    rect(fill: rgb("#e3f2fd"), inset: 6pt)[t=1],
    rect(fill: rgb("#e3f2fd"), inset: 6pt)[t=4],
    rect(fill: rgb("#e3f2fd"), inset: 6pt)[t=7],
    rect(fill: rgb("#fce4ec"), inset: 6pt)[t=3 \ _late_],
    rect(fill: rgb("#e3f2fd"), inset: 6pt)[t=9],
    rect(fill: rgb("#e3f2fd"), inset: 6pt)[t=11],
    [→],
  )
)

#v(0.5em)

The watermark advances as: $W = max("observed event time") - "tolerated lag"$.

When the watermark passes the end of a window, the window is *closed* and its result emitted. The tolerated lag is a tunable trade-off:

- Larger lag → more late events captured, higher result latency, more state held
- Smaller lag → lower latency, more events dropped as late
