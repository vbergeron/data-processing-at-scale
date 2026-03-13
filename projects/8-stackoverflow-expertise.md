# Project 8 — Distributed Faceted Search with Embedded Lucene in Spark

**Extends:** Sessions 2.2 (Spark & query execution internals), 1.4 (data modeling), 2.1 (storage formats)  
**Dataset:** [Stack Exchange Data Dump](../DATASETS.md#stack-exchange-data-dump)  
**Stack:** Scala, Spark, Apache Lucene (embedded)

## What is Apache Lucene?

Apache Lucene is a Java library for full-text search — not a server, but a library you embed in your own code. It provides inverted indexes (mapping terms to documents), BM25 relevance scoring (a TF-IDF successor that accounts for document length), and faceted search (computing category counts at query time, like "3,204 results in `java`, 1,891 in `python`"). Elasticsearch and Solr are servers *built on top of* Lucene, but here you'll use the library directly inside Spark executors.

## Context

Because Lucene is just a JAR, it can run inside any JVM process — including a Spark executor. By embedding Lucene inside `mapPartitions`, each Spark partition builds its own local index, and queries fan out across partitions. Your job is to build this distributed search pipeline over Stack Overflow data in Scala-Spark.

## Objectives

1. **Build distributed indexes** using `mapPartitions`: each Spark partition creates a Lucene index over its slice of SO posts (title, body, tags, score, date)
2. **Implement BM25 search** inside Spark: a query is broadcast to all executors, each searches its local Lucene index, results are merged and ranked globally
3. **Add faceted navigation**: use Lucene's `FacetsCollector` inside each partition, aggregate facet counts (by tag, by year, by score range) in the Spark driver
4. **Benchmark** against Spark SQL `LIKE` and ClickHouse full-text: compare latency, relevance, and memory footprint
5. **Persist and reload** the distributed index: write Lucene indexes to HDFS/S3 alongside Parquet data

## Questions You Should Be Able to Answer

- How does `mapPartitions` differ from `map` for Lucene index construction? Why does it matter?
- How do you merge BM25 scores from different partitions into a globally correct ranking?
- What is the memory footprint of a Lucene index per partition vs the equivalent Parquet data?
- Show a query where Lucene ranking differs from a SQL `ORDER BY score`. Why?
- How would you handle index updates when new posts arrive without rebuilding everything?
