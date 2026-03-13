# Project 18 — Reddit Narrative Cross-Pollination Tracker

**Extends:** Sessions 3.1 (Flink), 3.2 (windowed aggregations), 4.1 (probabilistic structures)  
**Dataset:** [Reddit (Pushshift Archive)](../DATASETS.md#reddit-pushshift-archive)  
**Stack:** Kafka, Flink, Python

## Context

Ideas and memes don't stay in one subreddit — they spread. Tracking how a topic migrates from a niche community to mainstream subreddits is an information diffusion problem. Your job is to build a streaming pipeline that detects when a keyword or topic crosses subreddit boundaries.

## Objectives

1. **Replay** Reddit comments chronologically into Kafka
2. **Track** keyword/topic first-appearance per subreddit using Bloom filters (has this subreddit seen this term before?)
3. **Detect** cross-pollination events: when a term first seen in subreddit A appears in subreddit B within a time window
4. **Compute** diffusion speed: time lag between first appearance in origin and destination subreddits
5. **Visualize** diffusion graphs: which subreddits are "originators" and which are "followers"?

## Questions You Should Be Able to Answer

- How does your Bloom filter handle the growing vocabulary? What is the false positive rate after 1 month?
- Show a real diffusion event from the data. What was the origin subreddit and how fast did it spread?
- What window type do you use for cross-pollination detection? Why?
- How do you distinguish a term spreading organically from one that's just universally common?
