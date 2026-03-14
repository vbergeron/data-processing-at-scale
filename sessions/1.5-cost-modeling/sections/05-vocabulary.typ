#import "../../style.typ": hero

== \

#hero[How long should this query take? \ Now you can *estimate before you run*.]

== One sentence to remember

#hero[
  Performance reasoning is not about measuring — \
  it's about *predicting* from first principles \
  and knowing when reality doesn't match.
]

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*Storage hierarchy*], [L1 → L2 → L3 → RAM → SSD → network → S3 — each ~10× slower],
  [*Sequential access*], [Reading consecutive bytes — enables prefetch, maximizes throughput],
  [*Random access*], [Jumping to arbitrary positions — pays full seek latency each time],
  [*Cache line*], [64-byte block — the CPU's atomic unit of memory access],
  [*Column pruning*], [Reading only the columns referenced by a query — skipping the rest],
  [*Columnar storage*], [Storing all values of one column contiguously — enables pruning and compression],
  [*Shuffle*], [Repartitioning data across the network by key — serialize, transfer, merge, deserialize],
  [*Amdahl's law*], [Speedup limited by the serial fraction: S = 1 / (s + (1-s)/N)],
  [*Strong scaling*], [Fixed data, more nodes → faster. Limited by serial fraction.],
  [*Weak scaling*], [More data, more nodes → same speed. Limited by communication.],
  [*Straggler*], [A slow task that determines the job's wall-clock time],
)
