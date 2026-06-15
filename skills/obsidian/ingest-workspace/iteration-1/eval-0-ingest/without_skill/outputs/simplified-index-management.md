---
title: "Simplified Index Management"
type: source
created: 2026-06-15
updated: 2026-06-15
ingested: 2026-06-15
source_file: "[[raw/Clippings/processed/Simplified Index Management.md]]"
author: Oak Indexing (oakTools)
date:
tags:
  - adobe
  - adobe-experience-manager
  - aem
  - oak-indexing
  - operations
---

# Simplified Index Management

## Key Takeaways

- **Simplified Index Management** lets you define custom indexes and customize out-of-the-box (OOTB) indexes for [[adobe-experience-manager]] using a single `diff.json` file — no copying full definitions, no explicit version management.
- Customizations are **automatically merged** with the latest OOTB index, and a new index version is created automatically only when the merged result actually changes.
- Two run modes share the same `diff.json`: **Pipeline Mode** (Cloud Service Dev/Stage/Prod, processed outside AEM so it works on all releases) and **RDE & Local Quickstart** (changes applied immediately; requires AEM as a Cloud Service 2026.05 / release 25892+ with Oak 1.92+).
- Merge rules are conservative: `includedPaths`, `queryPaths`, and `tags` are **unioned** (never made more restrictive); existing property values are **not overwritten** (except `boost` and `weight`); and certain keys (`selectionPolicy`, `valueRegex`, `queryFilterRegex`, `excludedPaths`, `isRegexp`, `index`, `function`, `name`) cannot be added/changed on existing definitions.
- Merged indexes are named `<baseName>-<productVersion>-custom-<customerVersion>`, carry `mergeInfo` + `mergeChecksum` (SHA-256) properties, and old versions are garbage-collected; an index dropped from the diff is removed.
- Two helper tools: the **Index Definition Analyzer** (generate a diff from a Developer Console index dump) and the **Diff Index Verifier** (validate a hand-edited diff).

## Summary

The page documents Oak's Simplified Index Management feature for AEM as a Cloud Service. Rather than maintaining full Lucene index definitions and their versions by hand, the developer maintains one `diff.json` that is merged against the current OOTB index.

**Pipeline Mode** (cloud, with a deployment pipeline): in the program's Git repo under `ui.apps/src/main/content/jcr_root/_oak_index`, create a `diff.index` directory containing a fixed `.content.xml` (type `lucene`, with `includedPaths`/`queryPaths` set to a non-existent path like `/same` so existing tooling doesn't build a large index) plus the `diff.json`; add a `<filter root="/oak:index/diff.index" />` line to `filter.xml`; run the pipeline to merge and version.

**RDE & Local Quickstart** (no pipeline): in CRX/DE, create a `diff.index` node of type `oak:QueryIndexDefinition` with `type` = `disabled`, a `diff.json` child of type `nt:file`, save, and a new version is created with immediate reindexing. Explicitly warned against for large repositories and for Cloud Service DEV environments because reindexing is immediate.

**Authoring a diff.** Open the Developer Console → Status Dump → Oak Indexes, output JSON, download, and paste into the Index Definition Analyzer to generate the diff; verify with the Diff Index Verifier. A `diff.json` can both customize an OOTB index (e.g. `damAssetLucene`) and define a fully custom index — fully custom index names must contain a dot (e.g. `custom.slingFolderNodeNames`), need a non-empty `includedPaths` not under `/apps` or `/libs`, and should set `queryPaths` to match. OOTB Tika config is not needed in the diff; custom indexes need Tika only for analyzed properties or aggregations.

**Merge mechanics.** Top-level: union of `includedPaths`/`queryPaths`/`tags`; no overwriting existing values; new non-conflicting properties added. Indexed properties: the merger matches by `name` value first (then by `function`), applying the diff to the matched child even if node names differ, else creates a new child; it cannot change `isRegexp`/`index`/`function`/`name` or overwrite values other than `boost`/`weight`. For comparison the definitions are normalized (volatile reindex/version/seed properties stripped, Oak `str:`/`nam:`/`dat:` prefixes removed, `jcr:primaryType` ignored at top level, `jcr:uuid` removed, properties sorted but child order significant), and a SHA-256 checksum detects changes across runs.

## Entities Mentioned

- [[adobe-experience-manager]] — the product this feature manages indexes for (AEM as a Cloud Service; Oak/Jackrabbit is its content repository).

## Concepts

- [[oak-indexing]] — Apache Jackrabbit Oak query indexing in AEM; this source documents the merge-based customization workflow.

## Notes

No author or publication date given in the clipping (`author:`/`published:` empty). Hosted on the community `oak-indexing.github.io/oakTools` site, with support routed through that project's GitHub issues — appears to be a tooling/companion resource rather than official Adobe Experience League documentation, though it links to the official Content Search and Indexing docs. Version requirements (2026.05 / release 25892, Oak 1.92) are recent, consistent with the 2026-06-03 clip date.

## See Also
- [[oak-indexing]]
- [[adobe-experience-manager]]
