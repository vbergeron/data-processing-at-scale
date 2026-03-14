#import "../style.typ": *

#show: dpas-theme.with(title: [1.5 — Cost Modeling & Performance Reasoning], day: [Day 1], slug: "1.5-cost-modeling", lab: "1.5-cost-modeling")

// The memory and storage hierarchy
#include "sections/01-storage-hierarchy.typ"

// Access patterns, columnar vs row
#include "sections/02-access-patterns.typ"

// Parallelism, Amdahl's law, scaling
#include "sections/03-parallelism.typ"

// Back-of-the-envelope estimation
#include "sections/04-estimation.typ"

// Recap & closing
#include "sections/05-vocabulary.typ"
