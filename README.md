# Data Processing at Scale

Course material for a 21-hour (14 sessions) master's-level course on distributed data processing.

## Prerequisites

- [Typst](https://typst.app/) — slide compilation
- [entr](https://eradman.com/entrproject/) — file-watching for live rebuild (`sudo apt install entr`)
- GNU Make

## Quick Start

```bash
make            # build all session PDFs into build/
make watch      # rebuild automatically on any .typ change
make clean      # remove all built artifacts
```

PDFs are written to `build/<session-name>.pdf`.

## Repository Layout

```
context/                        Course-level reference documents
  SESSIONS.md                     Syllabus, session list, learning outcomes
  PROJECTS.md                     30 projects with difficulty ratings
  DATASETS.md                     15 datasets — descriptions, sizes, access

projects/                       Individual project briefs (one per project)
  1-github-analytics.md
  ...
  30-noaa-correlation.md

labs/                           Instructor-led demo guides (one per session)
  1.1-single-node-benchmark.md
  ...

sessions/                       Slide decks (one folder per session)
  style.typ                       Shared Typst/Touying theme
  1.1-introduction/
  1.2-distributed-systems/
  ...
  4.3-project-briefing/

build/                          Compiled PDFs (git-ignored)
```

## Session Folder Structure

Each session follows the same layout:

```
sessions/<session-name>/
  main.typ              Entry point — theme setup + #include for each slide
  assets/               Images, diagrams, data files
  slides/
    slide_001.typ        One file per slide, zero-padded numbering
    slide_002.typ
    ...
```

- `main.typ` is the compile target. It assembles slides but contains no content itself.
- `style.typ` (one level up) holds the shared Metropolis theme config. All sessions import it.

## Sessions

| Day | Session | Topic |
|-----|---------|-------|
| 1 | 1.1 | Introduction & Motivation |
| 1 | 1.2 | Distributed Systems Fundamentals |
| 1 | 1.3 | MapReduce |
| 1 | 1.4 | Data Modeling for Analytics |
| 1 | 1.5 | Cost Modeling & Performance Reasoning |
| 2 | 2.1 | Storage Formats & Lakehouse |
| 2 | 2.2 | Apache Spark |
| 3 | 3.1 | Apache Flink: Stream Processing |
| 3 | 3.2 | Flink Advanced: State & Exactly-Once |
| 3 | 3.3 | ClickHouse: Real-Time Analytics |
| 3 | 3.4 | Data Pipelines: Theory & Reasoning |
| 4 | 4.1 | Probabilistic Data Structures |
| 4 | 4.2 | Differential Dataflow & Incremental Computation |
| 4 | 4.3 | Project Briefing |

## Editing Slides

- One idea per slide. One file per slide.
- Slide files use level-2 headings (`==`) for content slides.
- Insert a new slide by creating `slide_XXX.typ`, adding its `#include` to `main.typ`, and renumbering subsequent files.
- Assets are per-session — don't cross-reference between sessions.
- With `make watch` running, save a `.typ` file and the PDF rebuilds automatically.
