#import "../../style.typ": hero

== Vocabulary recap

#table(
  columns: 2,
  align: (left, left),
  table.header([*Term*], [*Definition*]),
  [*First-class function*], [A function that can be passed, returned, and assigned like any value],
  [*Higher-order function*], [A function that takes or returns another function],
  [*Immutability*], [Values never change after creation — enables safe replication],
  [*Side effect*], [An action that modifies state outside the function's scope],
  [*Referential transparency*], [An expression replaceable by its value — enables retries & caching],
  [*Pure function*], [Deterministic + total + no side effects — enables safe distribution],
  [*ADT*], [Algebraic Data Type — products (and) + sums (or) for domain modeling],
  [*Case class*], [Serializable product type — your distributed data contract],
  [*Sealed trait / enum*], [Exhaustive sum type — no unknown messages at runtime],
  [*Ship code to data*], [Send functions to nodes instead of moving data — the FP-enabled pattern],
)

== \

#hero[FP is not a paradigm preference. \
It is the engineering foundation \
that makes distributed data processing work.]
