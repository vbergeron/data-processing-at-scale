#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

= Replication

== Why replicate?

#align(center + horizon,
  image("../assets/ovh.jpg", height: 85%),
)

== Why replicate?

#{
  let p1 = rgb("#bbdefb")
  let p2 = rgb("#c8e6c9")
  let p3 = rgb("#fff9c4")
  let p4 = rgb("#ffccbc")

  let partition-tag(label, color) = box(
    fill: color, inset: (x: 5pt, y: 3pt), radius: 3pt,
    text(size: 9pt, weight: "bold")[#label],
  )

  let node-box(name, ..parts) = box(
    stroke: 0.8pt, radius: 4pt, inset: 8pt, width: 2.8cm,
    align(center)[
      #text(size: 11pt, weight: "bold")[#name]
      #stack(dir: ltr, spacing: 4pt, ..parts.pos())
    ],
  )

  align(center,
    stack(dir: ltr, spacing: 0.6cm,
      node-box("N1", partition-tag("P1", p1), partition-tag("P4", p4)),
      node-box("N2", partition-tag("P1", p1), partition-tag("P2", p2)),
      node-box("N3", partition-tag("P1", p1), partition-tag("P2", p2), partition-tag("P3", p3)),
      node-box("N4", partition-tag("P2", p2), partition-tag("P3", p3), partition-tag("P4", p4)),
      node-box("N5", partition-tag("P3", p3), partition-tag("P4", p4)),
    )
  )

  align(center,
    text(size: 9pt, fill: luma(120))[4 partitions × RF 3 across 5 nodes],
  )
}

- *Durability*: survive hardware failure — data exists on multiple machines
- *Availability*: serve reads even if one replica is down
- *Latency*: read from the geographically closest copy
- Partitioning and replication are *orthogonal* — you almost always use both

== Leader / follower replication

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((1, 0), [Client], stroke: (dash: "dashed")),
    node((1, 1), [*Leader*], fill: rgb("#bbdefb")),
    node((0, 2), [Follower], fill: rgb("#e3f2fd")),
    node((1, 2), [Follower], fill: rgb("#e3f2fd")),
    node((2, 2), [Follower], fill: rgb("#e3f2fd")),
    edge((1, 0), (1, 1), "->", [writes & reads]),
    edge((1, 1), (0, 2), "->", [replication log], stroke: rgb("#1565c0")),
    edge((1, 1), (1, 2), "->", [replication log], stroke: rgb("#1565c0")),
    edge((1, 1), (2, 2), "->", [replication log], stroke: rgb("#1565c0")),
  )
)

- One *leader* accepts all writes; *followers* replicate the write-ahead log
- No write conflicts — the leader serializes every mutation into a single ordered log
- Reads can go to any replica — scale read throughput by adding followers
- Simple mental model: behaves like a single node with backup copies

