---
name: search
description: Search the AI Wiki knowledge base by keyword and return all relevant pages and sources, ranked, with wikilinks and one-line descriptions. Use whenever the user asks to find, look up, search for, or "what do we have on" a topic in the wiki, lists keywords to research, or asks a question the wiki likely answers. Queries Index.base and Glossary.base plus full-text search through the Obsidian CLI for context efficiency, reads only the top matches, and offers to synthesize the answer into an analysis page.
---

# Search the AI Wiki

Given keywords (or a question), find every relevant page and source and return a ranked,
linked result set. The discipline this skill enforces: **find candidates cheaply by
querying the Obsidian Bases and the search/tag indexes, then read only the top matches** —
rather than pulling `index.md` (21 KB) or many pages into context. That keeps answers fast
and the context window lean.

## Setup

Obsidian commands go through the bundled wrapper. From the skill directory:

```bash
chmod +x scripts/obs.sh   # first run only
scripts/obs.sh base:query path="wiki/Glossary.base" view="A–Z" format=md | head -3   # smoke test
```

**If a CLI call comes back empty, don't assume the wrapper is broken.** The wrapper is
fine — it only redirects the noisy startup banner (stderr) and prints real results on
stdout. Empty output almost always means either (a) `search` flakiness (it intermittently
returns nothing on the first call — just run the same command again), or (b) Obsidian
isn't running yet. `base:query` and `tag` are reliable; use them to confirm the CLI works
before falling back to anything else. Do **not** bypass `obs.sh` by calling the raw binary —
the wrapper exists so you target the right vault (a global `OBSIDIAN_VAULT` env var points
at a *different* vault on this machine, so the raw binary would query the wrong one).

Full command set and base view names are in `references/obsidian-cli.md`.

## Strategy: three lookup channels, then read the winners

Run the channels that fit the query (cheap, often in parallel), union the hits, rank, then
read only the top few pages in full.

### 1. Term lookup — Glossary.base
The Glossary is the catalog of entities + concepts + topics. If a keyword maps to a
cluster, pull that view; otherwise pull `A–Z` and scan. `format=md` is compact and
readable.
```bash
scripts/obs.sh base:query path="wiki/Glossary.base" view="Vectorization & RAG" format=md
scripts/obs.sh base:query path="wiki/Glossary.base" view="A–Z" format=json
```
Cluster view names are listed in `references/obsidian-cli.md` (e.g. `LLM Core`,
`Context Engineering & Agents`, `Training & Fine-tuning`, `Tools & Frameworks`, `People`…).

### 2. Tag lookup — exact topic membership
When a keyword is (or resembles) a tag, this is the highest-precision channel:
```bash
scripts/obs.sh tags counts sort=count format=json   # find the closest existing tag
scripts/obs.sh tag name="rag" verbose               # all pages carrying #rag
```

### 3. Full-text — search across all pages and sources
```bash
scripts/obs.sh search query="reward model" format=json   # -> array of file paths
```
For multiple keywords, run one search per keyword and rank files by how many keywords
hit them. To get the full catalog of pages (with titles/types/#sources) for ranking
context, query the Index base:
```bash
scripts/obs.sh base:query path="wiki/Index.base" view="All Pages" format=json
```

### 4. Read only the top matches
`scripts/obs.sh read path="wiki/concepts/rag.md"` on the handful of pages that clearly
matter. Don't read everything you found — read what you'll actually cite.

## Ranking

Order results by usefulness, not just match count:
1. **Direct term pages** — an entity/concept/topic whose title *is* the keyword.
2. **Topic overviews** — good entry points that link onward.
3. **Source pages** — primary material behind the claims.
4. **Analyses** — existing syntheses/comparisons that may already answer the question.

A page hit by several channels (Glossary + tag + full-text) ranks above a single-channel
hit. Prefer recently-updated pages and those with more sources when otherwise tied
(both visible in the base output).

## Output format

Group by category, each entry a wikilink + one-line description + path:

```markdown
**Concepts & Entities**
- [[rag]] — Retrieval-Augmented Generation: core pattern + tradeoffs (wiki/concepts/rag.md)
- [[pgvector]] — Postgres extension for vector search (wiki/entities/pgvector.md)

**Topics**
- [[embeddings]] — overview tying vectorization, RAG, and vector DBs together

**Sources**
- [[pinecone-concepts]] — Pinecone's managed vector DB model

**Analyses**
- [[what-is-rag-and-related-retrieval-architectures]] — existing synthesis
```

If the query was a **question** (not just keywords), synthesize a short answer first,
citing pages with `[[wikilinks]]`, then list the results that back it. If nothing
relevant exists, say so plainly and suggest the closest pages or that the topic may need
ingesting.

## Offer to save (Query workflow, step 4)
If you produced a substantial, reusable synthesis, offer to save it as
`wiki/analyses/<slug>.md`. Only if the user accepts: write the page (analysis template in
the ingest skill's `references/page-templates.md`), add a one-line entry to `wiki/index.md`,
and append a `query` entry to `wiki/log.md`. A plain lookup that just lists pages does not
need to be saved.
