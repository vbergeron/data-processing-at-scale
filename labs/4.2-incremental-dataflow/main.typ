#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 4.2 — Incremental Computation: From Recomputation to Deltas],
  session: [Session 4.2 — Differential Dataflow & Incremental Computation],
  format: [Instructor-led hands-on demo],
  tools: [Python],
)

= Objective

Build a small incremental computation engine in Python that maintains a materialized view by processing deltas instead of recomputing from scratch. Show when incremental maintenance is correct by construction, and when it requires care.

= Setup

- Pure Python — no external libraries
- A simulated event log (user actions with timestamps) that grows over time
- Three materialized views to maintain: a count, a top-K, and a join

= Walkthrough

== Step 1 — The cost of recomputation

Start with a naive approach:
- A table of 1M user events
- Three analytics queries: count per user, top-10 users by activity, user-event joined with a dimension table
- Append 1,000 new events. Recompute all three queries from scratch.
- Measure: recomputation time is proportional to total data, not to the change size
- This is the baseline to beat

== Step 2 — Modeling changes as (data, diff) pairs

Introduce the core abstraction:
- Each change is a `(record, +1)` for an insert or `(record, -1)` for a delete
- An update is a delete followed by an insert: `(old_record, -1), (new_record, +1)`
- Show that a batch of changes can be compacted: `(A, +1), (A, -1)` cancels out
- Implement a `DiffCollection` class that stores `{record: diff_count}`

== Step 3 — Incremental count (a monotonic case)

Maintain a per-user count incrementally:
- On `(user, +1)`: increment the user's count
- On `(user, -1)`: decrement the user's count
- Process the 1,000-event delta: update only the affected users
- Verify: incremental result == full recomputation result
- Show: count is a group homomorphism — `count(A ∪ B) = count(A) + count(B)` — so incremental maintenance is correct by construction
- Connect to Day 3: this is a lattice merge when restricted to inserts

== Step 4 — Incremental top-K (a non-monotonic case)

Maintain the top-10 users by activity count:
- When a user's count changes, they might enter or leave the top-10
- Show: a new event for user \#50 can displace user \#10 — the top-K output is non-monotonic even if the input is insert-only
- Implement the incremental update: maintain a sorted structure, re-rank only affected users
- Show the edge case: two users tied at the boundary. Arrival order matters.
- Connect to CALM: non-monotonic output from monotonic input — the top-K operator is the coordination point

== Step 5 — Incremental join

Maintain a join between the event stream and a slowly-changing dimension table:
- New events: probe the dimension table, emit joined rows
- Dimension change (e.g., user changes city): retract all old joined rows, re-emit with new dimension value
- Implement using `(record, diff)` pairs flowing through both sides
- Show: this is differential dataflow's `join` operator — it processes deltas from both inputs
- Measure: incremental join on 1,000 new events vs re-joining 1M rows

== Step 6 — Composing operators into a pipeline

Chain the three operators: `events → join(dimensions) → count(per_user) → top_k(10)`
- Push a batch of deltas through the full pipeline
- Each operator receives `(record, diff)` pairs and emits `(record, diff)` pairs downstream
- Show: deltas propagate and contract — 1,000 input changes produce far fewer output changes
- Verify end-to-end: pipeline output matches full recomputation

== Step 7 — Connecting to real systems

Map the demo concepts to production systems:
- ClickHouse materialized views: incremental aggregation on insert (Step 3), but no retraction support
- Flink stateful operators: maintain state per key, process deltas per event (Steps 3–5)
- PostgreSQL `REFRESH MATERIALIZED VIEW CONCURRENTLY`: full recomputation (Step 1) — the thing we're trying to avoid
- Materialize / DBSP: the full differential dataflow model (Steps 2–6) as a database

= Key Takeaways

- Recomputation is O(total data); incremental maintenance is O(change size) — often orders of magnitude faster
- Modeling changes as `(record, diff)` pairs gives a universal framework for incremental operators
- Monotonic operators (count, sum, union) are trivially incremental — deltas flow through unchanged
- Non-monotonic operators (top-K, threshold, negation) require more care but are still incrementally maintainable
- Composing incremental operators into a pipeline preserves the property: deltas in, deltas out
- This is the core idea behind differential dataflow, and it explains why systems like Flink and ClickHouse materialized views work the way they do
