#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 1.2 — Observing Partition and Replication in a Distributed KV Store],
  session: [Session 1.2 — Distributed Systems Fundamentals],
  format: [Instructor-led hands-on demo],
  tools: [Docker Compose, etcd (or Redis Cluster)],
)

= Objective

Make distributed systems concepts tangible by running a small cluster, then intentionally breaking it. Students observe partitioning, replication, and failure behavior in real time.

= Setup

- 3-node etcd cluster running in Docker Compose
- A simple client script that writes and reads keys
- Network manipulation via `docker network disconnect` / `tc` (traffic control)

= Walkthrough

== Step 1 — Healthy cluster

Write keys, read them back from different nodes. Show:
- Leader election (who is the current leader?)
- Consistent reads across all nodes
- Where data physically lives (inspect each node)

== Step 2 — Kill a follower

Stop one node. Show:
- Cluster still operates (quorum: 2/3)
- Writes succeed, reads succeed
- Bring it back — observe catch-up replication

== Step 3 — Kill the leader

Stop the leader node. Show:
- Brief unavailability during re-election
- New leader elected automatically
- Writes resume after election completes

== Step 4 — Network partition

Isolate one node from the other two (without killing it). Show:
- The isolated node thinks it's alive but can't reach quorum
- The majority partition continues serving reads and writes
- Stale reads on the isolated node (if configured for local reads)
- Reconnect — observe reconciliation

== Step 5 — Split brain scenario (discussion)

With only 2 nodes, show what happens when they can't see each other:
- Neither has quorum → cluster is unavailable
- This is CAP in action: we chose consistency over availability

= Key Takeaways

- Quorum-based systems tolerate minority failures
- Leader election introduces brief unavailability — there is no free lunch
- Network partitions are the hardest failure mode: nodes are alive but isolated
- CAP is not a toggle — it's a spectrum of design choices