== Asynchronous replication

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let cx = 0; let lx = 5; let fx = 10

    line((cx, 0), (cx, -7.5), stroke: 1.2pt)
    line((lx, 0), (lx, -7.5), stroke: 1.2pt)
    line((fx, 0), (fx, -7.5), stroke: 1.2pt)

    content((cx, 0.6), text(size: 11pt, weight: "bold")[Client])
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Leader])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Follower])

    line((cx + 0.2, -1), (lx - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2.5, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((lx - 0.2, -2), (cx + 0.2, -2.5), stroke: 1pt, mark: (end: ">"))
    content((2.5, -2.7), text(size: 10pt)[ok ✓])

    line(
      (lx + 0.2, -2.5), (fx - 0.2, -5.5),
      stroke: (paint: luma(120), thickness: 1pt, dash: "dashed"),
      mark: (end: ">"),
    )
    content((7.5, -3.5), text(size: 9pt, fill: luma(120))[async \ replication])

    rect((lx - 0.3, -3.5), (lx + 0.3, -5), fill: rgb("#ffcdd2").transparentize(50%), stroke: none)
    content((lx - 2, -4.25), text(size: 9pt, fill: rgb("#c62828"))[💀 data lost \ if leader dies])

    content((5, -7.8), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

- Leader acks *before* replication — fast writes, low latency
- If the leader crashes in the danger zone, acknowledged writes are *permanently lost*
- Used by: PostgreSQL (default), MySQL, MongoDB, Redis

== Synchronous replication

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let cx = 0; let lx = 5; let fx = 10

    line((cx, 0), (cx, -7.5), stroke: 1.2pt)
    line((lx, 0), (lx, -7.5), stroke: 1.2pt)
    line((fx, 0), (fx, -7.5), stroke: 1.2pt)

    content((cx, 0.6), text(size: 11pt, weight: "bold")[Client])
    content((lx, 0.6), text(size: 11pt, weight: "bold")[Leader])
    content((fx, 0.6), text(size: 11pt, weight: "bold")[Follower])

    line((cx + 0.2, -1), (lx - 0.2, -1.5), stroke: 1pt, mark: (end: ">"))
    content((2.5, -0.7), text(size: 10pt)[`write(x, 42)`])

    line((lx + 0.2, -2), (fx - 0.2, -2.5), stroke: (paint: rgb("#1565c0"), thickness: 1pt), mark: (end: ">"))
    content((7.5, -1.7), text(size: 10pt, fill: rgb("#1565c0"))[replicate])

    line((fx - 0.2, -3), (lx + 0.2, -3.5), stroke: (paint: rgb("#1565c0"), thickness: 1pt), mark: (end: ">"))
    content((7.5, -3.7), text(size: 10pt, fill: rgb("#1565c0"))[ack])

    line((lx - 0.2, -4), (cx + 0.2, -4.5), stroke: 1pt, mark: (end: ">"))
    content((2.5, -4.7), text(size: 10pt)[ok ✓])

    line((cx - 0.5, -1), (cx - 0.5, -4.5), stroke: (paint: red, thickness: 2.5pt))
    content((cx - 1.8, -2.75), text(size: 9pt, fill: red)[blocked])

    content((5, -7.8), text(size: 9pt, fill: luma(120))[time ↓])
  })
)

- Leader acks *after* replication — data is durable on multiple nodes before the client proceeds
- Cost: every write pays a round-trip latency penalty; one slow follower blocks everything
- Used by: etcd, ZooKeeper (Raft/ZAB), PostgreSQL (`synchronous_commit`)

== A network partition

#{
  let r = 1.5
  let pts = range(8).map(i => {
    let a = i * 45deg
    (calc.cos(a) * r, calc.sin(a) * r)
  })
  let left = (2, 3, 4, 5)

  let draw-clique(partition: false) = cetz.canvas(length: 1cm, {
    import cetz.draw: *
    for i in range(8) {
      for j in range(i + 1, 8) {
        let cross = (i in left) != (j in left)
        if not (partition and cross) {
          line(pts.at(i), pts.at(j), stroke: 0.4pt + luma(160))
        }
      }
    }
    if partition {
      let mid-a = 67.5deg
      let d = 2.0
      line(
        (calc.cos(mid-a) * d, calc.sin(mid-a) * d),
        (-calc.cos(mid-a) * d, -calc.sin(mid-a) * d),
        stroke: (paint: red, thickness: 2pt, dash: "dashed"),
      )
    }
    for p in pts {
      circle(p, radius: 0.22, fill: rgb("#c8e6c9"), stroke: 0.8pt)
    }
  })

  align(center,
    grid(
      columns: 2,
      gutter: 2cm,
      align: center,
      draw-clique(),
      draw-clique(partition: true),
    )
  )
}

- Both sides are alive, but they *cannot talk to each other*
- Clients can still reach each node independently
- The system must now choose: consistency or availability?

== Split-brain

