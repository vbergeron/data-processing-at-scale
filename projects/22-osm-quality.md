# Project 22 — OpenStreetMap Consistency Validator with Embedded Prolog in Spark

**Extends:** Sessions 3.3 (CALM, lattices), 2.2 (Spark & query execution internals), 1.4 (data modeling)  
**Dataset:** [OpenStreetMap Changesets](../DATASETS.md#openstreetmap-changesets)  
**Stack:** Scala, Spark, tuProlog or SWI-Prolog (via JPL bridge)

## What is Prolog?

Prolog is a logic programming language where you declare **facts** and **rules**, then query them. The engine uses **unification** (structural pattern matching) and **backtracking** (exploring all proof paths) to find solutions. A key feature is **negation-as-failure** (`\+`): `\+ water(X)` succeeds if `water(X)` cannot be proven — this lets you express rules like "a building is inconsistent if it's in water *and not* tagged as man-made."

**tuProlog** is a pure-Java Prolog engine that can be embedded directly in a Spark executor (same JVM, no subprocess). **SWI-Prolog** is the full-featured reference implementation (C-based) and can be integrated via **JPL**, a bidirectional Java↔Prolog bridge that provides direct in-process calls (assert, query, iterate solutions) without spawning subprocesses.

## Context

OSM has implicit consistency rules that are hard to express as flat SQL predicates: "a building tagged `building=yes` should not be inside an area tagged `natural=water`, unless it's also tagged `man_made=yes`." These rules involve negation, composition, and spatial reasoning — a natural fit for Prolog. By embedding Prolog inside Spark `mapPartitions`, you can validate geographic consistency at continental scale.

## Objectives

1. **Preprocess** OSM data in Spark: extract nodes, ways, relations with their tags and spatial relationships (containment, adjacency) per geographic tile
2. **Embed** a Prolog engine inside `mapPartitions`: each geographic tile is loaded as Prolog facts, rules are evaluated per tile
3. **Encode** consistency rules in Prolog:
   - `inconsistent(Node) :- building(Node), inside(Node, Area), water(Area), \+ man_made(Node).`
   - `disconnected_road(Way) :- road(Way), endpoint(Way, Node), \+ connected(Node, _).`
   - `address_mismatch(Node) :- addr_city(Node, City), admin_boundary(Node, Boundary), \+ city_name(Boundary, City).`
4. **Collect** violations back into Spark, rank by severity, generate fix suggestions
5. **Benchmark** rule evaluation: throughput per tile, scaling with partition count, comparison against Spark SQL equivalent

## Questions You Should Be Able to Answer

- How do you partition OSM data spatially so that rules involving nearby objects still work at tile boundaries?
- Show a rule using Prolog negation-as-failure (`\+`). How would you express this in SQL?
- What is the throughput of Prolog validation per geographic tile? What is the dominant cost — fact assertion or inference?
- How do you handle the boundary problem: objects that span two tiles?
- Could these rules be expressed as CALM-monotonic computations? Which ones require coordination?
