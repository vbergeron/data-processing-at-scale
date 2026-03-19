#import "../../style.typ": hero, pause
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

== \

#hero[Why do files matter ?]

== MapReduce (2004)

+ *Load* — read data from files into workers
+ *Map* — apply a function on each partition
+ *Shuffle* — redistribute by key across the network
+ *Reduce* — aggregate partitions into results
+ *Save* — persist results back to files


Files are the interface between every stage.

== Why file format is the first optimization

The file format determines the cost of every MapReduce stage:

#v(0.5em)

  + *Map* : Read speed constrained
  + *Shuffle* : Size constrained
  + *Reduce* : Write speed constrained

#v(0.5em)

This stays true for any modern system. \
There is not so many ways to persist data.

== \

#hero[Format is one of *key design decisions*. \
      It is not an implementation details.]

== Distributed file systems

Where do the files live?


- Your laptop: one disk, one filesystem, one failure domain
- A cluster: thousands of disks, across racks and datacenters


The data doesn't fit on one machine. We solved this in session 1.3.

== GFS / HDFS

#align(center + horizon, image("../assets/hadoop-logo.svg", width: 60%))

== GFS / HDFS

Google File System (2003) and its open-source clone HDFS (2006):


- Files are split into *blocks* (64–256 MB each)
- Each block is replicated (default: *N copies* on different racks)


This is the foundation that made MapReduce, and later Spark, possible.

== HDFS architecture

#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], stroke: (dash: "dashed"), width: 2.8cm, inset: 14pt),

    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),

    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),
  )
)

- *NameNode*: stores the metadata — file names, block locations, permissions
- *DataNodes*: store the actual blocks on local disks, send heartbeats to the NameNode

== HDFS — the write path
#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], width: 2.8cm, inset: 14pt),

    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),

    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),

    edge((0, 0.25), (0, 1.75), "->", [], label-side: left),
    edge((0, 0.25), (0, 1.75), "<-", [], label-side: left),
  )
)

1. *Client* ask the *NameNode* for block allocation

== HDFS — the write path
#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], width: 2.8cm, inset: 14pt),

    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),

    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),
    
    edge((0, 0.25), (1,0), "->", [], label-side: left, shift: 4pt),
    
    edge((1,0), (1,1), "->", label-side: left),
    edge((1,1), (1,2), "->", label-side: left),
    
    edge((0, 0.25), (1,0), "<-", [], label-side: right, shift: -4pt, stroke: (dash: "dashed")),
    edge((0, 0.25), (1,1), "<-", [], label-side: right, stroke: (dash: "dashed")),
    edge((0, 0.25), (1,2), "<-", [], label-side: right, stroke: (dash: "dashed")),

  )
)

2. *Client* push data on the first *DataNode*
  + Replication in pipelined to reduce bandwidth
  + Every *DataNode* acknoledge to the *Client*

== HDFS — the write path
#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], width: 2.8cm, inset: 14pt),

    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),

    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),

    edge((0, 0.25), (0, 1.75), "->", [], label-side: left),
    edge((0, 0.25), (0, 1.75), "<-", [], label-side: left),
  )
)

3. *Client* notify the *NameNode* the transfer is complete

== HDFS — the read path


#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], width: 2.8cm, inset: 14pt),
    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),
    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),

    edge((0, 0.25), (0, 1.75), "->", [], label-side: left, shift: 4pt),
    edge((0, 0.25), (0, 1.75), "<-", [], label-side: right, shift: -4pt, stroke: (dash: "dashed")),
  )
)

1. *Client* asks the *NameNode* for the block list and their locations

== HDFS — the read path


#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*], width: 2.8cm, inset: 14pt),
    node((0, 1.75), [*NameNode*], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),
    node((1, 0), [*DataNode 1*], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*], width: 5cm, inset: 14pt),

    edge((0, 0.25), (1, 0), "<-", [], label-side: left, shift: 4pt),
    edge((0, 0.25), (1, 0), "->", [], label-side: right, shift: -4pt, stroke: (dash: "dashed")),
  )
)


2. *Client* reads directly from the *closest* DataNode

== HDFS & MapReduce — data locality

