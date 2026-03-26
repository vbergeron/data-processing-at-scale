= More Probabilistic Data Structures

== HyperLogLog — the problem

`COUNT(DISTINCT user_id)` over a billion rows requires storing all user IDs to compare them — or does it?

Exact distinct counting is a *streaming hardness result*: any exact algorithm requires $Omega(n)$ bits in the worst case. HyperLogLog breaks this by accepting a small, bounded error.

*The deal:* ~12 KB of memory, any cardinality, ~1–2% relative error. The same 12 KB whether you have 10 000 or 10 billion distinct elements.

== HyperLogLog — mechanics

*Intuition:* hash each element uniformly. The probability of a hash starting with $k$ leading zeros is $2^(-k)$. If the maximum number of leading zeros observed is $k$, you have likely seen around $2^k$ distinct elements.

*In practice:* one register is too noisy. HyperLogLog splits elements into $m = 2^b$ buckets (using the first $b$ bits of the hash), keeps one max-leading-zeros register per bucket, and combines them with a *harmonic mean* to correct for bias.

Error: $approx 1.04 / sqrt(m)$ — with $m = 2^14 = 16384$ registers, error drops below 1%.

*Merging:* two HyperLogLog sketches merge by taking the element-wise max of their registers — this is exact, no loss.

== HyperLogLog — in the stack

#table(
  columns: (auto, 1fr),
  [*System*], [*Usage*],
  [ClickHouse], [`uniq()` and `uniqHLL12()` — default for `COUNT(DISTINCT ...)`],
  [Redis], [`PFADD` / `PFCOUNT` — a HLL per key, O(1) add and count],
  [BigQuery], [`APPROX_COUNT_DISTINCT()` — HLL++ variant],
  [Apache Spark], [`approx_count_distinct()` with configurable relative SD],
  [Druid], [HLL sketch columns for rollup aggregation at ingest time],
)

When you see `uniq(user_id)` in a ClickHouse dashboard query, the database is running HyperLogLog — not a hash set.

== Count-Min Sketch — the problem

Given a high-velocity stream of events (clicks, packets, transactions), answer: *"how many times has element $x$ appeared?"* — without storing the full stream.

Exact frequency counting requires one counter per distinct element — $O(|Sigma|)$ space. For IP addresses or URLs, that is gigabytes.

Count-Min Sketch answers frequency queries in *fixed space* with a one-sided error: it may *overestimate*, but never underestimates. A count of 0 means the element was truly never seen.

== Count-Min Sketch — mechanics

*Structure:* a $d times w$ matrix of counters, initialized to zero. Choose $d$ independent hash functions $h_1, ..., h_d$, each mapping an element to $[0, w)$.

*Update* element $x$: for each row $i$, increment `table[i][h_i(x)]`.

*Query* element $x$: return $min_i$ `table[i][h_i(x)]`.

*Why min?* Hash collisions only inflate counters — they never decrease them. Taking the minimum across $d$ independent rows isolates the least-collided estimate.

Error bound: with probability $1 - delta$, the estimate is within $epsilon dot ||f||_1$ of the true count, where $w = ceil(e / epsilon)$ and $d = ceil(ln(1/delta))$.

== Count-Min Sketch — in the stack

#table(
  columns: (auto, 1fr),
  [*System*], [*Usage*],
  [Apache Flink], [Heavy-hitter detection in `TopNFunction` and stream sampling],
  [Network monitoring], [Per-flow packet counting in switches — hardware implementations],
  [Databases], [Query optimiser cardinality estimation for join ordering],
  [Content delivery], [Tracking hot keys / trending content without storing full logs],
  [ClickHouse], [`topK(N)(x)` uses the Space-Saving algorithm — a CMS variant],
)

The key asymmetry: you trade *which* elements you count precisely (all of them) for *which* queries you answer precisely (only the heavy hitters, which are what you care about anyway).

== Reservoir Sampling — the problem

Given a stream of unknown length $N$, select a *uniform random sample* of exactly $k$ elements — without knowing $N$ in advance, and without storing the full stream.

Naïve approach: buffer everything, sample at the end. Requires $O(N)$ memory — infeasible for an unbounded stream.

Reservoir sampling solves this in $O(k)$ memory with a provably uniform sample, processing each element exactly once.

== Reservoir Sampling — mechanics

*Algorithm R (Vitter, 1985):*

1. Fill the reservoir with the first $k$ elements.
2. For each subsequent element at position $i > k$: generate $j = $ random integer in $[1, i]$. If $j <= k$, replace reservoir$[j]$ with the current element.

*Why is this uniform?* After $i$ elements, each has probability $k/i$ of being in the reservoir — provable by induction. The final sample is exactly uniform over all $N$ elements.

*Distributed variant (reservoir merging):* each partition independently samples $k$ elements with weights. Partitions are merged by weighted sampling — enables parallel reservoir sampling over a Spark or Flink dataset.

== Reservoir Sampling — in the stack

#table(
  columns: (auto, 1fr),
  [*System*], [*Usage*],
  [ClickHouse], [`quantile(p)(x)` uses reservoir sampling for percentile estimation],
  [Apache Spark], [`DataFrame.sample()` and `sampleBy()` use reservoir variants],
  [Apache Flink], [Stream sampling operators; `approxQuantile` in Table API],
  [ML pipelines], [Uniform data sampling for training sets from large feature stores],
  [A/B testing], [Reservoir ensures uniform user assignment when population size is unknown],
)

Reservoir sampling is the streaming equivalent of `ORDER BY random() LIMIT k` — except it runs in $O(k)$ memory and one pass, while `ORDER BY random()` requires materialising the full dataset.
