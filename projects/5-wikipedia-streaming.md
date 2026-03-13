# Project 5 — Wikipedia Vandalism Detection

**Extends:** Sessions 3.1 (Flink), 3.2 (windowed aggregations, watermarks)  
**Dataset:** [Wikimedia EventStreams](../DATASETS.md#wikimedia-eventstreams)  
**Stack:** Kafka, Flink, Python

## Context

Wikipedia is under constant attack from vandals: spam insertions, page blanking, offensive content. Detecting this in real time is critical. Your job is to build a Flink streaming pipeline that scores edits for vandalism likelihood based on behavioral and content signals.

## Objectives

1. **Ingest** the Wikimedia SSE stream into Kafka (live or replayed from a recorded file)
2. **Extract** vandalism signals per edit: anonymous vs registered, edit size delta, revert frequency for the page, edit rate of the user (session windows)
3. **Score** each edit with a vandalism likelihood based on signal combination
4. **Track** user editing sessions (session windows) to detect burst editing patterns typical of vandals
5. **Measure** detection quality: compare flagged edits against actual reverts in the stream

## Questions You Should Be Able to Answer

- What signals best predict vandalism? Show true positive and false positive examples.
- How does your session window define "end of session"? What gap did you choose and why?
- What is the state size of your per-user session tracking after 24h?
- How does your watermark configuration affect detection latency? What if a legitimate edit arrives late?
