#import "../../style.typ": hero, pause

= Text Formats

== CSV — the universal lowest common denominator

```
user_id,name,amount,currency,timestamp
42,Alice,19.99,EUR,2024-03-15T10:30:00Z
43,Bob,1250.00,USD,2024-03-15T10:31:12Z
```


- No standard. RFC 4180 exists — almost nobody follows it exactly.
- No types: is `42` an integer, a string, a float?
- No nested structures
- Delimiter collisions: what if a field contains a comma?

== CSV — what it's good at

CSV is often a pragmatic choice for human-interrop.
#v(0.5em)
- *Universal*: every tool reads CSV. Excel, Python, `awk`, databases.
- *Streamable*: you can process line-by-line without loading the whole file
- *Debuggable*: open it in a text editor (or better, with SQLite)



== JSON — self-describing and nested

```json
{
    "user_id": 42, 
    "name": "Alice", 
    "amount": 19.99,
    "currency": "EUR", 
    "address": {
        "city": "Paris", 
        "zip": "75001"
    }
}
```


- *Self-describing*: field names travel with the data
- *Nested*: objects and arrays — richer than flat CSV
- *Typed* (partially): numbers, strings, booleans, null — but no integers vs floats, no dates

== JSON — the cost of self-description

```json
{"user_id": 42, "name": "Alice", "amount": 19.99}
{"user_id": 43, "name": "Bob", "amount": 1250.00}
{"user_id": 44, "name": "Carol", "amount": 7.50}
```

Field names can account for *more bytes than the data itself*.

== NDJSON — JSON for pipelines

Newline-Delimited JSON: one JSON object per line.

```json
{"user_id": 42, "name": "Alice", "amount": 19.99}
{"user_id": 43, "name": "Bob", "amount": 1250.00}
```


- *Splittable*: any line boundary is a valid split point
- *Appendable*: just add a line
- *Streamable*: process record by record


This is the default format for GH Archive, log pipelines, and most streaming ingestion.

== \

#hero[Text formats trade efficiency for readability. \
At scale, that trade stops being worth it.]
