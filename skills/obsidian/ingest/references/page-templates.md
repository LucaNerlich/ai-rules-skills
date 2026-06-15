# Wiki page templates & tagging (ai-wiki)

These mirror the schema in `CLAUDE.md`. Every page has YAML frontmatter and uses
`[[wikilinks]]` for cross-references. Dates are `YYYY-MM-DD`. File names are
kebab-case slugs (e.g. `direct-preference-optimization.md`); the `title:` is the
human label shown in the bases.

## Source page — `wiki/sources/<slug>.md`
```markdown
---
title: Source Title
type: source
created: YYYY-MM-DD
updated: YYYY-MM-DD
ingested: YYYY-MM-DD
source_file: "[[raw/Clippings/processed/Original Name]]"   # post-move path
author: Author Name
date: YYYY-MM-DD            # publication date of the source
tags: []
---

# Source Title

## Key Takeaways
- Most important claims/findings.

## Summary
Detailed summary.

## Entities Mentioned
- [[Entity]] — how it appears here.

## Concepts
- [[Concept]] — how this source develops it.

## Notes
Caveats, open questions, contradictions with other sources.
```
- For PDFs, `source_file:` is `"[[raw/PDFs/processed/Original Name]]"`.
- `created`/`ingested` = today. `date` = the source's own publication date if known.

## Entity / Concept / Topic page — `wiki/{entities,concepts,topics}/<slug>.md`
```markdown
---
title: Page Title
type: entity | concept | topic
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[source-slug]]"
tags:
  - tag1
  - tag2
---

# Page Title

Content with [[wikilinks]]. Cite claims back to the [[source-slug]] they came from.

## See Also
- [[Related Page]]
```
- When updating an existing page, bump `updated:`, append the new `[[source]]` to
  `sources:`, and weave in the new material rather than duplicating.

## Cluster tags (drive the Glossary.base views)
Pick at least one so the page appears in the right Glossary cluster view. Common tags:

| Cluster view | Tags |
|---|---|
| AI Safety | `ai-safety` |
| LLM Core | `llm` |
| Training & Fine-tuning | `training`, `fine-tuning`, `pretraining` |
| Context Engineering & Agents | `context-engineering`, `agents`, `prompts` |
| Vectorization & RAG | `vectorization`, `rag`, `embeddings`, `retrieval`, `vector-database` |
| AI-Assisted Software Development | `ai-assisted-development`, `methodology`, `software-engineering`, `software-economics` |
| Knowledge Management | `knowledge-management`, `standards`, `meta` |
| Web Development | `web-development` |
| People | `person` |
| Organizations | `organization` |
| Tools & Frameworks | `framework`, `tool`, `ml-tooling` |
| Models & Datasets | `model`, `dataset`, `benchmark` |

Reuse existing tags where possible — check what's in use with
`scripts/obs.sh tags counts sort=count format=json` before inventing a new one.

## index.md entry format
One line per page, under its category heading:
```
- [[Page Title]] — one-line description (N sources)
```

## log.md entry format (append-only)
```
## [YYYY-MM-DD] ingest | Source Title

Brief description of what was done.
Pages created/updated: [[page1]], [[page2]], ...
```
