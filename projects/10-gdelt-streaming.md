# Project 10 — Geopolitical Escalation Early Warning

**Extends:** Sessions 3.1 (Flink), 3.2 (windowed aggregations), 3.4 (ClickHouse)  
**Dataset:** [GDELT Project](../DATASETS.md#gdelt-project)  
**Stack:** Kafka, Flink, ClickHouse

## Context

Geopolitical crises don't appear out of nowhere — they escalate. The Goldstein scale in GDELT assigns a cooperation/conflict score to each event. A country pair shifting from positive to negative scores over days may indicate a brewing crisis. Your job is to build a Flink streaming pipeline that detects these escalation patterns.

## Objectives

1. **Stream** GDELT 15-minute update files into Kafka, replay chronologically
2. **Compute** a rolling Goldstein score per country pair using sliding windows in Flink
3. **Detect** escalation: country pairs whose rolling score crosses a threshold (e.g., drops below -5) after being positive
4. **Sink** detected escalation events into ClickHouse for historical analysis and pattern matching
5. **Validate** against known crises: does your system detect them before or after they became headline news?

## Questions You Should Be Able to Answer

- What sliding window parameters did you choose? How does the window size affect false positive rate?
- Show an escalation your system detected. When did it trigger relative to real-world events?
- How does your Flink pipeline handle a GDELT update arriving 2 hours late?
- What is the state size of your rolling score computation? How many country pairs are you tracking?
