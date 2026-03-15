#import "../style.typ": *

#show: lab-theme.with(
  title: [Lab 1.3.1 — Replication and Consistency in a Distributed KV Store],
  session: [Session 1.3 — Distributed Systems Fundamentals],
  format: [Hands-on lab],
  tools: [Scala 3 (`scala-cli`), `nodelib.scala` (provided)],
)

= Objective

You will build two replication strategies on top of a simulated distributed key-value store and observe how each behaves under network partitions. By the end you will have experienced the CAP trade-off firsthand: the same cluster, the same data, but radically different behavior depending on the replication model you choose.

= The Framework

A library file `nodelib.scala` provides the infrastructure. You write your node behavior in `lab.scala`.

== What the library gives you

- *`Cluster`* — the simulated network. Creates nodes, routes messages with random latency (50--500ms), and can simulate network partitions.
- *`KVServer`* — a file-backed key-value store that handles `GET`, `PUT`, `DEL`. Each node gets its own isolated store directory.
- *`KVClient`* — sends requests to a node through the cluster network. Returns `Future[RPCResponse]`.
- *`NodeCommand`* — the message type your node behavior receives: `Stop` or `Request(rpc)`.
- *`ServerCommand`* — what you send to the `KVServer` child actor: the RPC plus a `replyTo` for the response.

== What you write

Your node is a Pekko `Behavior[NodeCommand]` that receives client requests and decides what to do with them. The default node simply forwards every request to its local `KVServer`:

```scala
object MyNode:
  def init(cluster: Cluster, id: String, storeRoot: Path): Behavior[NodeCommand] =
    Behaviors.setup: ctx =>
      val serverRef = ctx.spawn(KVServer.init(id, storeRoot), "server")
      Behaviors.receiveMessage:
        case NodeCommand.Stop => Behaviors.stopped
        case NodeCommand.Request(rpc) =>
          serverRef ! ServerCommand(rpc, rpc.replyTo)
          Behaviors.same
```

To implement replication you will modify this behavior to intercept requests before (or after) forwarding them to the local store, and use `cluster.send(from, to, msg)` to communicate with peer nodes.

== Key APIs

#table(
  columns: 2,
  align: (left, left),
  table.header([*Call*], [*Effect*]),
  [`cluster.send(from, to, msg)`], [Send a `NodeCommand` from node `from` to node `to` through the network. Returns `false` if partitioned.],
  [`cluster.spawn(id)`], [Spawn a node with the default behavior.],
  [`cluster.spawn(id, factory)`], [Spawn a node with a custom `NodeFactory`.],
  [`cluster.isolate(id)`], [Partition a node from all others and the client.],
  [`cluster.rejoin(id)`], [Remove all partition rules involving this node.],
  [`cluster.partition(a, b)`], [Partition two specific nodes (symmetric).],
  [`cluster.heal(a, b)`], [Heal a specific partition.],
  [`cluster.client(id)`], [Get a `KVClient` for an existing node.],
)

#pagebreak()

= Part 1 — Async Replication (AP system)

== 1.1 — Fan-out writes

Modify your node behavior so that on every `PUT`, the node:
+ Writes to its own local `KVServer` (and replies to the client immediately)
+ Forwards the same `PUT` to all peer nodes via `cluster.send`

Your node needs to know the list of peer node IDs. Pass them as a parameter to your factory.

_Hint:_ `cluster.send(myId, peerId, NodeCommand.Request(rpc))` sends the same RPC to a peer. The peer's node will process it against its own local store. You do not need to wait for the peers to acknowledge — this is _asynchronous_ replication.

== 1.2 — Read from any node

Once writes fan out, every node eventually has the same data. Test this:
+ `PUT` a key on `alice`
+ Wait briefly for replication (e.g.~`Thread.sleep(1000)`)
+ `GET` the same key from `bob` and `carol`

Verify that all three nodes return the same value.

== 1.3 — Observe stale reads

Now remove the sleep. Fire a `PUT` on `alice` and immediately `GET` from `bob`. Do you always get the latest value? Why not?

_Discussion:_ this is _eventual consistency_. The write is acknowledged before replicas have caught up. Reads from different nodes may return different values during the replication window.

== 1.4 — Partition behavior

+ Write `color = red` on `alice`
+ Partition `alice` from `bob`: `cluster.partition("alice", "bob")`
+ Write `color = blue` on `alice`
+ Read `color` from `bob` — what do you get?
+ Heal the partition, wait, read again

