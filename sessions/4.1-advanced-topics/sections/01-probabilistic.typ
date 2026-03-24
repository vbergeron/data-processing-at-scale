== The Case for Approximation

- Trading accuracy for space and speed
- Bounded error in fixed memory

== HyperLogLog

- Cardinality estimation in kilobytes
- Hash, bucket, count leading zeros
- ~12 KB for billion-element estimates within 1–2%

== Bloom Filters

- Membership testing with no false negatives
- Bit array + k hash functions
- Tuning: false positive rate vs memory

== Count-Min Sketch

- Frequency estimation in streaming contexts
- Overestimates but never underestimates
- Heavy-hitter detection

== t-digest

- Approximate percentiles on distributed data
- Mergeable across partitions
- Accurate at the tails

== Demo

*Building HLL, Bloom filters, and CMS from scratch, then comparing against ClickHouse built-ins*
