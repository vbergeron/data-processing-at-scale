#import "../../style.typ": hero, pause

== \

#hero[You need to run code on 1 000 machines. \
What properties must your programs have?]

= A bit of history

== 1936 — λ-calculus

- Introduced by *Alonzo Church* as a framework to express computation
- Minimal by design — only three constructs
- Turing complete: equivalent in power to a Turing machine

#pause

#table(
  columns: 2,
  align: (left, left),
  table.header([*Construct*], [*Syntax*]),
  [Variable], [`x`],
  [Abstraction (lambda)], [`λx.x`],
  [Application], [`(λx.x) y`],
)

== 1936 — λ-calculus in action

Computation = rewriting expressions by substitution

```
Y := λg.(λx.g (x x)) (λx.g (x x))

Y g
→ (λx.g (x x)) (λx.g (x x))
→ g ((λx.g (x x)) (λx.g (x x)))
→ g (Y g)
```

The entire model: rename variables, substitute, repeat.

== 1958 — LISP

- Designed by *John McCarthy*, directly inspired by λ-calculus
- Dynamically typed — everything is a list
- First language with a *garbage collector*

```lisp
;; no operators — just function application
(+ 1 1)

;; anonymous functions
(lambda (x) (+ x 1))

;; definitions are lists too
(def increase (salary rate) (* salary (+ 1 rate)))
```

== 1958 — LISP and homoiconicity

#hero[
  "In a homoiconic language, the primary representation \
  of programs is also a data structure in a primitive type \
  of the language itself."
]

The program _is_ the data. Code that rewrites code is natural.

== 1973 — ML and the type revolution

- *Hindley-Milner* static type system — types are _inferred_, not written
- Spawned *OCaml* (1985, INRIA) and *Haskell* (1990)
- Pattern matching as a first-class control flow

```ml
fun fac 0 = 1
  | fac n = n * fac (n - 1)
```

Heavily influenced Scala's design.

== 2003 — Scala

#quote(attribution: [james-iry.blogspot.com])[
  "A drunken Martin Odersky sees a Reese's Peanut Butter Cup ad
  and has an idea. He creates Scala, a language that unifies
  constructs from both object-oriented and functional languages."
]

Scala = *Scalable Language* — objects for modules, functions for compute.

== FP is everywhere today

- *OCaml* — CoQ proof assistant, Jane Street's trading systems
- *Haskell* — Facebook spam filtering
- *Rust* — an ML for systems programmers
- *React hooks* — functional reactive programming in the browser
- *Scala* — the most mainstream FP language (Spark, Kafka, Flink)

== Why FP won in distributed computing

Every major distributed data framework is built on FP:

- *Spark* (Scala) — immutable RDDs, pure transformations shipped to nodes
- *Kafka Streams* (Scala/Java) — stateless stream transformations
- *Flink* (Scala/Java) — deterministic, retryable dataflow operators

#pause

This is not a coincidence. FP gives you exactly the properties \
that distributed systems need to be *correct*.
