# Project 23 — Web-Scale Search Pipeline with Embedded Lucene in Spark

**Extends:** Sessions 2.2 (Spark & query execution internals), 2.1 (storage formats), 4.1 (probabilistic structures)  
**Dataset:** [Common Crawl](../DATASETS.md#common-crawl)  
**Stack:** Scala, Spark, Apache Lucene (embedded)

## What is Apache Lucene?

Apache Lucene is a Java library (not a server) for full-text search. Core concepts: an **inverted index** maps each term to the list of documents containing it; **BM25** scores documents by relevance (term frequency normalized by document length); **facets** compute taxonomy counts ("how many results per category?") at query time using a `FacetsCollector`. Lucene runs in-process — you create an `IndexWriter`, add documents, and search with an `IndexSearcher`, all from your own JVM code.

## Context

Indexing billions of web pages requires distributing the work. Since Lucene is a library, each Spark executor can build its own index shard in `mapPartitions`, producing a set of sharded Lucene indexes as a natural output of a Spark job. Your job is to build this end-to-end pipeline: preprocess web pages, build distributed Lucene indexes, and query across shards.

## Objectives

1. **Preprocess** Common Crawl data in Spark: parse HTML (strip tags, extract text), extract metadata (title, domain, language, server header), partition by domain or hash
2. **Index** each partition into an embedded Lucene index using `mapPartitions`: multi-field schema (body, title, domain, language, content_type)
3. **Query** across all shards: broadcast query, collect top-K per shard, merge into global top-K with correct BM25 scoring
4. **Build facets** inside Lucene: taxonomy counts by TLD, by server technology, by language — aggregated across shards in the driver
5. **Measure** indexing throughput: how does it scale with Spark parallelism? What is the bottleneck — Lucene indexing or HTML parsing?

## Questions You Should Be Able to Answer

- How do you partition the data for indexing? What are the trade-offs of hash vs domain-based partitioning?
- Show the code path from a query string to merged results. Where does the Spark shuffle happen (or not)?
- What is the total index size across all shards vs the original Parquet data? How does Lucene compression compare?
- How do you handle the fact that IDF (inverse document frequency) is per-shard, not global? Does it affect ranking quality?
- What happens if one shard is 10x larger than others? How does it affect query latency?
