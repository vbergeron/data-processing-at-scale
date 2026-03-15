#import "../../style.typ": hero, pause

== \

#hero[Your data travels across nodes. \
How do you make it self-describing \
and safe?]

= Data Modeling

== What is data modeling?

- Encoding your domain into *structures* and *behavior*
- No function writing yet — just the shape of your data
- Three questions:
  + What are the objects I manipulate?
  + Which ones are *behaviors* (open) vs *data structures* (closed)?
  + Which ones manipulate others vs are manipulated?

== Encoding behavior: traits

*Traits* define a contract — implementations provide the behavior.

```scala
trait Fighter:
  def attack: String
  def defend: String

class Warrior extends Fighter:
  def attack = "Sword strike"
  def defend = "Shield block"

class Barbarian extends Fighter:
  def attack = "Big stick smash"
  def defend = "Defense is for weaklings"
```

== Composition over inheritance

Traits compose — no need for deep class hierarchies.

```scala
trait Healer:
  def heal: String

class Paladin extends Fighter, Healer:
  def attack = "Sword strike"
  def defend = "Shield block"
  def heal   = "Full life"
```

Multiple traits, flat structure, explicit capabilities.

== Sealed traits — compile-time safety

```scala
sealed trait Suit
object `♣` extends Suit
object `♠` extends Suit
object `♥` extends Suit
object `♦` extends Suit
```

#pause

```scala
def isBlack(suit: Suit) = suit match
  case `♣` | `♠` => true
  case `♥`       => false
  // compiler warns: match may not be exhaustive
```

`sealed` = the compiler *knows all cases* and enforces exhaustiveness.

== Product types and sum types

#table(
  columns: 3,
  align: (left, left, left),
  table.header([*Kind*], [*Meaning*], [*Domain size*]),
  [Product], [A *and* B and C], [|A| × |B| × |C|],
  [Sum], [A *or* B or C], [|A| + |B| + |C|],
)

#pause

Together they form *Algebraic Data Types* (ADTs) — \
the building blocks of FP data modeling.

== Product types in Scala

Tuples and *case classes*:

```scala
val a: (String, Int) = ("foo", 123)

case class User(name: String, age: Int)
val b = User("Gandalf", 2587)
```

A `case class` gives you: immutability, `equals`, `hashCode`, `toString`, \
pattern matching, and `copy` — for free.

In Spark, case classes _are_ your row schema — the type system \
becomes your distributed data contract.

== Sum types in Scala

Sealed traits and *enums*:

```scala
sealed trait Suit
case object `♣` extends Suit
case object `♠` extends Suit
case object `♥` extends Suit
case object `♦` extends Suit
```

#pause

Or with Scala 3 syntax:

```scala
enum Suit:
  case `♣`, `♠`, `♥`, `♦`
```

== Mixing products and sums

```scala
trait Color
sealed trait Red extends Color
sealed trait Black extends Color

enum Suit:
  case `♣` extends Suit, Black
  case `♠` extends Suit, Black
  case `♥` extends Suit, Red
  case `♦` extends Suit, Red
```

Type hierarchies encode *domain constraints* that the compiler enforces.

In distributed systems, these constraints survive serialization — \
a malformed message is rejected *at compile time*, not at 3 AM.

== Generic types

Classes, traits, and enums can have *type parameters*:

```scala
case class Page[A](items: Seq[A], token: Option[String]):
  def map[B](mapping: A => B): Page[B] =
    Page(items.map(mapping), token)
```

#pause

A `Page[User]` and a `Page[Order]` share structure — \
the logic is written once, the type ensures correctness.

== Generic types — bounds

Type parameters can be *constrained*:

```scala
trait Spawnable[A]:
  def make: A

def spawnChild[A, B <: Spawnable[A]](parent: B): A =
  parent.make
```

`B <: Spawnable[A]` means: `B` must be a subtype of `Spawnable[A]`.

For all types: `Nothing <: A <: Any`.

== Data modeling — the distributed payoff

#table(
  columns: 2,
  align: (left, left),
  table.header([*FP construct*], [*Distributed role*]),
  [Case class], [Serializable row / message — travels across nodes],
  [Sealed trait / enum], [Exhaustive event types — no unknown messages at runtime],
  [Generics], [Type-safe pipelines — `Dataset[Order]` not `Dataset[Any]`],
  [Pattern matching], [Safe routing of events in stream processing],
)

#pause

Your types are your *distributed contract*. \
The compiler checks it — the network doesn't.
