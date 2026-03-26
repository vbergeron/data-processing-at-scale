= Probabilistic Data Structures — A Survey

== The shared idea

Bloom filters trade exactness for *bounded, predictable error with fixed memory*. Three other structures follow the same contract — each for a different query type.

#table(
  columns: (auto, auto, 1fr),
  [*Structure*], [*Query*], [*Error guarantee*],
  [Bloom filter], [Is $x$ in the set?], [False positives only; configurable rate],
  [HyperLogLog], [How many distinct $x$?], [~1–2% relative error; ~12 KB for any cardinality],
  [Count-Min Sketch], [How often does $x$ appear?], [Overestimates only; never underestimates],
  [t-digest], [What is the $p$-th percentile?], [Accurate at tails; looser near median],
)

== HyperLogLog — cardinality estimation

Counting distinct elements exactly requires storing them all. HyperLogLog estimates the count in ~12 KB with ~1–2% error regardless of the true cardinality.

*Intuition:* hash each element, observe the maximum number of leading zeros in any hash. The probability of seeing $k$ leading zeros is $2^{-k}$, so the max implies roughly $2^k$ distinct elements. Multiple registers (buckets) tame the variance.

*In the stack:* `COUNT(DISTINCT ...)` in ClickHouse runs `uniq()` — HyperLogLog under the hood. Redis ships `PFADD` / `PFCOUNT`. BigQuery uses it for `APPROX_COUNT_DISTINCT`. When you saw `uniq(user_id)` in the ClickHouse session, that was HyperLogLog.

== Count-Min Sketch — frequency estimation

Given a stream of elements, estimate how often each element has appeared — using sub-linear memory.

*Structure:* a $d × w$ matrix of counters, with $d$ hash functions (one per row). On each arrival of $x$, increment `table[i][h_i(x)]` for each row $i$. To query, return `min(table[i][h_i(x)])`.

*Why min?* Hash collisions only cause over-counting, never under-counting. The minimum over $d$ independent rows minimises the collision noise.

*Use cases:* heavy-hitter detection in network traffic; top-K pages in a web analytics stream; rate limiting by IP. Flink's `TopNFunction` uses a variant internally.

== t-digest — approximate percentiles

`AVG(AVG(x)) = AVG(x)` over a union — but `MEDIAN(MEDIAN(x)) ≠ MEDIAN(x)`. Percentiles do not compose naively across partitions.

t-digest solves this by maintaining a sorted list of *centroids* (compressed clusters of data points). Merging two t-digests is exact — centroids from both are merged and re-compressed.

*Properties:* the sketch is more accurate at the tails (p1, p99) than near the median — exactly where accuracy matters most for SLA monitoring.

*In the stack:* ClickHouse `quantileTDigest(0.99)(latency)`, Elasticsearch percentile aggregations, Prometheus `histogram_quantile` (a weaker cousin). You saw the `*State` / `*Merge` pattern in the ClickHouse session — t-digest states are what `quantileTDigestState` serialises.
