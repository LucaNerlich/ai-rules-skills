# Obsidian CLI cheat-sheet (ai-wiki)

The Obsidian CLI is a thin client that talks to the **running** Obsidian app over IPC.
**Obsidian must be open** (any vault) for these to work. All commands below are routed
through the bundled wrapper `scripts/obs.sh`, which targets the `ai-wiki` vault and
silences the startup banner. Run it from the skill directory or by absolute path.

Verified working on installer 1.12.7+ (app 1.13.1). On older installers `base:query`
returns empty — if that happens, see "Fallbacks" at the bottom.

## The commands this skill relies on

### base:query — query an Obsidian Base, get compact rows (the context-efficiency win)
Prefer this over reading `wiki/index.md` (21 KB) or dozens of page files. It returns
only the columns the base defines (title, type, tags, # sources, updated).

```bash
# Glossary = entities + concepts + topics. View names are the tabs in Glossary.base.
scripts/obs.sh base:query path="wiki/Glossary.base" view="A–Z" format=md
scripts/obs.sh base:query path="wiki/Glossary.base" view="Vectorization & RAG" format=json

# Index = every wiki page.
scripts/obs.sh base:query path="wiki/Index.base" view="All Pages" format=paths
```

- `path=` is vault-root-relative. `view=` selects a tab within that base.
- `format=` is `json` | `csv` | `tsv` | `md` | `paths` (default `json`).
- Note the en-dash in `"A–Z"` (not a hyphen).

**Glossary.base view names** (cluster views auto-populate from tags):
`A–Z`, `By Type`, `Recently Updated`, `AI Safety`, `LLM Core`, `Training & Fine-tuning`,
`Context Engineering & Agents`, `Vectorization & RAG`, `AI-Assisted Software Development`,
`Knowledge Management`, `Web Development`, `People`, `Organizations`, `Tools & Frameworks`,
`Models & Datasets`.

**Index.base view names:** `All Pages`, `By Category`.

List a base's views if unsure (operates on the focused base — open it first or just
read the `.base` YAML directly):

```bash
scripts/obs.sh base:views path="wiki/Glossary.base"
```

### search — full-text, returns matching file paths
```bash
scripts/obs.sh search query="reward model" format=json   # -> JSON array of paths
scripts/obs.sh search query="pgvector" path="wiki"        # limit to a folder
```
Multi-word queries are ANDed across the file. `format=json` gives a clean path array.
(`search:context` — line-level snippets — is still broken on this build; use `read` on
the top hits instead.)

**`search` is flaky** — it intermittently returns empty on the first call (IPC timing),
then works on an identical retry. If a search comes back empty, **retry once** before
concluding there are no matches. `base:query` and `tag` are reliable; lean on them as the
primary channels and use `search` to widen coverage.

### tag — find pages carrying a tag (great for keyword→pages)
```bash
scripts/obs.sh tag name="rag" verbose      # count + list of files with #rag
scripts/obs.sh tags counts sort=count format=json   # all tags, by frequency
```

### read / files — content and listings
```bash
scripts/obs.sh read path="wiki/concepts/rag.md"
scripts/obs.sh files folder="wiki/sources" ext=md
scripts/obs.sh files folder="raw/Clippings" ext=md    # fresh clippings live at top level
```

### Writes & metadata (keep Obsidian's cache + links in sync)
```bash
scripts/obs.sh move path="raw/Clippings/Foo.md" to="raw/Clippings/processed"   # updates links
scripts/obs.sh property:set path="raw/Clippings/processed/Foo.md" name="ingested" value="2026-06-15" type="date"
scripts/obs.sh backlinks path="wiki/concepts/rag.md" counts   # who links here
scripts/obs.sh orphans        # pages with no inbound links (useful in lint)
scripts/obs.sh unresolved verbose   # broken wikilinks
```

For authoring multi-line page bodies, the `Write`/`Edit` tools are more ergonomic than
`obsidian create content=...`. Use the CLI for queries, moves, and single-property edits;
use Write/Edit for page content.

## Fallbacks (if base:query ever returns empty again)
1. `base:query` operates against the running app; if a future installer regresses, it may
   need the target base focused. Make it active first:
   `scripts/obs.sh open path="wiki/Glossary.base"` then retry.
2. Reproduce any base view with `eval` over the metadata cache (no focus dependency):
   ```bash
   scripts/obs.sh eval code='JSON.stringify(app.vault.getMarkdownFiles()
     .filter(f=>f.path.startsWith("wiki/concepts/")||f.path.startsWith("wiki/entities/")||f.path.startsWith("wiki/topics/"))
     .map(f=>{const fm=(app.metadataCache.getFileCache(f)||{}).frontmatter||{};return{path:f.path,title:fm.title,type:fm.type,tags:fm.tags};}))'
   ```
3. Last resort: read `wiki/index.md` or the `.base` YAML directly with the `Read` tool.
