---
title: AEM Simplified Oak Index Management
type: concept
created: 2026-06-15
updated: 2026-06-15
sources:
  - "[[simplified-index-management]]"
tags:
  - adobe-experience-manager
  - aem
  - oak
  - indexing
---

# AEM Simplified Oak Index Management

A diff-based approach to defining and customizing Apache Jackrabbit **Oak query indexes** in [[adobe-experience-manager|AEM as a Cloud Service]]. Instead of copying full out-of-the-box (OOTB) index definitions and managing versions by hand, the developer maintains a single `diff.json` describing only the *delta*; the platform automatically **merges** it with the latest OOTB index and **auto-creates a new index version** when the merged result changes. Documented in [[simplified-index-management]].

## The diff.json model

`diff.json` holds two kinds of entries:

- **Customizations of OOTB indexes** (e.g. `damAssetLucene`) — only the added/changed bits.
- **Fully custom indexes** — name must contain a dot, must omit the `/oak:index/` prefix, and must set a non-empty `includedPaths` outside `/apps` and `/libs` (best practice: `queryPaths` = `includedPaths`).

A diff is produced from a Developer Console Oak-index status dump via the **Index Definition Analyzer**, and can be validated with the **Diff Index Verifier** (both oakTools).

## Run modes

- **Pipeline Mode** — Cloud Service Dev/Stage/Prod. The repo carries `_oak_index/diff.index/.content.xml` (a fixed compatibility stub: `type="lucene"`, deliberately non-existent `includedPaths`/`queryPaths`) plus `diff.json`, with `/oak:index/diff.index` registered in `filter.xml`. The deployment pipeline performs the merge. Works on all AEM releases because `diff.index` is processed outside AEM.
- **RDE & Local Quickstart** — changes applied immediately, no pipeline (requires AEMaaCS 2026.05 / release 25892+ and Oak 1.92+). In CRX/DE: a `diff.index` node (`oak:QueryIndexDefinition`, `type="disabled"`) containing a `diff.json` (`nt:file`); on save a new version is created and reindexing starts immediately. **Not for large repositories or Cloud Service DEV** (reindexing can be slow).

## Versioning and removal

- Merged index name: `<baseName>-<productVersion>-custom-<customerVersion>`; the customer version increments when a merge yields a different result.
- `mergeInfo` and `mergeChecksum` (SHA-256) properties are stamped on every merged index.
- Old versions of the same base index are removed after the new version is created; a previously-merged index that is no longer referenced in the diff is removed.

## Merge rules (conservative by design)

To avoid breaking OOTB indexes the merge is additive and non-destructive:

- **Top-level properties:** `includedPaths`, `queryPaths`, `tags` are **unioned**, not overwritten — but may not be *added* if absent (would narrow the index). `selectionPolicy`, `valueRegex`, `queryFilterRegex`, `excludedPaths` may not be added to an existing index (dropped with a warning). Other new properties are added; existing ones are never overwritten.
- **Indexed properties:** children under `properties` are matched by `name` value first, then by `function` value (the diff applies to the match even if the node name differs); otherwise a new child is created. `isRegexp`, `index`, `function`, `name` may not be added or updated on an existing child (freezes how a property is indexed). Existing values are immutable except `boost` and `weight`.
- **Comparison:** a normalized form is compared — transient props (`reindex`, `:version`, `mergeInfo`, etc.) stripped, Oak prefixes (`str:`, `nam:`, `dat:`) normalized, `jcr:primaryType` ignored at top level, `jcr:uuid` removed; property order ignored but child-node order significant. A SHA-256 checksum detects real changes across runs.

## See Also

- [[simplified-index-management]]
- [[adobe-experience-manager]]
- [[aem-cloud-service-intro]]
