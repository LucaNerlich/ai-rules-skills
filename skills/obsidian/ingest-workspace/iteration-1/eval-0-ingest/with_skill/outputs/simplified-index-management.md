---
title: "Simplified Index Management"
type: source
created: 2026-06-15
updated: 2026-06-15
ingested: 2026-06-15
source_file: "[[raw/Clippings/processed/Simplified Index Management.md]]"
author:
date:
tags:
  - adobe
  - adobe-experience-manager
  - aem
  - oak
  - indexing
---

# Simplified Index Management

Documentation (oak-indexing.github.io / oakTools) for **Simplified Index Management**, a way to define custom Apache Jackrabbit Oak indexes and customize out-of-the-box (OOTB) indexes in [[adobe-experience-manager|AEM as a Cloud Service]] using a single `diff.json` file — no copying definitions, no explicitly defining versions. See [[aem-oak-index-management]].

## Key Takeaways

- **One JSON file (`diff.json`)** defines customizations and fully custom indexes. Customizations are automatically **merged** with the latest OOTB index, and a new index version is created automatically when needed.
- **Two run modes:** *Pipeline Mode* (Cloud Service Dev/Stage/Prod via the deployment pipeline; works on all AEM releases because `diff.index` is processed outside AEM) and *RDE & Local Quickstart* (changes applied immediately, no pipeline; requires AEMaaCS 2026.05 / release 25892+ and Oak 1.92+).
- **Do not use RDE/immediate mode on large repositories** (reindexing can be slow) — and never for Cloud Service DEV environments.
- **Versioning:** each merged index is named `<baseName>-<productVersion>-custom-<customerVersion>`; the customer version increments when a merge produces a different result. `mergeInfo` + `mergeChecksum` (SHA-256) properties are added to every merged index; old versions are removed after the new one is created; an unreferenced previously-merged index is removed.
- **Merge rules are conservative** to avoid breaking OOTB indexes: `includedPaths`/`queryPaths`/`tags` are *unioned* (not overwritten) and may not be *added* if absent (would make the index more restrictive); `selectionPolicy`, `valueRegex`, `queryFilterRegex`, `excludedPaths` may not be added to an existing index; existing properties are never overwritten.
- **Indexed property rules:** the merger matches children under `properties` by `name` value (then by `function`), applying the diff to the match even if the node name differs; `isRegexp`, `index`, `function`, `name` may not be added/updated on an existing child; existing property values are immutable except `boost` and `weight`.
- **Fully custom index** names must contain a dot, must not include the `/oak:index/` prefix, must set a non-empty `includedPaths` outside `/apps` and `/libs` (best: `queryPaths` = `includedPaths`).
- **Tooling:** the [Index Definition Analyzer](https://oak-indexing.github.io/oakTools/indexDefAnalyzer.html) creates a diff index from a Developer Console Oak-index status dump; the [Diff Index Verifier](https://oak-indexing.github.io/oakTools/diffIndexVerifier.html) checks correctness.

## Summary

Customizing Oak query indexes in AEM has traditionally meant copying a full OOTB index definition, editing it, and managing index versions by hand. Simplified Index Management replaces that with a single `diff.json` describing only the *delta*. At deploy/merge time the diff is combined with the latest OOTB index and, if the result differs from the current merged index, a new version is created automatically.

**Pipeline Mode** is the Cloud Service path. In the program's Git repo you add `ui.apps/src/main/content/jcr_root/_oak_index/diff.index/.content.xml` (a fixed compatibility stub with `type="lucene"` and intentionally non-existent `includedPaths`/`queryPaths` so existing tooling doesn't build a large index) plus the real `diff.json`, and register `/oak:index/diff.index` in `filter.xml`. Running the pipeline performs the merge. Because the diff index is processed outside AEM, the feature works on all AEM releases.

**RDE & Local Quickstart** applies changes immediately without a pipeline (requires AEMaaCS 2026.05 / Oak 1.92+). In CRX/DE you create a `diff.index` node (`oak:QueryIndexDefinition`, `type="disabled"`) containing a `diff.json` (`nt:file`); saving triggers a new index version and immediate reindexing. Not for large repos or Cloud Service DEV.

The **merge rules** are deliberately additive and non-destructive: top-level `includedPaths`/`queryPaths`/`tags` are unioned but never introduced where absent; a set of properties (`selectionPolicy`, `valueRegex`, `queryFilterRegex`, `excludedPaths`) cannot be added to an existing index; existing values are never overwritten. Under `properties`, children are matched by `name` (then `function`) value, and the indexing-shape properties (`isRegexp`, `index`, `function`, `name`) are frozen on existing children; only `boost`/`weight` of existing properties are mutable. A normalized, prefix-stripped comparison (dropping `reindex`, `:version`, `mergeInfo`, etc., and ignoring property order but not child-node order) plus a SHA-256 checksum detects real changes efficiently across runs.

## Entities Mentioned

- [[adobe-experience-manager]] — the platform (AEM as a Cloud Service) this tooling targets.
- Apache Jackrabbit Oak — the JCR/content repository whose query indexes are being managed (version 1.92+ required for immediate mode).
- oakTools / oak-indexing (GitHub) — host of the documentation and the Analyzer/Verifier tools.

## Concepts

- [[aem-oak-index-management]] — diff-based, auto-merged, auto-versioned Oak index customization; this source is its primary reference.

## Notes

- No author or publication date given in the clipping.
- The fixed `.content.xml` stub uses deliberately non-existent paths (`/same`) so legacy tooling doesn't build a large index for the compatibility placeholder.
- Tika configuration of OOTB indexes is not needed in the diff; for fully custom indexes Tika config is only required when the definition has analyzed properties or an aggregation.

## See Also

- [[aem-oak-index-management]]
- [[adobe-experience-manager]]
- [[aem-cloud-service-intro]]
