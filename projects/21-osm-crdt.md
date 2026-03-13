# Project 21 — OpenStreetMap Collaborative Edit Analysis

**Extends:** Sessions 3.3 (CALM, lattices, CRDTs), 4.2 (incremental computation)  
**Dataset:** [OpenStreetMap Changesets](../DATASETS.md#openstreetmap-changesets)  
**Stack:** Python, PostgreSQL or DuckDB

## Context

OpenStreetMap is one of the largest collaborative editing systems in the world. Thousands of mappers edit overlapping geographic regions simultaneously — a natural setting for CRDT-like reasoning. Your job is to analyze the changeset history and identify convergence patterns, edit conflicts, and areas of contention.

## Objectives

1. **Ingest** the OSM changeset metadata: timestamps, users, bounding boxes, tags, comments
2. **Detect** edit conflicts: cases where multiple users edit the same geographic region within a short time window
3. **Model** the editing process as a lattice: can you define a merge function that makes regional map state converge?
4. **Compute** incrementally: as new changesets arrive (from replication diffs), update conflict metrics without full recomputation

## Questions You Should Be Able to Answer

- How do you define "same geographic region"? What granularity did you choose and why?
- Is the OSM editing model naturally monotonic? Where does it break?
- Show a real edit conflict from the data. How would a CRDT-based approach resolve it?
- How does your incremental update handle changesets that arrive out of order in the replication feed?
