#import "../../style.typ": hero, pause
#import "@preview/fletcher:0.5.8" as fletcher: node, edge

= Binary Row Formats

== What "row-oriented binary" means

Each record is serialized as a contiguous byte sequence. \
All fields of one row, then all fields of the next.


```
[row 0: user_id | name | amount | currency | timestamp]
[row 1: user_id | name | amount | currency | timestamp]
[row 2: user_id | name | amount | currency | timestamp]
```


Good for: writing whole records, reading whole records, streaming one-by-one. \
Bad for: reading a single column across millions of rows.

== The design axes

Binary row formats differ on four axes:


#table(
  columns: 2,
  align: (left, left),
  table.header([*Axis*], [*Question*]),
  [Schema], [Is the schema embedded, external, or negotiated?],
  [Evolution], [Can readers handle writers with a different schema version?],
  [Zero-copy], [Can you access fields without deserializing the whole record?],
)

== MessagePack & CBOR — schemaless binary

*MessagePack*: "JSON but binary." Same data model (maps, arrays, scalars), ~30% smaller.

*CBOR* (RFC 8949): IETF standard, same idea, richer type system (dates, binary blobs, tags).

- No schema, no evolution story — same flexibility (and same problems) as JSON
- Good for: caching, inter-service messages, embedded systems
- Not designed for analytical workloads

== MessagePack & CBOR — schemaless binary

JSON (27 bytes): 
```json
{ "compact": true, "schema": 0 }
```

MessagePack (18 bytes):

#align(center,
  fletcher.diagram(
    spacing: (0.85cm, 1.3cm),
    node-stroke: 0.7pt,
    node-corner-radius: 2pt,

    node((0, 0), `82`, inset: 6pt),
    node((1, 0), `A7`, inset: 6pt),
    node((2, 0), raw("compact"), stroke: none),
    node((3, 0), `C3`, inset: 6pt),
    node((4, 0), `A6`, inset: 6pt),
    node((5, 0), raw("schema"), stroke: none),
    node((6, 0), `00`, inset: 6pt),

    node((0,   1), text(size: 0.72em)[2-element map], stroke: none),
    node((1.5, 1), text(size: 0.72em)[7-byte string], stroke: none),
    node((3,   1), text(size: 0.72em)[true],          stroke: none),
    node((4.5, 1), text(size: 0.72em)[6-byte string], stroke: none),
    node((6,   1), text(size: 0.72em)[integer 0],     stroke: none),

    edge((0, 0), (0,   1), "->"),
    edge((1, 0), (1.5, 1), "->"),
    edge((2, 0), (1.5, 1), "->"),
    edge((3, 0), (3,   1), "->"),
    edge((4, 0), (4.5, 1), "->"),
    edge((5, 0), (4.5, 1), "->"),
    edge((6, 0), (6,   1), "->"),
  )
)


== Protocol Buffers — schema-first, evolution-safe

Google's serialization format. Schema defined in `.proto` files:

```protobuf
message Transaction {
  int64 user_id = 1;
  string name = 2;
  double amount = 3;
  string currency = 4;
}
```


- Fields identified by *number*, not name → very compact on the wire
- *Backward compatible*: new code can read old data (unknown fields are ignored)
- *Forward compatible*: old code can read new data (new fields get default values)

Both directions work — as long as you follow the evolution rules.

== Avro — the Hadoop ecosystem standard

Apache Avro embeds the *writer's schema* in the file header:

```json
{"type": "record", "name": "Transaction",
 "fields": [
   {"name": "user_id", "type": "long"},
   {"name": "name", "type": "string"},
   {"name": "amount", "type": "double"}
 ]}
```

- Reader provides its own schema → *schema resolution* at read time
- No tag numbers — fields matched by *name*
- The default serialization for Hadoop, Kafka

== Avro — schema evolution guarantees

Fields are matched by *name*, not number. That changes the compatibility story:

- *Backward compatible* (new code reads old data): safe if new fields have a default value — missing fields use the default.
- *Forward compatible* (old code reads new data): safe if removed fields had a default — old readers skip unknown fields.
- *Both directions*: only guaranteed if every field always carries a default.

Renaming a field *breaks compatibility* unless you declare an `alias`. \
Changing a type always breaks. \
There is no equivalent of Protobuf's "never reuse tag numbers" — name stability *is* the contract.

The schema travels *with the file*. No external schema registry needed (but one helps at scale).

== Zero-copy formats — FlatBuffers & Cap'n Proto

Most serialization formats require full deserialization before accessing any field.


*FlatBuffers* (Google) and *Cap'n Proto* (author of Protobuf v2):

- Access fields directly from the serialized buffer — no unpacking step
- Memory layout *is* the wire format
- Ideal when read latency matters more than file size


Trade-off: larger on disk (alignment padding), more complex schemas. \
Used in: game engines, mobile apps, some high-frequency trading systems. \
Rare in data pipelines.

== SQLite as a file format

SQLite is *the most deployed database engine in the world* — more instances than all other databases combined.

- One `.db` file, zero server, zero setup, zero dependencies
- Universally readable: every language has a SQLite driver
- Full SQL: filtering, joins, aggregations, window functions
- B-tree indexes: point lookups in O(log n) without scanning the file
- ACID transactions — crash-safe by default

== The row format landscape

#table(
  columns: 4,
  align: (left, center, center, center),
  table.header([*Format*], [*Schema*], [*Evolution*], [*Zero-copy*]),
  [MsgPack / CBOR], [None], [None], [No],
  [Protobuf], [External], [Tag-based], [No],
  [Avro], [Embedded], [Name-based], [No],
  [FlatBuffers], [External], [Tag-based], [Yes],
  [Cap'n Proto], [External], [Tag-based], [Yes],
  [SQLite], [Embedded], [DDL-based], [B-tree],
)

== \

#hero[Row formats are optimized for \ *writing whole records*. \
What if you mostly read single columns?]
