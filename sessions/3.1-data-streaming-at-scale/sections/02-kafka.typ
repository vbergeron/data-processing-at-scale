#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Kafka Recap

== Topics, partitions, offsets

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 0.7cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,
    node((0, 1), [*Topic*], width: 2cm, inset: 10pt),
    node((1, 0), [*P0* \ #text(size: 9pt)[0 · 1 · 2 · 3 · …]], fill: rgb("#e3f2fd"), width: 3cm, inset: 10pt),
    node((1, 1), [*P1* \ #text(size: 9pt)[0 · 1 · 2 · 3 · …]], fill: rgb("#e3f2fd"), width: 3cm, inset: 10pt),
    node((1, 2), [*P2* \ #text(size: 9pt)[0 · 1 · 2 · 3 · …]], fill: rgb("#e3f2fd"), width: 3cm, inset: 10pt),
    node((2, 0), [Consumer A], fill: rgb("#e8f5e9"), width: 3cm, inset: 8pt),
    node((2, 1), [Consumer B], fill: rgb("#e8f5e9"), width: 3cm, inset: 8pt),
    node((2, 2), [Consumer C], fill: rgb("#e8f5e9"), width: 3cm, inset: 8pt),
    edge((0,1),(1,0), "->"),
    edge((0,1),(1,1), "->"),
    edge((0,1),(1,2), "->"),
    edge((1,0),(2,0), "->"),
    edge((1,1),(2,1), "->"),
    edge((1,2),(2,2), "->"),
  )
)

Each partition is an ordered, immutable log. Ordering is guaranteed *within a partition*, not across partitions. One consumer per group reads each partition — this is the unit of parallelism scaling.

== The offset contract

The *offset* is a monotonically increasing integer that identifies each record within a partition.

- Producers append records; the broker assigns the next offset
- Consumers track their position by committing the last-read offset
- On restart, a consumer resumes from its committed offset

Delivery guarantees come from *when* the offset is committed:

- Commit *before* processing → at-most-once (may lose the record if the consumer crashes)
- Commit *after* processing → at-least-once (may reprocess if committed offset is lost)
- Commit *atomically with output* → effectively exactly-once (requires idempotent producers + transactional API)

== What Kafka does not do

Kafka guarantees *durability* and *ordering within a partition*. It does not:

- Transform events
- Join two streams
- Aggregate over time windows
- Track event-time watermarks
- Maintain keyed state across events

These are the responsibilities of a *stream processing framework* that sits downstream of Kafka. The rest of this session is about what those frameworks add.
