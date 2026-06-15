---
title: Oak Indexing (AEM)
type: concept
created: 2026-06-15
updated: 2026-06-15
sources:
  - "[[simplified-index-management]]"
tags:
  - adobe
  - adobe-experience-manager
  - aem
  - oak-indexing
  - operations
---

# Oak Indexing (AEM)

Apache Jackrabbit Oak is the content repository underneath [[adobe-experience-manager]]; queries against the JCR are served by **Oak query indexes** (most commonly Lucene indexes) defined as nodes under `/oak:index`. Customizing or extending these indexes is a routine but historically fiddly AEM operations task because each definition is versioned and must usually be copied wholesale to change.

## Simplified Index Management

The [[simplified-index-management]] feature replaces hand-maintained full definitions with a single **`diff.json`** that is automatically merged against the latest out-of-the-box (OOTB) index; a new index version is created only when the merged result changes. It supports both customizing an OOTB index (e.g. `damAssetLucene`) and defining a fully custom index (name must contain a dot, e.g. `custom.slingFolderNodeNames`, with a non-empty `includedPaths` not under `/apps` or `/libs`).

### Two run modes

- **Pipeline Mode** — Cloud Service Dev/Stage/Prod via a deployment pipeline; the diff is processed *outside* AEM so it works on all releases. Configured in Git under `ui.apps/.../jcr_root/_oak_index/diff.index` with a fixed `.content.xml` and the `diff.json`, plus a `filter.xml` entry.
- **RDE & Local Quickstart** — no pipeline; changes apply immediately with immediate reindexing. Requires AEM as a Cloud Service 2026.05 (release 25892)+ and Oak 1.92+. Not for large repositories or Cloud Service DEV environments.

### Merge rules (conservative by design)

- `includedPaths`, `queryPaths`, `tags` are **unioned**, never made more restrictive; `includedPaths`/`queryPaths` may not be *added* if absent.
- Existing property values are **not overwritten** (exceptions: `boost`, `weight`).
- Indexed properties are matched by `name` value first, then `function`; `isRegexp`/`index`/`function`/`name` cannot be added or changed on existing children.
- Merged indexes are named `<baseName>-<productVersion>-custom-<customerVersion>`, carry `mergeInfo` + `mergeChecksum` (SHA-256), old versions are removed, and an index dropped from the diff is removed.

### Tooling

- **Index Definition Analyzer** — generate a diff from a Developer Console Oak Indexes JSON status dump.
- **Diff Index Verifier** — validate a hand-edited diff.

## See Also
- [[simplified-index-management]]
- [[adobe-experience-manager]]
