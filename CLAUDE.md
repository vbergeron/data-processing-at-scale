# Data Processing at Scale — course repository

Slides and lab handouts for a ~20h master's course (4 days, 9 sessions, 7 labs), written in Typst and published to GitHub Pages. See `README.md` for the session list and `context/SESSIONS.md` for the syllabus.

Detailed authoring rules live in `.claude/rules/`:
- `content-accuracy.md` — always applies
- `slide-pedagogy.md`, `slide-composition.md` — when editing `sessions/**/*.typ`
- `lab-writing.md` — when editing `labs/**/*.typ`

## Layout

```
index.html          Landing page — Tailwind CDN, links to the PDFs colocated in build/
context/            SESSIONS.md (syllabus), PROJECTS.md (30 projects), DATASETS.md (15 datasets)
projects/           One brief per project (<n>-<slug>.md)
sessions/
  style.typ         Shared Touying/Metropolis theme (dpas-theme, hero, …) — single source of truth
  <X.Y-name>/
    main.typ        Assembly only: dpas-theme setup + #include of each section
    sections/       NN-topic.typ files, included in order
    assets/         Images and diagrams for this session only
labs/
  style.typ         Shared lab document theme (lab-theme)
  <X.Y[.Z]-name>/
    main.typ        Self-contained handout: objective, setup, walkthrough, takeaways
    assets/         Optional starter code, shipped as build/lab-<name>-assets.tar.gz
```

## Rules

- Never put slide content in a session's `main.typ`; it only assembles sections.
- Never duplicate theme configuration; import `../style.typ` (from `main.typ`) or `../../style.typ` (from a section).
- Assets are per-session. Do not reference another session's assets.
- `dpas-theme` takes `title`, `day`, `slug` (must equal the folder name — it drives the QR code/PDF URL), `lab` (a lab folder name or a tuple of them) and optional `next` (the following session's folder).
- Lab folders are named after the session they belong to (e.g. `1.2-single-node-benchmark`). Not every session has a lab.
- When adding, renaming or removing a session or lab, update together: `index.html`, `README.md`, `context/SESSIONS.md`, and any `lab:`/`next:` references in other sessions' `main.typ`.
- Links in `context/*.md` and `projects/*.md` are relative to the file's own folder (e.g. `../projects/…`, `../context/DATASETS.md`).

## Build & verify

```bash
make            # build every session PDF, lab PDF, lab asset archive and index.html into build/
make -k         # what CI runs — keep going past failures
make watch      # rebuild on .typ changes (needs entr)
typst compile --root . sessions/<name>/main.typ build/<name>.pdf   # one deck
```

After editing a `.typ` file, compile the affected deck or lab and fix any errors or warnings before finishing. Always pass `--root .`: sections reference shared files outside their folder.

CI (`.github/workflows/release.yml`) runs `make -k` on pushes to `main` and deploys `build/` to GitHub Pages; `v*` tags also attach the PDFs to a release.
