---
name: ingest
description: Ingest fresh source documents into the AI Wiki knowledge base. Use whenever the user asks to ingest, process, import, or "catch up" new sources in raw/ — clippings or PDFs awaiting processing, or says "add this to the wiki". Reads each source in full, then creates/updates source, entity, concept, and topic pages, refreshes index.md / overview.md / log.md, and marks sources processed. Queries Index.base and Glossary.base through the Obsidian CLI to find existing pages and avoid duplicates instead of reading large files into context.
---

# Ingest sources into the AI Wiki

Turn fresh documents in `raw/` into linked wiki pages, following the schema in the
project's `CLAUDE.md`.

`CLAUDE.md` already describes the *what* of the ingest workflow. The distinct value this
skill adds — and the thing to lean on hardest — is **querying the Obsidian Bases with
`base:query` to discover what already exists before you write anything.** That is what
keeps the "one page per entity/concept" rule (rule 5) honest at scale: with ~150+ pages,
you cannot eyeball whether a concept already has a page, and reading `index.md` (21 KB,
and often stale) or dozens of candidate files just to check burns context for no reason.
A single `base:query` against `Glossary.base` returns the exact set of existing terms in
a cluster, compactly, so you reliably **update instead of duplicate**. Treat the base
query as a required pre-write step, not an optional nicety. The skill also gets the
"mark processed" bookkeeping exactly right.

## Setup

All Obsidian commands go through the bundled wrapper. From the skill directory:

```bash
chmod +x scripts/obs.sh   # first run only
scripts/obs.sh files folder="raw/Clippings" ext=md   # smoke test — Obsidian must be running
```

Read `references/obsidian-cli.md` for the full command set and `references/page-templates.md`
for the exact page formats and cluster-tag list. Keep both handy throughout.

## Default mode: batch

Ingest **every** fresh source end-to-end, then report a summary of what was created and
updated. Don't stop to discuss each one. Pause only when you hit a genuine fork:
- new information **contradicts** an existing page (flag it on both pages — rule 7),
- a source is ambiguous, corrupt, or not in English and you're unsure how to treat it,
- you'd be creating a page that looks like a near-duplicate of an existing one and the
  merge isn't obvious.

If the user points at a single document, you may discuss takeaways first — but the
default for "ingest the new stuff" is batch.

## Workflow

Track these as todos so nothing is skipped.

### 1. Discover fresh sources
Fresh = sitting at the top level of a category folder, not yet in `processed/`.
```bash
scripts/obs.sh files folder="raw/Clippings" ext=md   # excludes raw/Clippings/processed via your eyes
ls raw/PDFs/*.pdf 2>/dev/null
```
The `files` listing includes `processed/` entries — ignore anything under a `processed/`
path. If there are no fresh sources, say so and stop.

### 2. Read each source in full
Clippings: `scripts/obs.sh read path="raw/Clippings/<name>.md"` (or the `Read` tool).
PDFs: use the `Read` tool with the `pages` parameter — read the whole document, not just
the first page.

### 3. Find what already exists (query the bases — don't read everything)
Before writing any entity/concept page, check whether one exists, so you update rather
than duplicate (rule 5). Use the cheapest lookup that answers the question:

```bash
# Is there already a page for a term? Pull the relevant Glossary cluster, compactly:
scripts/obs.sh base:query path="wiki/Glossary.base" view="Vectorization & RAG" format=md

# Or search by the entity/concept name across the wiki:
scripts/obs.sh search query="LlamaIndex" format=json

# Or find pages already tagged with the topic:
scripts/obs.sh tag name="rag" verbose
```

Only `read` a candidate page in full when you're actually going to update it.

### 4. Create the source page
`wiki/sources/<slug>.md` using the source template in `references/page-templates.md`.
Set `created`/`ingested` to today, `source_file:` to the **post-move** path (inside
`processed/`), and `date:` to the source's own publication date if known.

### 5. Create or update entity pages
`wiki/entities/<slug>.md` for notable people, orgs, tools, products. Update existing
pages (bump `updated:`, append the new `[[source]]`, weave in new facts) rather than
recreating. Cite claims back to the source page.

### 6. Create or update concept pages
`wiki/concepts/<slug>.md` for ideas, frameworks, methodologies. Same update-not-duplicate
rule. Pick cluster tags (see the table in `page-templates.md`) so the page lands in the
right Glossary view automatically.

### 7. Update topic pages
Update relevant `wiki/topics/<slug>.md` overviews, or create one if a genuinely new
theme emerges. Link the new source and any new entity/concept pages.

### 8. Update index.md
Add a one-line entry per new/updated page under its category heading
(`- [[Page Title]] — description (N sources)`). This is a hand-maintained catalog —
edit it directly with `Edit`.

### 9. Update overview.md (only if the big picture moved)
If the source materially changes the synthesis, update `wiki/overview.md`. Skip for
incremental additions.

### 10. Append to log.md
Append one `ingest` entry per source (see `page-templates.md` for the format). Never
rewrite earlier log entries — append only.

### 11. Mark the source processed
- **Move** it into `processed/` (this keeps Obsidian's link graph correct):
  ```bash
  scripts/obs.sh move path="raw/Clippings/<name>.md" to="raw/Clippings/processed"
  scripts/obs.sh move path="raw/PDFs/<name>.pdf" to="raw/PDFs/processed"
  ```
- **Clippings only**, add the processed markers to frontmatter (the one allowed edit to a
  raw clipping). Append `processed` to the existing `tags:` array and add `ingested:`:
  ```bash
  scripts/obs.sh property:set path="raw/Clippings/processed/<name>.md" name="ingested" value="2026-06-15" type="date"
  ```
  For the tag, read the clipping's `tags:` and add `processed` (use `Edit` — it's a list
  append, e.g. `clippings` → `clippings`, `processed`). PDFs have no frontmatter; the
  folder move is their only marker.

## Finish
Verify the source page's `source_file:` points at the post-move path. Then report a
concise summary: sources ingested, pages created vs updated (as wikilinks), any
contradictions flagged, anything you skipped and why. Don't claim a page was written
unless you actually wrote it.
