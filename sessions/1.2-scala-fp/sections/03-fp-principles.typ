#import "../../style.typ": hero, pause

== \

#hero[Four principles make FP code reliable \
on one machine — and _necessary_ \
on a thousand.]

= Principles of FP

== \

#hero[1 — Function as a value]

== Functions in Scala — three ways

```scala
// Standard function declaration
def f(n: Int): Int = n + 1

// Lambda expression
val f: Int => Int = n => n + 1

// Short lambda syntax
val f: Int => Int = _ + 1
```

All three are equivalent. A function is a *value* you can pass around.

== Why function as value matters

The problem: repeated structure, only the operation changes.

```scala
def multiplyBy4(values: List[Int]): List[Int] =
  for (value <- values) yield value * 4

def add26(values: List[Int]): List[Int] =
  for (value <- values) yield value + 26

def sub42(values: List[Int]): List[Int] =
  for (value <- values) yield value - 42
```

== Extracting the pattern

Put the operation *in parameter*:

```scala
def map(f: Int => Int)(values: List[Int]): List[Int] =
  for (value <- values) yield f(value)
```

#pause

```scala
def multiplyBy4 = map(_ * 4)
def add26       = map(_ + 26)
def sub42       = map(_ - 42)
```

One change point. One place to test. *DRY*.

== A note on readability

Chaining can produce dense one-liners:
```scala
text.split("\n").toList.filter(_.trim.nonEmpty).map(_.toUpperCase).mkString("\n")
```

#pause

Prefer intermediate values and line breaks:
```scala
val lines = text.split("\n").toList
lines
  .filter(_.trim.nonEmpty)
  .map(_.toUpperCase)
  .mkString("\n")
```

== Function as value — summary

- A function is a *first-class citizen* — it can be passed, returned, assigned
- Enables *higher-order functions*: functions that take or return functions
- Result: more concise, more readable, easier to maintain and test

== Function as value — the distributed payoff

In a cluster, data is too large to move. You *ship the function to the data*.

```scala
// local — runs on your machine
val result = records.map(r => r.amount * 1.2)

// Spark — same syntax, runs on 100 nodes
val result = rdd.map(r => r.amount * 1.2)
```

#pause

This only works because `r => r.amount * 1.2` is a *value* — \
it can be serialized, sent over the network, and executed on a remote JVM.

== \

#hero[2 — Immutability]

== `val` vs `var`

```scala
val a = 2  // immutable — cannot be reassigned
var b = 2  // mutable — avoid this
```

#pause

- Avoid: `var a = 2; /* ... */ a = 4`
- Prefer: `val a = 2; /* ... */ val b = 4`

#hero[Nothing changes, and this changes everything.]

== Why immutability?

#table(
  columns: 3,
  align: (left, center, center),
  table.header([], [*Mutable*], [*Immutable*]),
  [Performance], [Optimizable ✓], [Forced copying ✗],
  [Readability], [Side effects ✗], [Predictable ✓],
  [Concurrency], [Locks, races ✗], [Safe sharing ✓],
  [Debugging], [State depends on history ✗], [Value is the truth ✓],
)

== Side effects — the hidden danger

A *side effect* is an action that escapes the function's scope.

```scala
var x = 0
def totallyNotAffectingX(n: Int): Int =
  x += 1
  n + 1

totallyNotAffectingX(42) // 43
assert(x == 0)           // Boom!
```

#pause

Effect catalog: mutation of global state, IO, exceptions.

== Side effects — the extreme case

```scala
def makeCoffee(beans: CoffeeBeans, water: Water): Coffee =
  val powder   = grindCoffee(beans)
  val hotWater = heatWaterUp(water)
  launchRocket() // hidden side effect
  filterCoffee(powder, hotWater)
```

You can't tell from the signature what this function _actually does_.

== Mutable bank account

```scala
class BankAccount(initial: BigDecimal):
  private var balance = initial
  def withdraw(amount: BigDecimal): Unit =
    balance -= amount
  def deposit(amount: BigDecimal): Unit =
    balance += amount
```

#pause

```scala
val account1 = BankAccount(100)
account1.deposit(10)
val account2 = account1      // shared reference!
account2.withdraw(30)
println(account1.balance)    // 80 — surprised?
```

== Immutable bank account

```scala
class BankAccount(val balance: BigDecimal):
  def withdraw(amount: BigDecimal): BankAccount =
    BankAccount(balance - amount)
  def deposit(amount: BigDecimal): BankAccount =
    BankAccount(balance + amount)
```

#pause

```scala
val account1 = BankAccount(100)
val account2 = account1.deposit(10)
val account3 = account2.withdraw(20).withdraw(30)
println(account1.balance)  // 100 — unchanged
println(account2.balance)  // 110
println(account3.balance)  // 60
```

