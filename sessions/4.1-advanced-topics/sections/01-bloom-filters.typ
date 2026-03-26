
= Bloom Filters

== The membership problem

Given a large set $S$, answer *"is x in S?"* — as fast and as cheaply as possible.

== The naive answer

- linear search : compute is O(|S|), space is O(|S|)
- binary search (hash set) : compute is O(log |S|), space is O(|S|).

== \

What if we trade accuracy for space?

== Bloom filters

A probabilistic data structure that answers the membership question.

- O(1) in time
- O(K < N) (*sub-linear*) space. 

Bloom filters can return *false positives* (claim an element is present when it is not), but they *never return false negatives*.

== The data structure

A Bloom filter is :
- a *bit array* $B$ of $m$ bits, initially all zero
- $k$ independent hash functions $h_1, ..., h_k$ each mapping an element to $[0, m)$.

== Efficient hashes computation

Small interpolation trick, given only two hash functions $h_A$ and $h_B$:
$ h_i(x) = (h_A(x) + i * h_B(x)) mod m $

== Insert $x$

Insert is : $"foreach" i "in" [0, k), B[h_i(x)] := 1$

== Query $x$

Query is : $"forall" i "in" [0, k), B[h_i(x)] = 1$

== False positives

A false positive occurs when all $k$ positions happen to be set by *other* elements. \
There are no false negatives because insertion always sets all $k$ bits.

#align(center,
  image("../assets/Bloom_filter.svg.png", width: 90%)
)

== Other nice features

- *Deletion is not supported* — clearing a bit might unset it for another element that shares that position.
- if $m$ and $h_i$ are the same for both filters
  - $B_1 union B_2$ is given by bitwise OR
  - $B_1 inter B_2$ is given by bitwise AND

== Tuning: the false positive rate

Given $n$ elements inserted into $m$ bits with $k$ hash functions, the false positive probability is approximately:

$ p approx (1 - e^(-k n / m))^k $

For a target false positive rate $p$ and expected $n$ elements, the optimal parameters are:

$ m = - (n ln p) / (ln 2)^2 $

$ k = (m / n) ln 2 $

*Example:* 1 million elements at 1% false positive rate → $m ≈ 9.6$ million bits (~1.2 MB), $k = 7$ hash functions.

== Where Bloom filters appear in the stack

#table(
  columns: (auto, 1fr),
  [*System*], [*Use*],
  [Apache Cassandra], [Each SSTable has a Bloom filter — skip reading the file entirely if the key is definitely absent],
  [Apache Parquet], [Row group Bloom filters — added in 2.0; skip entire row groups in predicate pushdown],
  [ClickHouse], [`bloom_filter` skip index — prune granules that cannot match a `WHERE` condition],
)

== Variants

*Counting Bloom filter* — replace each bit with a small counter. Increment on insert, decrement on delete. Enables deletion at the cost of ~4× memory. Risk of counter overflow.

*Scalable Bloom filter* — chain multiple filters of increasing size. Start small; when the current filter would exceed the target false positive rate, add a new layer. Total memory grows logarithmically.

*Cuckoo filter* — stores fingerprints in a cuckoo hash table. Supports deletion natively, better cache efficiency, lower false positive rate at the same memory. Preferred over counting Bloom in modern systems.

*Blocked Bloom filter* — aligns bit positions to cache lines. All $k$ bits for one element land in the same cache line → 1 cache miss per lookup instead of $k$. Used in Apache Arrow and DuckDB.
