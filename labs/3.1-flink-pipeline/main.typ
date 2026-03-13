#import "../style.typ": *

#show: lab-theme.with(
  title: [Demo 3.1 — Building a Flink Pipeline on a Kafka Source],
  session: [Session 3.1 — Apache Flink: Stream Processing Engine],
  format: [Instructor-led hands-on demo],
  tools: [Docker Compose, Apache Kafka, Apache Flink, Flink SQL Client],
)

= Objective

Show how Flink consumes from Kafka and processes events as a stream. Students already know Kafka — this demo focuses on what happens _after_ events leave the topic: Flink's runtime, parallelism, and the DataStream/SQL APIs.

= Setup

- Kafka cluster (reused from students' prior course or a simple Docker Compose setup)
- A producer emitting JSON events (e.g., web clickstream) into a Kafka topic
- Flink cluster in Docker Compose (JobManager + 2 TaskManagers)
- Flink SQL Client for interactive queries

= Walkthrough

== Step 1 — Flink SQL on Kafka

Connect Flink SQL to the Kafka topic as a source:
- `CREATE TABLE` with Kafka connector, define schema and watermark
- `SELECT * FROM events` — show events flowing in real time
- Simple aggregation: `SELECT user_id, COUNT(*) FROM events GROUP BY user_id` — observe continuous output

== Step 2 — Flink architecture

While the query runs, explore the Flink Web UI:
- JobManager: the job graph, how operators are chained
- TaskManagers: parallelism, slots, task distribution
- Show how Flink maps SQL operators to a physical execution graph

== Step 3 — Parallelism and Kafka partitions

- Set Flink parallelism to match Kafka partition count — show 1:1 mapping
- Increase parallelism beyond partition count — some subtasks are idle
- Decrease parallelism — some subtasks handle multiple partitions
- Observe throughput changes in the Flink UI

== Step 4 — DataStream API

Switch from SQL to the DataStream API (Python/PyFlink or Java):
- Same Kafka source, but with programmatic transformations
- Show: map, filter, keyBy, process functions
- Compare verbosity and flexibility vs Flink SQL

== Step 5 — Exactly-once with Kafka

- Enable checkpointing in Flink
- Show the Kafka consumer offset being committed _with_ the checkpoint, not independently
- Kill a TaskManager mid-processing — observe recovery from checkpoint
- Verify: no duplicates, no data loss

= Key Takeaways

- Flink is where the processing logic lives — Kafka is the transport
- Flink SQL provides a low-barrier entry point; DataStream API gives full control
- Parallelism in Flink is tied to Kafka partition count for source operators
- Checkpointing is what enables exactly-once: it ties Kafka offsets to Flink's internal state
