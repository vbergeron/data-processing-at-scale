#import "../style.typ": *

#show: dpas-theme.with(title: [1.3 — Distributed Systems Fundamentals], day: [Day 1], slug: "1.3-distributed-systems", lab: "1.3-distributed-kv")

// Too big — splitting data across nodes
#include "sections/01-partitioning.typ"

// Too fragile — why distribution is hard
#include "sections/02-failures.typ"

// What trade-offs — CAP theorem & consistency models
#include "sections/03-cap-consistency.typ"

// Too complex — copying data for durability & availability
#include "sections/04-replication.typ"

// Recap & closing
#include "sections/05-vocabulary.typ"
