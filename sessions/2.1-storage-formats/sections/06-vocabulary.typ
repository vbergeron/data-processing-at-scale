#import "../../style.typ": hero

== One sentence to remember

#hero[
  The file format is a design-time bet \ on your query pattern. \
  *Get it right and every query benefits for free.*
]

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*Row-oriented*], [Fields of a record stored contiguously],
  [*Column-oriented*], [All values of a field stored contiguously],
  [*Self-describing*], [Format carries its own schema (JSON, Avro files)],
  [*Schema evolution*], [Readers and writers can use different schema versions safely],
  [*Predicate pushdown*], [Skipping data based on column statistics without reading it],
  [*Projection pruning*], [Reading only the columns needed by a query],
  [*Table format*], [Metadata layer (Iceberg, Delta, Hudi) that gives ACID and schema to file collections],
  [*Time travel*], [Querying a table as it existed at a past point in time via snapshot metadata],
)
