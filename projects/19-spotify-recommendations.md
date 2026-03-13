# Project 19 — Playlist Similarity Engine

**Extends:** Sessions 2.2 (Spark & query execution), 1.4 (data modeling), 4.1 (probabilistic structures)  
**Dataset:** [Spotify Million Playlist](../DATASETS.md#spotify-million-playlist-dataset)  
**Stack:** PySpark, Python

## Context

With 1 million playlists and 66 million track entries, computing similarity between playlists is a combinatorial challenge. Your job is to build a Spark pipeline that computes playlist similarity using both exact and approximate methods, and compares their performance.

## Objectives

1. **Model** the playlist-track relationship: playlists as sets of track IDs, track metadata as a dimension
2. **Compute** exact similarity: Jaccard index between playlist pairs, co-occurrence matrices for tracks
3. **Implement** approximate similarity: MinHash / locality-sensitive hashing (LSH) for near-neighbor playlist search
4. **Compare** exact vs approximate: accuracy, computation time, memory usage across different thresholds

## Questions You Should Be Able to Answer

- How many playlist pairs exist? Why can't you compute exact similarity for all of them?
- How does MinHash approximate the Jaccard index? What is the error with 128 hash functions vs 256?
- Show the Spark execution plan for your co-occurrence matrix computation. Where are the shuffles?
- How would you handle playlist updates (tracks added/removed) incrementally?
