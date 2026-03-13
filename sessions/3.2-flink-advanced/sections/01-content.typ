== Windowing

- Tumbling windows
- Sliding windows
- Session windows

== Watermarks & Late Data

- Watermark generation strategies
- Allowed lateness
- Side outputs for late arrivals

== Stateful Processing

- Keyed state vs operator state
- State backends: HashMapStateBackend, RocksDB
- State size and expiration

== Checkpointing & Savepoints

- Chandy-Lamport algorithm
- Exactly-once semantics end-to-end
- Savepoints for versioned deployment

== Backpressure & Flow Control

- How Flink propagates backpressure
- Credit-based flow control
- Diagnosing backpressure in the Flink UI

== Demo

*Implementing windowed aggregations with watermarks in Flink*
