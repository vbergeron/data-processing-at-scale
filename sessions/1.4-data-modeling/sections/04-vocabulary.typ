#import "../../style.typ": hero

== \

#hero[Why can't you just normalize everything? \
Because reads and writes have \ *different* cost models.]

== One sentence to remember

#hero[
  The schema is not a description of the data — \
  it's a *bet on how the data will be queried*.
]

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*Star schema*], [A central fact table surrounded by dimension tables],
  [*Fact table*], [Stores measurable events — narrow, very tall, append-heavy],
  [*Dimension table*], [Stores descriptive context — wide, short, slowly changing],
  [*Surrogate key*], [A synthetic key decoupled from source system identifiers],
  [*Denormalization*], [Embedding related data into one table to eliminate joins],
  [*Write amplification*], [One logical update causing many physical writes],
  [*Pre-aggregation*], [Storing pre-computed summaries for faster reads],
  [*Wide table*], [Fully flattened denormalized table — no joins needed],
  [*Grain*], [The finest level of detail in a fact table],
  [*SCD (Slowly Changing Dimension)*], [A dimension that tracks historical changes over time],
)
