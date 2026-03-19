#import "../style.typ": *

#show: dpas-theme.with(title: [2.1 — Storage Formats & Distributed File Systems], day: [Day 2], slug: "2.1-storage-formats", lab: "2.1-file-formats", next: "2.2-spark")

// You built MapReduce — now what's inside the files?
#include "sections/01-mapreduce-to-files.typ"

// CSV, JSON, NDJSON — universality at a cost
#include "sections/02-plaintext.typ"

// Avro, Protobuf, and the binary row format landscape
#include "sections/03-row-formats.typ"

// Parquet deep dive, ORC, Arrow, Lance
#include "sections/04-columnar-formats.typ"

// Iceberg, Delta Lake, Hudi — metadata on top of files
#include "sections/05-lakehouse.typ"

// Recap & closing
#include "sections/06-vocabulary.typ"
