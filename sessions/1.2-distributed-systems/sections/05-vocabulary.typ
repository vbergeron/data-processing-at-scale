#import "../../style.typ": hero
== One sentence to remember

#hero[
  Too big → too fragile → too complex → \ *your job is to choose the right trade-offs.*
]

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*Partial failure*], [Some components fail while others keep running],
  [*CAP theorem*], [During a network partition, choose consistency or availability],
  [*Linearizability*], [Behaves as if there is a single copy of the data],
  [*Eventual consistency*], [Replicas converge if no new writes arrive — no time bound],
  [*Causal ordering*], [Causally related operations are seen in the same order everywhere],
  [*Partition / shard*], [A subset of data assigned to one node],
  [*Consistent hashing*], [Hash ring that minimizes key movement when nodes change],
  [*Replication lag*], [Delay between a write on the leader and its application on a follower],
  [*Failover*], [Promoting a follower to leader when the current leader fails],
  [*Split-brain*], [Two nodes both believe they are the leader],
  [*Quorum*], [Minimum number of nodes that must agree for an operation to succeed],
)
