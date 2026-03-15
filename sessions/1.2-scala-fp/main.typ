#import "../style.typ": *

#show: dpas-theme.with(title: [1.2 — Distributed Programming with Scala], day: [Day 1], slug: "1.2-scala-fp", lab: "1.2-single-node-benchmark")

// From λ-calculus to Scala — why FP exists
#include "sections/01-history.typ"

// What Scala is and where it runs
#include "sections/02-what-is-scala.typ"

// The four principles: functions as values, immutability, referential transparency, purity
#include "sections/03-fp-principles.typ"

// Encoding domain models with traits, ADTs, and generics
#include "sections/04-data-modeling.typ"

// Recap & closing
#include "sections/05-vocabulary.typ"