== Immutable collections in Scala

```scala
// List (immutable by default)
val cities = List("Paris", "Madrid", "London")
cities.appended("Roma")  // new list — original unchanged

// Map (immutable by default)
val ages = Map("Jon" -> 32, "Mary" -> 35)
ages.updated("Jon", 33)  // new map — original unchanged
```

`scala.collection.immutable` is the default import.

== Immutability and the JVM

- Immutability creates many short-lived objects
- The JVM's *generational garbage collector* is optimized for exactly this
- First GC ever was built for LISP — this is a solved problem

#pause

Immutability + GC = no locks, no deadlocks, safe concurrency.

== Immutability — the distributed payoff

On a single machine, mutability causes bugs. \
On a cluster, it causes *impossibility*.

#pause

- *Partitioned data*: each node holds a copy — mutation means synchronizing all copies
- *Task retries*: if a node dies mid-mutation, the data is in an unknown state
- *Parallel reads*: mutable state requires distributed locks (slow, fragile, deadlock-prone)

#pause

Immutable data can be *replicated*, *cached*, and *reprocessed freely*. \
This is why Spark's RDDs are immutable by design.

== \

#hero[3 — Referential transparency]

== Referential transparency

#hero[
  An expression is *referentially transparent* \
  if it can be replaced by its value \
  with no change in behavior.
]

== Referential transparency in practice

```scala
def countEven(l: List[Int]): Int = l.count(_ % 2 == 0)
```

#pause

```scala
// hard to read
countEven(List(1,4,3,6,8,2,3)) * (1 + 2 * countEven(List(1,4,3,6,8,2,3)))
```

#pause

```scala
// introduce variables freely — behavior is identical
val l     = List(1, 4, 3, 6, 8, 2, 3)
val count = countEven(l)
count * (1 + 2 * count)
```

Referential transparency = *fearless refactoring*.

== Referential transparency — the distributed payoff

If an expression can be replaced by its value, then:

- A *failed task* can be re-executed on another node — same input, same output
- Results can be *cached* and reused without re-computing
- The scheduler can *speculate*: run the same task on two nodes, take whoever finishes first

#pause

Spark does all three. This is only safe because transformations are \
referentially transparent.

== When it breaks: `Random`

```scala
// three calls → three different values
List(Random.nextInt(100), Random.nextInt(100), Random.nextInt(100))
// List(30, 42, 90)
```

#pause

```scala
// one call extracted → three identical values (wrong!)
val value = Random.nextInt(100)
List(value, value, value)
// List(77, 77, 77)
```

`Random.nextInt` is *not* referentially transparent.

== Fixing the `Random` example

Delay execution by wrapping in a function:

```scala
val randomInt = () => Random.nextInt(100)
List(randomInt, randomInt, randomInt).map(f => f())
// List(77, 90, 70) — correct
```

The _description_ of the computation is referentially transparent, \
even if the _execution_ is not.

== \

#hero[4 — Pure functions]

== Determinism

A *deterministic* function always returns the same output for the same input.

```scala
// deterministic
def f(n: Int): Int = n + 1

// NOT deterministic — depends on external randomness
def g(n: Int): Int = Random.nextInt(n)
```

== Totality

A *total* function is defined for every input of its declared type.

```scala
// partial — fails for negative input
def sqrt(x: Double): Double = Math.sqrt(x)

// total — uses Option to signal absence
def sqrt(x: Double): Option[Double] =
  if x >= 0 then Some(Math.sqrt(x)) else None
```

#pause

Strategy: use the *type system* to make illegal states unrepresentable.

== Pure functions

A *pure function* is deterministic + total + side-effect free.

#pause

- Pure functions are *referentially transparent*
- Pure functions are *easy to refactor*
- Pure functions are *simple to test*

#pause

In practice: pure core, impure edges. Push IO to the *frontier* of your program.

== Purity — the distributed payoff

A pure function makes distributed execution *trivial*:

- *Partition*: apply `f` independently to each shard — no coordination needed
- *Retry*: re-run `f` on failure — no side effects to undo
- *Reorder*: execute partitions in any order — result is the same

#pause

Non-pure functions break all three. A function that writes to a database \
cannot be safely retried without risking duplicates.

== Principles of FP — key takeaways

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Principle*], [*Local benefit*], [*Distributed benefit*]),
  [Function as value], [DRY, expressivity], [Ship code to data nodes],
  [Immutability], [No side effects], [Safe replication & caching],
  [Referential transparency], [Fearless refactoring], [Safe retries & speculation],
  [Pure functions], [Testability], [Partition, retry, reorder freely],
)

#pause

FP is not an academic preference — it is the *minimal set of properties* \
that make distributed data processing correct.
