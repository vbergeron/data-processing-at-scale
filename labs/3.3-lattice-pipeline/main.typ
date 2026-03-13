#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 3.3 — Modeling a Pipeline as a Lattice],
  session: [Session 3.3 — Data Pipelines: Theory & Reasoning],
  format: [Instructor-led hands-on demo],
  tools: [Python, whiteboard/slides for diagrams],
)

= Objective

Make the CALM theorem and lattice-based reasoning concrete by building a small distributed pipeline where state converges without coordination, then showing a case where it doesn't.

= Setup

- A Python simulation of distributed nodes exchanging messages
- Each node maintains local state using lattice-based data structures
- Configurable message delays and reordering to simulate network non-determinism

= Walkthrough

== Step 1 — A convergent counter (GCounter)

Implement a grow-only counter as a lattice:
- 3 nodes, each incrementing its own slot in a vector
- Nodes periodically gossip their state to peers
- Merge operation: element-wise `max`
- Reorder messages, delay them, duplicate them — the final count is always correct
- Show: this is monotonic (the count only goes up) → no coordination needed

== Step 2 — A convergent set (GSet)

Implement a grow-only set:
- Nodes add elements locally, gossip to peers
- Merge: set union
- Same message chaos — the sets converge
- Show: union is monotonic, so CALM guarantees coordination-freedom

== Step 3 — Where monotonicity breaks (set with deletes)

Try to add a `remove` operation:
- Naive approach: remove from the local set
- Gossip brings the element back (another node hasn't seen the delete)
- Show the anomaly live: a "zombie" element keeps reappearing
- This is non-monotonic — CALM says we _need_ coordination

== Step 4 — Fixing it with a lattice (OR-Set / 2P-Set)

Implement a 2P-Set (two grow-only sets: additions and tombstones):
- Deletes become monotonic additions to the tombstone set
- Merge: union both sets, effective set = additions − tombstones
- Show: convergence is restored, no coordination needed
- Discuss the trade-off: tombstones grow forever

== Step 5 — Mapping to real systems

Connect the theory back to the course:
- Kafka offsets: a monotonically advancing high-water mark (lattice!)
- Spark accumulators: associative, commutative merge
- ClickHouse ReplacingMergeTree: last-write-wins is a lattice on timestamps
- Flink checkpoints: snapshot state at a consistent cut across the lattice of event time

= Key Takeaways

- If your computation is monotonic, it can run without coordination — the CALM theorem
- Lattice merge (join) gives you convergence for free: any message order produces the same result
- Non-monotonic operations (delete, revoke, negate) require either coordination or clever encoding
- CRDTs are lattices designed for practical use — they encode non-monotonic intent as monotonic structure
- This framework explains _why_ certain distributed systems work and others need consensus