#{
  let r = 1.5
  let pts = range(8).map(i => {
    let a = i * 45deg
    (calc.cos(a) * r, calc.sin(a) * r)
  })
  let left-side = (2, 3, 4, 5)
  let original-leader = 0

  let follower-color = rgb("#c8e6c9")
  let leader-color = rgb("#ffcdd2")

  let draw-unified() = cetz.canvas(length: 1cm, {
    import cetz.draw: *
    for i in range(8) {
      for j in range(i + 1, 8) {
        line(pts.at(i), pts.at(j), stroke: 0.4pt + luma(160))
      }
    }
    for (i, p) in pts.enumerate() {
      let is-leader = i == original-leader
      circle(p, radius: if is-leader { 0.32 } else { 0.22 },
        fill: if is-leader { leader-color } else { follower-color }, stroke: 0.8pt)
      if is-leader {
        content((calc.cos(i * 45deg) * (r + 0.7), calc.sin(i * 45deg) * (r + 0.7)),
          text(size: 10pt)[👑])
      }
    }
  })

  let draw-split() = cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let leader-left = 4
    let leader-right = 0

    for i in range(8) {
      for j in range(i + 1, 8) {
        let cross = (i in left-side) != (j in left-side)
        if not cross {
          line(pts.at(i), pts.at(j), stroke: 0.4pt + luma(160))
        }
      }
    }

    let mid-a = 67.5deg
    let d = 2.0
    line(
      (calc.cos(mid-a) * d, calc.sin(mid-a) * d),
      (-calc.cos(mid-a) * d, -calc.sin(mid-a) * d),
      stroke: (paint: red, thickness: 2pt, dash: "dashed"),
    )

    for (i, p) in pts.enumerate() {
      let is-leader = i == leader-left or i == leader-right
      circle(p, radius: if is-leader { 0.32 } else { 0.22 },
        fill: if is-leader { leader-color } else { follower-color }, stroke: 0.8pt)
      if is-leader {
        content((calc.cos(i * 45deg) * (r + 0.7), calc.sin(i * 45deg) * (r + 0.7)),
          text(size: 10pt)[👑])
      }
    }

    content((r + 1.5, -0.5), text(size: 10pt)[`x = 42`])
    content((-r - 1.5, 0.5), text(size: 10pt)[`x = 99`])
  })

  align(center,
    grid(
      columns: 2,
      gutter: 2cm,
      align: center,
      draw-unified(),
      draw-split(),
    )
  )
}

- Both sides elect a leader — two leaders accept *conflicting writes*
- When the partition heals, the system must reconcile divergent state
- Solutions: fencing tokens, consensus protocols (Raft, Paxos)

== Leaderless replication

#align(center,
  fletcher.diagram(
    spacing: (2.5cm, 2cm),
    node-stroke: 0.8pt,
    node((1, 0), [Client], stroke: (dash: "dashed")),
    node((0, 1), [Node A], fill: rgb("#c8e6c9")),
    node((1, 1), [Node B], fill: rgb("#c8e6c9")),
    node((2, 1), [Node C], fill: rgb("#c8e6c9")),
    edge((1, 0), (0, 1), "->", stroke: rgb("#1565c0")),
    edge((1, 0), (1, 1), "->", [write], stroke: rgb("#1565c0")),
    edge((1, 0), (2, 1), "->", stroke: rgb("#1565c0")),
    edge((0, 1), (1, 1), "<->", stroke: (paint: luma(160), dash: "dashed")),
    edge((1, 1), (2, 1), "<->", [gossip], label-side: right, stroke: (paint: luma(160), dash: "dashed")),
  )
)

- No designated leader — the *client* sends writes to multiple nodes directly
- Nodes exchange updates among themselves via *gossip* (anti-entropy)
- No failover needed: if one node is down, the others keep serving
- But how does the client know a read is up to date?

== Quorum reads & writes — W + R > N

- *Quorum*: a minimum number of nodes that must participate in an operation
- Write to *W* nodes, read from *R* nodes, out of *N* total replicas
- If `W + R > N`, at least one node in every read has the latest write
- The client picks the value with the highest version number

== Tuning W, R, N

#table(
  columns: 4,
  align: (left, center, center, center),
  table.header([*Config*], [*Consistency*], [*Write speed*], [*Read speed*]),
  [N=3, W=2, R=2], [Strong], [Medium], [Medium],
  [N=3, W=1, R=1], [Eventual], [Fast], [Fast],
  [N=3, W=3, R=1], [Strong], [Slow], [Fast],
  [N=3, W=1, R=3], [Strong], [Fast], [Slow],
)

- Every configuration is a *trade-off dial* between latency and safety
- W=1 is "fire and forget" — fast writes, but data can be lost
- R=1 is "read from anyone" — fast reads, but might be stale

== Leader/follower vs leaderless — when to use which

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Leader/follower*], [*Leaderless (quorum)*]),
  [Write throughput], [One bottleneck], [Distributed],
  [Read scaling], [Add followers], [Any node serves reads],
  [Failover complexity], [High (leader election)], [Low (no single leader)],
  [Consistency], [Depends on sync/async], [Tunable via W, R, N],
)

== \

#hero[Data is split and copied. \ But what can we actually guarantee?]