#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0.25), [*Client*\ #text(size: 9pt, fill: luma(100))[submits job]], width: 2.8cm, inset: 14pt),
    node((0, 1.75), [*JobTracker*\ #text(size: 9pt, fill: luma(100))[schedules tasks]], fill: rgb("#fff3e0"), width: 5cm, inset: 14pt),
    node((1, 0), [*DataNode 1*\ #text(size: 9pt, fill: luma(100))[+ TaskTracker]], width: 5cm, inset: 14pt),
    node((1, 1), [*DataNode 2*\ #text(size: 9pt, fill: luma(100))[+ TaskTracker]], width: 5cm, inset: 14pt),
    node((1, 2), [*DataNode 3*\ #text(size: 9pt, fill: luma(100))[+ TaskTracker]], width: 5cm, inset: 14pt),

    edge((0, 0.25), (0, 1.75), "->", [job], label-side: left),
    edge((0, 1.75), (1, 0), "->", [map], label-side: left),
    edge((0, 1.75), (1, 1), "->", [map]),
    edge((0, 1.75), (1, 2), "->", [map], label-side: right),
  )
)

- Each DataNode runs a *TaskTracker* — a worker that executes map and reduce tasks
- The *JobTracker* schedules each map task on the DataNode that holds the blocks it needs
- *Data locality*: input data never crosses the network for the map phase

== HDFS — the NameNode problem

The NameNode is a *single point of failure* and a *scalability bottleneck*:


- All metadata in RAM — one NameNode must hold the entire namespace
- ~150 bytes per block in memory → 100 million blocks ≈ 15 GB of RAM
- If the NameNode dies, the cluster is *down* — data is intact on DataNodes but unreachable


In Day 1 terms: the NameNode is a *leader* with no *failover*. A crash is a total outage.

== HDFS High Availability

HDFS HA uses a *Standby NameNode* and *JournalNodes*. \
*NameNodes* append and read from a shared edit log stored on *JournalNodes* 

- *Active NameNode*: appends to the edit log.
- *Standby NameNode*: replays the edit log.
- Both are using *Quorum* read or writes.

ZooKeeper's role: decide *which* NameNode is active.

== HDFS High Availability

#align(center,
  fletcher.diagram(
    spacing: (5cm, 1cm),
    node-stroke: 0.8pt,
    node-corner-radius: 4pt,

    node((0, 0), [*NameNode* #text(size: 0.7em, style: "italic")[(Active)]], width: 5cm, inset: 14pt),
    node((0, 1), [*ZK*], width: 2.8cm, inset: 14pt),
    node((0, 2), [*NameNode* #text(size: 0.7em, style: "italic")[(Standby)]], width: 5cm, inset: 14pt),
    
    node((1, 0), [*JournalNode*], width: 5cm, inset: 14pt),
    node((1, 1), [*JournalNode*], width: 5cm, inset: 14pt),
    node((1, 2), [*JournalNode*], width: 5cm, inset: 14pt),

    edge((0, 0), (0, 1), "->", []),
    edge((0, 2), (0, 1), "->", []),
    
    edge((0, 0), (1, 0), "->", []),
    edge((0, 0), (1, 1), "->", []),
    edge((0, 0), (1, 2), "->", []),
    
    edge((0, 2), (1, 0), "<-", stroke: (dash: "dashed")),
    edge((0, 2), (1, 1), "<-", stroke: (dash: "dashed")),
    edge((0, 2), (1, 2), "<-", stroke: (dash: "dashed")),
  )
)


== ZooKeeper

#align(center + horizon, image("../assets/zookeeper-logo.svg", width: 60%))

== ZooKeeper — the coordination service

*ZooKeeper* is a *CP* system (recall Day 1: consistent + partition-tolerant, sacrifices availability):


- A small cluster (3 or 5 nodes) running a *consensus protocol* (ZAB, similar to Paxos/Raft)
- Provides: distributed locks, leader election, configuration, group membership
- *Linearizable writes* — with optional linearizable read: (issue `sync()` first) 

== ZooKeeper and the split-brain problem

ZooKeeper prevents *split-brain* with *fencing*:

+ Active NameNode holds an *ephemeral lock* (ZooKeeper znode)
+ If the active NameNode crashes, ZooKeeper detects the lost heartbeat and deletes the lock
+ Standby acquires the lock and becomes active
+ A *fencing* mechanism ensures the old active cannot issue writes (e.g., SSH kill, shared storage revocation)


ZooKeeper's quorum ensures the lock is never granted to two nodes at once — making *automatic failover* safe.

== HDFS Federation — scaling the namespace

Even with HA, one NameNode holds the *entire* namespace. At petabyte scale, this becomes the bottleneck.


*HDFS Federation*: multiple independent NameNodes, each owning a *namespace partition* (called a block pool).


- `/data/transactions/` → NameNode A
- `/data/logs/` → NameNode B
- DataNodes serve blocks for *all* NameNodes


In Day 1 terms: the namespace is *partitioned* across NameNodes, while data blocks are *replicated* across DataNodes. Two orthogonal concerns, just like we saw for databases.

== HDFS through the Day 1 lens

#table(
  columns: 2,
  align: (left, left),
  table.header([*Day 1 concept*], [*How it shows up in HDFS*]),
  [*Partitioning*], [Files split into blocks; Federation partitions the namespace],
  [*Replication*], [Each block stored on 3 DataNodes (different racks)],
  [*Leader / follower*], [Active NameNode (leader) + Standby (follower)],
  [*Failover*], [ZooKeeper-based leader election on NameNode crash],
  [*Split-brain*], [Prevented by ZooKeeper fencing],
  [*Quorum*], [JournalNodes (edit log) and ZooKeeper (leader election)],
  [*CAP trade-off*], [NameNode is CP — consistent metadata, unavailable during failover],
  [*Data locality*], [Scheduler places compute where replicas live — avoiding the network],
)

== Object storage — the cloud successor

S3, GCS, Azure Blob Storage replaced HDFS in most modern stacks:

- Immutable *objects* (files) in *buckets* (directories)
- No block-level control — you read ranges of bytes
- Virtually unlimited capacity, pay-per-GB

Trade-off: no data locality. Compute and storage are *decoupled*.

== Object storage — consistency model

Object storage is now *strongly consistent* for all clients:

- S3: strong consistency for all operations since December 2020
- GCS and Azure Blob: strongly consistent from the start
- After a successful `PUT` or `DELETE`, any client immediately sees the new value

Strong consistency here is *per-object* — there is no multi-object transaction. \
Concurrent writes to the same key are last-writer-wins.

== HDFS vs object storage — when it matters

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Property*], [*HDFS*], [*Object storage (S3)*]),
  [Data locality], [Yes — compute on data node], [No — data travels over network],
  [Mutability], [Append-only], [Immutable objects],
  [Cost], [Cluster runs 24/7], [Pay per GB stored + read],
  [Scalability], [NameNode bottleneck], [Virtually unlimited],
  [Ecosystem], [Hadoop, on-prem Spark], [Everything modern],
)


Most new systems target object storage. \
File format choice matters *more* — every byte you read crosses the network.

== \

#hero[Let's start with formats you already know.]
