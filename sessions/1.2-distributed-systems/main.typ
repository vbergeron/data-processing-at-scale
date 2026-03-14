#import "../style.typ": *

#show: dpas-theme.with(title: [1.2 — Distributed Systems Fundamentals], day: [Day 1], slug: "1.2-distributed-systems", lab: "1.2-distributed-kv")

// Too big — splitting data across nodes
#include "sections/03-partitioning.typ"

// Too fragile — why distribution is hard
#include "sections/01-failures.typ"

// Too complex — copying data for durability & availability
#include "sections/04-replication.typ"

// What trade-offs — CAP theorem & consistency models
#include "sections/02-cap-consistency.typ"

// Recap & closing
#include "sections/05-vocabulary.typ"
