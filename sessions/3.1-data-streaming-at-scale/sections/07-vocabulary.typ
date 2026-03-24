#import "../../style.typ": hero

= Wrap-Up

== Key vocabulary

#table(
  columns: (auto, 1fr),
  [*Term*], [*Definition*],
  [Unbounded dataset], [A data source with no defined end — events arrive continuously],
  [Micro-batch], [Collect records over a time interval, then process as a mini-batch (Spark model)],
  [Push / pull], [Push: upstream emits when data arrives. Pull: downstream requests when ready.],
  [Monotonic], [A computation whose output only grows as input grows — can be distributed without coordination],
  [CALM theorem], [A program is consistent without coordination if and only if it is monotone],
  [Idempotent], [Applying the same operation multiple times produces the same result as once],
  [Event time], [When an event *occurred*, embedded in the record — correct basis for aggregations],
  [Processing time], [When an event *arrived* at the processor — wall clock, simpler but not reproducible],
  [Watermark], [A signal that all events with timestamp $t < W$ have arrived; advances event-time progress],
  [keyBy], [Routes records with the same key to the same sub-task — enables co-located keyed state],
  [Keyed state], [State scoped to a key within an operator sub-task; always local, never remote],
  [Allowed lateness], [Grace period after a window closes during which late records still update the result],
  [OutputTag], [A typed label for a side output stream — used to route late or exceptional records],
  [State TTL], [Automatic expiry of idle state entries; prevents unbounded state growth],
  [Checkpoint barrier], [A marker injected into the data stream to trigger consistent state snapshots],
  [Savepoint], [A user-triggered, portable checkpoint used for job upgrades and migrations],
  [Exactly-once], [The effect on downstream state is applied once — not a guarantee against retries],
  [Backpressure], [Upstream slows when downstream cannot keep up — propagated through network buffers],
  [Broadcast state], [A copy of a stream sent to every sub-task — used for shared config or rules],
  [AsyncDataStream], [Pipelines multiple async external calls concurrently to avoid blocking sub-tasks],
  [Test harness], [An in-JVM wrapper around a Flink operator for unit testing without a cluster],
)

== One sentence to remember

A streaming system is correct when it produces the same answer regardless of *when* events arrive — and the tools for that are event time, watermarks, and state backed by durable checkpoints.
