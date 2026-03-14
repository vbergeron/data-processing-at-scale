#import "../../style.typ": hero

== \

#hero[How do you process data that doesn't fit on one machine? \
Now you know the model — and its limits.]

== One sentence to remember

#hero[
  MapReduce proved that *simple abstractions* \
  can tame *arbitrary parallelism* — \
  every engine since is a refinement of that idea.
]

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*Map*], [Apply a function to each record independently, emit key-value pairs],
  [*Reduce*], [Aggregate all values for a given key into a result],
  [*Shuffle*], [Repartition and transfer data across the network by key],
  [*Combiner*], [Local pre-aggregation on the mapper — reduces shuffle volume],
  [*Data locality*], [Scheduling computation on the node that holds the data],
  [*Lineage*], [A record of how each partition was derived — enables re-computation on failure],
  [*DAG*], [Directed acyclic graph — a flexible execution plan beyond Map + Reduce],
  [*Speculative execution*], [Running duplicate tasks to mitigate stragglers],
  [*Data skew*], [Uneven key distribution causing one reducer to bottleneck the job],
)