_Discussion:_ during the partition, `bob` serves stale data — but it _does_ serve data. The system remains *available* (every reachable node answers) but sacrifices *consistency* (nodes disagree). This is an *AP* system.

== 1.5 — Write conflicts

+ Partition `alice` from `bob`
+ Write `color = red` on `alice`
+ Write `color = blue` on `bob`
+ Heal the partition, wait for replication
+ Read `color` from both — what happened?

_Discussion:_ both writes succeed (availability), but after healing, the nodes may disagree or one overwrites the other depending on message ordering. There is no conflict resolution — last-writer-wins by accident. Real AP systems (Dynamo, Cassandra) use vector clocks or CRDTs to handle this.

#pagebreak()

= Part 2 — Leader / Follower Replication (CP system)

In this part you will implement a different replication model. One node is the *leader* — all writes go through it. The other nodes are *followers* — they receive replicated writes from the leader and serve reads.

There is no leader election. You designate the leader at startup. This is not a course on Raft — the goal is to observe CP behavior, not to implement consensus.

== 2.1 — Leader behavior

Write a `LeaderNode` factory. On `PUT` / `DEL`:
+ Write to the local `KVServer`
+ Forward the write to every follower via `cluster.send`
+ Reply to the client only *after* all followers have been sent the update

On `GET`: serve from the local store directly.

_Hint:_ the leader does not need to wait for follower acknowledgments in this simplified version. The key difference from Part 1 is that *only the leader accepts writes*.

== 2.2 — Follower behavior

Write a `FollowerNode` factory. On `PUT` / `DEL`:
+ If the request comes from the leader (forwarded via `cluster.send`), apply it to the local store
+ If the request comes from a client, *reject it* — followers do not accept writes

_Hint:_ you can distinguish leader-forwarded requests from client requests by adding a wrapper `NodeCommand` case, or by convention (e.g.~followers only accept requests through `cluster.send`, not through `cluster.ask`).

On `GET`: serve from the local store. Followers can serve reads.

== 2.3 — Test the happy path

+ Spawn `alice` as the leader, `bob` and `carol` as followers
+ Write data through `alice`
+ Read from `bob` and `carol` — verify they have the data

== 2.4 — Partition the leader

+ Write some data through `alice`
+ Isolate `alice`: `cluster.isolate("alice")`
+ Try to write through `alice` — what happens?
+ Try to read from `bob` — does it work?
+ Try to write through `bob` — what happens?

_Discussion:_ when the leader is partitioned, *writes are unavailable* — no node can accept them. Reads from followers still work (they have stale but consistent data). The system chose *consistency over availability*: rather than risk conflicting writes, it refuses to write at all. This is a *CP* system.

== 2.5 — Heal and recover

+ Rejoin `alice`
+ Write new data — verify it replicates to followers
+ The system resumes normal operation with no conflicts

_Discussion:_ because only one node ever writes, there are no conflicts to resolve after a partition heals. Compare this to Part 1 where both sides could write independently.

#pagebreak()

= Part 3 — Comparison and Discussion

== 3.1 — Discussion questions

+ _When would you choose an AP system?_ Think of use cases where availability matters more than strict consistency (shopping carts, social media likes, DNS).

+ _When would you choose a CP system?_ Think of use cases where consistency is critical (bank transfers, inventory counts, configuration management).

+ _What is missing from our CP system?_ We hardcoded the leader. What happens if the leader crashes permanently? This is the problem that consensus protocols (Raft, Paxos, ZAB) solve — but that is a topic for another day.

+ _Can you have both?_ Some systems (e.g.~CockroachDB, Spanner) use consensus for writes but allow stale reads from followers. Where does that sit on the CAP spectrum?

= Key Takeaways

+ *Replication is not free.* Every replication strategy trades something — latency, availability, or consistency.
+ *AP systems stay available during partitions* but may serve stale or conflicting data. Conflict resolution is the hard problem.
+ *CP systems stay consistent during partitions* but become unavailable for writes. Choosing a leader avoids conflicts but creates a single point of failure.
+ *CAP is not a toggle.* Real systems mix strategies: strong consistency for writes, eventual consistency for reads, tunable quorum levels per operation.
+ *Network partitions are inevitable.* Your code must handle them — the question is how.
