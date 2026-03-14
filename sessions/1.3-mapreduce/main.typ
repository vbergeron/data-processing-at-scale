#import "../style.typ": *

#show: dpas-theme.with(title: [1.3 — Batch Processing: MapReduce & Beyond], day: [Day 1], slug: "1.3-mapreduce", lab: "1.3-mapreduce")

// The MapReduce programming model
#include "sections/01-mapreduce-model.typ"

// Shuffle mechanics, sort, combiners
#include "sections/02-shuffle-internals.typ"

// Limitations of MapReduce
#include "sections/03-limitations.typ"

// From Hadoop to modern DAG engines
#include "sections/04-beyond-mapreduce.typ"

// Recap & closing
#include "sections/05-vocabulary.typ"
