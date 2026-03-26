= Differential Dataflow

== The recomputation problem

A `GROUP BY` query over 1 TB takes 10 seconds. \
One new row arrives. \
You rerun the query: 10 seconds _again_.

The question: can we process *only what changed* and produce a correct updated result?

== Differential dataflow

*Naïve incremental maintenance* works for simple cases — a running `SUM` or `COUNT` is trivially updatable. But `JOIN`, `GROUP BY` with retraction, `DISTINCT`, and `TOP-K` are not trivially updatable. 

Differential dataflow is a framework that handles incremental updates correctly.

== Changes as collections of deltas

Every input and output is a *multiset of changes* $Delta A$: pairs $(x, d)$ where $d in ZZ$ is a multiplicity.

$ Delta A = { (x_1, d_1), (x_2, d_2), ... } $

- $(x, +1)$ — row $x$ was inserted
- $(x, -1)$ — row $x$ was deleted
- An update is $(x_"old", -1)$ followed by $(x_"new", +1)$

== Changes as collections of deltas

*Compaction:* $(x, +1)$ and $(x, -1)$ cancel — a multiplicity of $0$ means the record is absent.

The full collection $A$ at any time is the accumulated sum of all deltas:

$ A = sum_t Delta A_t $

== Incremental monotonic operators

*Monotonic operators* propagate diffs unchanged — they never retract output.

- `map f` — $Delta(f(A)) = { (x, d) in Delta A => (f(x), d) }$

#v(0.5em)

- `filter p` — $Delta(sigma_p (A)) = { (x, d) in Delta A and p(x) => (x, d) }$

#v(0.5em)

- `union` — $Delta(A union B) = Delta A + Delta B$

== Incremental non-monotonic operators

*Non-monotonic operators* may produce retractions — a new input can invalidate a previous output.

- `join` — using the *delta rule* 

$ Delta(A join B) = (Delta A join B) union (A join Delta B) $

== Incremental non-monotonic operators — `group_by`

Model the aggregate as a function $kappa(S, x) -> S$ where $S$ is the *aggregation state* and $x$ is a new row. The operator maintains one state $S_k$ per group key $k$.

For *combinable* aggregates (`SUM`, `COUNT`), $kappa$ simply adds or subtracts from a scalar — efficient. \
For `AVG`, $S$ must track *(sum, count)* separately: $kappa((s, n), (x, +1)) = (s + x, n + 1)$. \
`MIN` and `MAX` require the full multiset — a single retraction of the minimum forces a scan of the remaining state.

== Incremental non-monotonic operators — `group_by`

When a delta row $(x, d)$ arrives in group $k$:
1. Look up the current state $S_k$ and derive the current output $"out"(S_k)$
2. Update: $S_k <- kappa(S_k, (x, d))$
3. Emit $(k, "out"(S_k^"old"), -1)$ — retract old output
4. Emit $(k, "out"(S_k^"new"), +1)$ — assert new output

== Incremental non-monotonic operators — `distinct`

`distinct` keeps only rows with positive total multiplicity. A new `+1` for a row already present does *not* produce output — the output was already asserted. A `-1` for a row with multiplicity 2 does *not* retract the output — the row is still present.

Only when multiplicity crosses zero does the output change:

- Multiplicity $0 -> 1$: emit $(x, +1)$
- Multiplicity $1 -> 0$: emit $(x, -1)$

This requires maintaining the *full multiplicity map* — not just presence. It cannot be implemented without state proportional to the number of distinct elements.

== Monotonicity and CALM

*Monotonic* programs only accumulate facts — they never retract. Given more input, they produce *more* output, never less.

A monotonic dataflow can run *without coordination*: each operator processes diffs as they arrive, in any order, and the result converges to the correct answer. No locks, no barriers, no two-phase commit.

*Non-monotonic* operators break this: a `distinct` or `top-K` may need to retract a previously emitted output when new data arrives. Correct retraction requires knowing *when* a delta is complete — which requires coordination.

== Real systems

#table(
  columns: (auto, 1fr),
  [*System*], [*Connection*],
  [Materialize], [Database built on differential dataflow; SQL views stay live and correct as data arrives],
  [Flink (Table API)], [Emits `+I` / `-D` / `-U` / `+U` changelog records — the same `(record, diff)` model],
  [ClickHouse MVs], [Trigger-on-insert, no retraction — correct only for monotonic aggregates (`SUM`, `COUNT`); `AVG` requires `AggregatingMergeTree`],
  [Apache Spark], [Structured Streaming with `outputMode("update")` emits deltas; complete mode recomputes — the non-incremental fallback],
)

== Wrap-Up — the shared thesis

Bloom filters, HyperLogLog, Count-Min Sketch, and Reservoir Sampling all make the same trade: *give up exactness to gain space and speed*, with a bounded, predictable error.

Differential dataflow makes a different trade: *give up simplicity to gain incrementality*, processing only what changed while remaining exactly correct.

Both directions are responses to the same pressure: data volumes that make naive approaches infeasible. Knowing when to approximate and when to maintain exactly — and *which systems implement which model* — is the engineering judgment this session is about.
