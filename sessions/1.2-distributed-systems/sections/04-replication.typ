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
- Reads can go to any replica (trade-off: freshness vs throughput)
- If the leader dies, a follower is promoted (*failover*) — risk of data loss or *split-brain*

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

== Quorum replication — W + R > N

#{
  let w-only = rgb("#c8e6c9")
  let r-only = rgb("#90caf9")
  let overlap = rgb("#ce93d8")
  let idle = rgb("#e0e0e0")

  let qnode(label, fill) = box(
    stroke: 0.8pt, radius: 4pt, inset: (x: 12pt, y: 8pt),
    fill: fill,
    text(size: 12pt, weight: "bold")[#label],
  )

  align(center,
    stack(dir: ltr, spacing: 1cm,
      qnode("N1", w-only),
      qnode("N2", w-only),
      qnode("N3", overlap),
      qnode("N4", r-only),
      qnode("N5", r-only),
    )
  )

  v(0.5em)

  align(center,
    stack(dir: ltr, spacing: 1.5cm,
      stack(dir: ltr, spacing: 4pt, rect(fill: w-only, width: 1em, height: 1em, stroke: 0.5pt), [Write (W = 3)]),
      stack(dir: ltr, spacing: 4pt, rect(fill: overlap, width: 1em, height: 1em, stroke: 0.5pt), [Overlap]),
      stack(dir: ltr, spacing: 4pt, rect(fill: r-only, width: 1em, height: 1em, stroke: 0.5pt), [Read (R = 3)]),
    )
  )
}

- *Quorum*: a minimum number of nodes that must participate in an operation
- If `W + R > N`, at least one node in every read has the latest write
- No single leader — any node can accept writes (with quorum acknowledgment)

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

== Leader/follower vs quorum — when to use which

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Leader/follower*], [*Quorum*]),
  [Write throughput], [One bottleneck], [Distributed],
  [Read scaling], [Add followers], [Any node serves reads],
  [Failover complexity], [High (leader election)], [Low (no single leader)],
  [Consistency], [Depends on sync/async], [Tunable via W, R, N],
  [Used by], [PostgreSQL, MySQL, MongoDB], [Cassandra, DynamoDB, Riak],
)

== \

#hero[Data is split and copied. \ But what can we actually guarantee?]
