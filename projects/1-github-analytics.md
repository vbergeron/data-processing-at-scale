# Project 1 — GitHub Star-Farming Ring Detection

**Extends:** Sessions 3.1 (Flink), 3.4 (ClickHouse), 4.1 (probabilistic structures)  
**Dataset:** [GH Archive](../DATASETS.md#gh-archive)  
**Stack:** Kafka, Flink, ClickHouse

## Context

Star-farming is a real problem on GitHub: coordinated groups of accounts artificially inflate repository star counts to game trending rankings and attract genuine users. These rings are adversarial — they actively try to look organic. Your job is to build a streaming pipeline that detects coordinated starring behavior by analyzing temporal and graph patterns that real users don't produce.

## Objectives

1. **Stream** GH Archive `WatchEvent` (star) events through Kafka into a Flink pipeline
2. **Detect temporal coordination**: accounts that star the same repositories within narrow time windows. Real users don't star 5 repos in the same minute as 20 other accounts
3. **Build co-starring graphs** in Flink state: for each pair of accounts, track how many repositories they have both starred. High overlap + low overall activity = suspicious
4. **Identify rings**: clusters of accounts with unusually high pairwise co-starring scores. Sink detected rings to ClickHouse with evidence (shared repos, timestamps, account ages)
5. **Score repositories**: for each repo, estimate what fraction of its stars come from suspected ring members. Flag repos where >30% of stars are suspect
6. **Validate** against known cases: find repos that were removed or flagged by GitHub. Do they appear in your results?

## Questions You Should Be Able to Answer

- Show a detected ring. What made these accounts suspicious? Could they be legitimate (e.g., a team starring their own projects)?
- How do you distinguish a real community (e.g., React developers) from a farming ring? What signals differ?
- What is the false positive rate? Show accounts your system flagged that are probably legitimate.
- How large does the co-starring state get in Flink? How do you expire old data?
- Show a repository with inflated stars. What fraction of its stars are suspect?
