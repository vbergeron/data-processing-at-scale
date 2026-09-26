# Data Processing at Scale

Course material for a ~20-hour master's-level course on distributed data processing: 9 sessions and 7 labs over 4 days, assessed by a project presentation.

**Live site:** <https://vbergeron.github.io/data-processing-at-scale/>

## Prerequisites

- [Typst](https://typst.app/) — slide and lab compilation
- [entr](https://eradman.com/entrproject/) — file-watching for live rebuild (`sudo apt install entr`)
- GNU Make

Labs additionally use [scala-cli](https://scala-cli.virtuslab.org/), DuckDB/PyArrow (lab 2.1) and ClickHouse (lab 3.2).

## Quick Start

```bash
make            # build all PDFs, lab asset archives and the landing page into build/
make watch      # rebuild automatically on any .typ change
make clean      # remove all built artifacts
```

Output goes to `build/`:
- `<session-name>.pdf` — slide decks
- `lab-<lab-name>.pdf` — lab handouts
- `lab-<lab-name>-assets.tar.gz` — starter code for labs that have an `assets/` folder
- `index.html` — course landing page

Pushing to `main` builds and deploys everything to GitHub Pages; pushing a `v*` tag also attaches the PDFs to a GitHub release (see `.github/workflows/release.yml`).

## Repository Layout

```
index.html                      Landing page (deployed to GitHub Pages)

context/                        Course-level reference documents
  SESSIONS.md                     Syllabus, session list, learning outcomes
  PROJECTS.md                     30 projects with difficulty ratings
  DATASETS.md                     15 datasets — descriptions, sizes, access

projects/                       Individual project briefs (one per project)
  1-github-analytics.md
  ...
  30-noaa-correlation.md

labs/                           Lab handouts (one folder per lab)
  style.typ                       Shared Typst document theme for labs
  1.2-single-node-benchmark/
    main.typ
    assets/                       Optional starter code, packaged as a tarball
  ...

sessions/                       Slide decks (one folder per session)
  style.typ                       Shared Typst/Touying theme for slides
  1.1-introduction/
    main.typ
    sections/
    assets/
  ...
  4.2-project-briefing/

.cursor/rules/                  Authoring guidelines (slide pedagogy, composition, lab writing, accuracy)

build/                          Compiled output (git-ignored)
```

## Session Folder Structure

Each session follows the same layout:

```
sessions/<session-name>/
  main.typ              Entry point — theme setup + #include for each section
  assets/               Images, diagrams, data files
  sections/
    01-content.typ      One or more section files, included in order
    ...
```

- `main.typ` is the compile target. It assembles sections but contains no content itself.
- `style.typ` (one level up) holds the shared Metropolis theme config (`dpas-theme`). All sessions import it; its `slug`, `lab` and `next` parameters generate the QR code and the links to the session's labs and the next deck.

## Lab Folder Structure

Each lab follows the same layout:

```
labs/<lab-name>/
  main.typ              Single document — objective, setup, walkthrough, takeaways
  assets/               Optional — starter code shipped as build/lab-<lab-name>-assets.tar.gz
```

- `style.typ` (one level up) holds the shared document theme. All labs import it.

## Sessions

| Day | Session | Topic | Lab |
|-----|---------|-------|-----|
| 1 | 1.1 | Introduction & Motivation | — |
| 1 | 1.2 | Distributed Programming with Scala | 1.2 — Benchmarking a Single-Node Pipeline |
| 1 | 1.3 | Distributed Systems Fundamentals | 1.3.1 — Replication & Consistency in a Distributed KV Store <br> 1.3.2 — Distributed Batch Processing & Partitioning |
| 2 | 2.1 | Storage Formats & Distributed File Systems | 2.1 — Query Performance Across File Formats |
| 2 | 2.2 | Apache Spark & Query Execution Internals | 2.2 — Reading & Optimizing Spark Query Plans |
| 3 | 3.1 | Data Streaming at Scale (Kafka, Spark Structured Streaming, Flink) | 3.1 — Portfolio Analytics with the Flink DataStream API |
| 3 | 3.2 | ClickHouse: Real-Time Analytics at Scale | 3.2 — Billion-Row Analytics in ClickHouse |
| 4 | 4.1 | Advanced Topics: Probabilistic Data Structures, Differential Dataflow, Druid | — |
| 4 | 4.2 | Project Briefing | — |

See [context/SESSIONS.md](context/SESSIONS.md) for the detailed syllabus and learning outcomes.

## Assessment

100% project presentation on a separate day. Teams pick one of the [30 projects](context/PROJECTS.md) built on the [15 datasets](context/DATASETS.md) presented in session 4.2.

## Editing

- One idea per slide. Section files use level-2 headings (`==`) for content slides.
- Assets are per-session — don't cross-reference between sessions.
- When adding a session or lab, also add it to `index.html`, this README and `context/SESSIONS.md`.
- With `make watch` running, save a `.typ` file and the PDF rebuilds automatically.
- The full authoring guidelines live in `.cursor/rules/`.
