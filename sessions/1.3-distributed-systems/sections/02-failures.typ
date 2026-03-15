#import "../../style.typ": hero
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/cetz:0.4.2"

== A single machine is simple

#align(center,
  fletcher.diagram(
    node-stroke: 0.8pt,
    node((0, 0), [CPU], width: 3cm),
    edge("-"),
    node((1, 0), [Memory], width: 3cm),
    edge("-"),
    node((2, 0), [Disk], width: 3cm),
  )
)

- One clock, one address space, shared fate
- Failure is total: the whole machine crashes or nothing does
- Every function call returns — or the process dies

== Partial failure — the new problem

#align(center,
  fletcher.diagram(
    spacing: 3cm,
    node-stroke: 0.8pt,
    node((0, 0), [Node A], fill: rgb("#c8e6c9"), stroke: rgb("#388e3c")),
    node((1, 0), text(fill: rgb("#c62828"))[Node B ?], fill: rgb("#ffcdd2"), stroke: (paint: rgb("#c62828"), dash: "dashed")),
    node((2, 0), [Node C], fill: rgb("#c8e6c9"), stroke: rgb("#388e3c")),
    edge((0, 0), (1, 0), "->", stroke: (dash: "dashed")),
    edge((1, 0), (2, 0), "->", stroke: (dash: "dashed")),
  )
)

- Some nodes fail while others keep running
- You cannot tell if a remote node is *dead* or just *slow*
- *Partial failure* — the defining characteristic of distributed systems

== The 8 fallacies of distributed computing

#text(size: 14pt)[
  Peter Deutsch identified seven assumptions that new engineers make about networks (1994). \
  James Gosling later added the eighth.
]

#v(1em)

#text(size: 12pt, fill: luma(80))[
  _"Essentially everyone, when they first build a distributed application, makes the following eight assumptions. All prove to be false in the long run and all cause big trouble and painful learning experiences."_ 
  \ — Peter Deutsch, _The Eight Fallacies of Distributed Computing_, Sun Microsystems, 1994. \
]


== Fallacy 1 — The network is reliable

#align(center,
  fletcher.diagram(
    spacing: (5cm, 1.6cm),
    node-stroke: 0.8pt,
    // ① Happy path
    node((0, 0), [Node A]),
    node((1, 0), [Node B]),
    edge((1, 0), (0, 0), "->", [msg ✓], shift: 10pt, label-side: center),
    edge((0, 0), (1, 0), "->", [ack ✓], shift: 10pt, label-side: center),
    // ② Message lost
    node((0, 1), [Node A]),
    node((1, 1), [Node B]),
    edge((0, 1), (1, 1), "->", stroke: (paint: red), [② msg ✗], label-side: left),
    // ③ Ack lost
    node((0, 2), [Node A]),
    node((1, 2), [Node B]),
    edge((0, 2), (1, 2), "->", [③ msg ✓], shift: 10pt, label-side: center),
    edge((1, 2), (0, 2), "->", [ack ✗],    shift: 10pt, label-side: center, stroke: (paint: red))
  )
)

- A cannot distinguish case ② from case ③
- The sender *never knows* if the message was processed

== Fallacy 2 — Latency is zero

#table(
  columns: 3,
  align: (left, right, right),
  table.header([*Operation*], [*Latency*], [*CPU cycles @ 3 GHz*]),
  [L1 cache reference], [1 ns], [3],
  [RAM access], [100 ns], [300],
  [SSD random read], [100 μs], [300 000],
  [Datacenter round-trip], [500 μs], [*1 500 000*],
  [Cross-region (EU↔US)], [80 ms], [*240 000 000*],
)

- A network round-trip costs *millions* of CPU cycles
- Every RPC, every shuffle, every checkpoint pays this cost
- Batching and locality are not optimizations — they are necessities

== Fallacy 3 — Bandwidth is infinite

- A 10 Gbps link moves ~1.25 GB/s — a single Spark shuffle can saturate it
- *Noisy Neighbors*: your job competes with every other tenant
- In the cloud, cross-AZ and cross-region bandwidth is metered and throttled

== Fallacy 4 — The network is secure

- Any node on the network can send malformed data — or nothing at all
- TLS, authentication, and firewalls add latency and operational complexity
- In data pipelines, the trust boundary is often *inside* the datacenter

== Fallacy 5 — Topology doesn't change

- Nodes join and leave: autoscaling, rolling deployments, hardware failures
- IP addresses change, DNS caches go stale
- Hence the need for *Service discovery* (Consul, ZooKeeper, Kubernetes DNS) 

== Fallacy 6 — There is one administrator

- Cloud infrastructure spans teams, organizations, and providers
- Different SLAs, upgrade schedules, and security policies
- No single person controls the full path from producer to consumer

== Fallacy 7 — Transport cost is zero

- Serialization, compression, encryption — all cost CPU
- Cloud egress fees: \$0.01–0.09 per GB across regions
- Moving data is often more expensive than processing it

== Fallacy 8 — The network is homogeneous

- Datacenter links ≠ cross-region links ≠ public internet
- Different MTUs, reliability guarantees, and congestion behavior
- A pipeline tuned for one network topology may fail in another

== The 8 fallacies — recap

+ The network is reliable
+ Latency is zero
+ Bandwidth is infinite
+ The network is secure
+ Topology doesn't change
+ There is one administrator
+ Transport cost is zero
+ The network is homogeneous

#text(size: 16pt, fill: luma(100))[Peter Deutsch (+ James Gosling), 1994 — the first three dominate data processing.]

== Failure taxonomy

  - *Crash failure*: Node stops responding -> Most systems handle this, 
  - *Omission failure*: Node loose messages -> TCP masks some of these, 
  - *Byzantine failure*: Node sends malicious messages

== Failure taxonomy

- Most data systems only tolerate *crash* failures
- Byzantine fault tolerance exists (*BFT*) using crytography
- If you are asked for a practical case for *blockchains*, this is it.

== Timeouts — guessing at failure

#align(center,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (16, 0), stroke: 0.8pt, mark: (end: ">"))
    content((16.5, 0), text(size: 10pt)[time])

    // request sent
    line((2, -0.3), (2, 0.3), stroke: 1pt)
    content((2, 0.8), text(size: 10pt)[request sent])

    // uncertainty zone
    rect((4, -0.6), (14, 0.6), fill: rgb("#fff3e0"), stroke: none)
    content((9, 0), text(size: 10pt, fill: luma(100))[uncertainty zone — is the peer dead or slow?])

    // aggressive timeout
    line((6, -0.8), (6, 0.8), stroke: (paint: rgb("#e53935"), dash: "dashed", thickness: 1.5pt))
    content((6, -1.3), text(size: 9pt, fill: rgb("#e53935"))[aggressive timeout \ → false positives])

    // conservative timeout
    line((12, -0.8), (12, 0.8), stroke: (paint: rgb("#1565c0"), dash: "dashed", thickness: 1.5pt))
    content((12, -1.3), text(size: 9pt, fill: rgb("#1565c0"))[conservative timeout \ → slow recovery])
  })
)

- *Failure detector* — a component that guesses whether a remote node is alive
- Too aggressive → healthy nodes declared dead (thrashing)
- Too conservative → long outages before recovery starts

