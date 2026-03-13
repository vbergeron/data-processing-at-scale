# Project 20 — Spotify Genre Boundary Detection

**Extends:** Sessions 2.2 (Spark & query execution), 1.4 (data modeling), 4.1 (probabilistic structures)  
**Dataset:** [Spotify Million Playlist](../DATASETS.md#spotify-million-playlist-dataset)  
**Stack:** PySpark, Python

## Context

Musical genres are fuzzy: some artists sit squarely in one genre, while others bridge multiple. Playlist co-occurrence data reveals these boundaries better than any label. Your job is to build a Spark pipeline that identifies genre-bridging artists and maps the implicit genre topology of music.

## Objectives

1. **Build** an artist co-occurrence matrix from playlist data: two artists are connected if they frequently appear in the same playlists
2. **Detect** communities in the co-occurrence graph using connected components or label propagation
3. **Identify** genre-bridging artists: those with strong connections to multiple communities
4. **Compute** a "genre distance" metric between artist pairs using co-occurrence similarity (Jaccard, cosine)

## Questions You Should Be Able to Answer

- How large is the co-occurrence matrix? How did you make the computation tractable?
- Show the Spark execution plan for your community detection. Where are the shuffles?
- Name 3 genre-bridging artists your system found. Do the results make intuitive sense?
- How does your genre distance metric compare to Jaccard vs cosine similarity? Which works better and why?
