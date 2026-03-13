# Project 17 — Reddit Toxicity Scoring with Embedded ONNX in Spark

**Extends:** Sessions 2.2 (Spark & query execution internals), 1.4 (data modeling), 2.1 (storage formats)  
**Dataset:** [Reddit (Pushshift Archive)](../DATASETS.md#reddit-pushshift-archive)  
**Stack:** Scala, Spark, ONNX Runtime (embedded)

## What is ONNX Runtime?

ONNX (Open Neural Network Exchange) is a standard format for ML models — you train in PyTorch, TensorFlow, or scikit-learn, then export to a `.onnx` file. **ONNX Runtime** is a high-performance inference engine (C++ with Java bindings) that loads these models and runs predictions. Because it's a library (not a server), you can embed it inside any JVM process — including a Spark executor. This lets you score every row of a DataFrame against a pre-trained model, distributed across the cluster, without a separate model-serving infrastructure.

## Context

Reddit has billions of comments, and community health depends on detecting toxic content. Pre-trained text classification models (e.g., a fine-tuned DistilBERT for toxicity) can score each comment — but running inference on millions of rows requires distributing the work. By embedding ONNX Runtime inside Spark `mapPartitions`, each executor loads the model once and scores its partition of comments. Your job is to build this inference pipeline.

## Objectives

1. **Export** a pre-trained toxicity classifier to ONNX format (provided, or train your own small model in PyTorch and export)
2. **Embed** ONNX Runtime inside Spark `mapPartitions`: load the model once per partition, tokenize and score each comment
3. **Score** 1+ month of Reddit comments for toxicity: output a score per comment alongside the original metadata (subreddit, author, timestamp)
4. **Aggregate** toxicity by subreddit, by time of day, by comment depth — identify the most toxic communities and time patterns
5. **Benchmark** throughput: comments/second per executor, scaling with partition count, impact of batch size on ONNX inference speed

## Questions You Should Be Able to Answer

- How do you load the ONNX model inside `mapPartitions`? What happens if you load it inside `map` instead? (hint: one model per row)
- What is the inference throughput per executor? How does batching (scoring 32 comments at once vs 1) affect it?
- How large is the ONNX model in memory? Does it fit alongside Spark's working memory per executor?
- Show a subreddit your system flagged as highly toxic. Does the result match intuition?
- How would you update the model (retrain, re-export) without redeploying the Spark pipeline?
