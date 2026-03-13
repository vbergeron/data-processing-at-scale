# Data Processing at Scale

Course material for a 21-hour (14 sessions) master's-level course on distributed data processing.

**Live site:** <https://vbergeron.github.io/data-processing-at-scale/>

## Prerequisites

- [Typst](https://typst.app/) — slide and lab compilation
- [entr](https://eradman.com/entrproject/) — file-watching for live rebuild (`sudo apt install entr`)
- GNU Make

## Quick Start

```bash
make            # build all PDFs + landing page into build/
make watch      # rebuild automatically on any .typ change
make clean      # remove all built artifacts
```

Output goes to `build/`:
- `<session-name>.pdf` — slide decks
- `lab-<lab-name>.pdf` — lab handouts
- `index.html` — course landing page

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

labs/                           Lab handouts (one folder per session)
  style.typ                       Shared Typst document theme for labs
  1.1-single-node-benchmark/
    main.typ
  ...

sessions/                       Slide decks (one folder per session)
  style.typ                       Shared Typst/Touying theme for slides
  1.1-introduction/
    main.typ
    sections/
    assets/
  ...
  4.3-project-briefing/

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
- `style.typ` (one level up) holds the shared Metropolis theme config. All sessions import it.

## Lab Folder Structure

Each lab follows the same layout:

```
labs/<lab-name>/
  main.typ              Single document — objective, setup, walkthrough, takeaways
```

- `style.typ` (one level up) holds the shared document theme. All labs import it.

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

## Editing

- One idea per slide. Section files use level-2 headings (`==`) for content slides.
- Assets are per-session — don't cross-reference between sessions.
- With `make watch` running, save a `.typ` file and the PDF rebuilds automatically.
