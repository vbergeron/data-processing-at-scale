#import "../style.typ": *

#show: dpas-theme.with(title: [1.4 — Data Modeling at Scale], day: [Day 1], slug: "1.4-data-modeling", lab: "1.4-star-schema")

// Why modeling changes at scale
#include "sections/01-why-modeling-changes.typ"

// Star schemas, fact tables, dimension tables
#include "sections/02-star-schemas.typ"

// Normalization vs denormalization trade-offs
#include "sections/03-normalization-denormalization.typ"

// Recap & closing
#include "sections/04-vocabulary.typ"
