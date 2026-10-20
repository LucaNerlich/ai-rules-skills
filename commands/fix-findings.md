---
description: Fix every finding /review-issues posted — on the reviewed layer, or in a file-disjoint stack for out-of-scope work
argument-hint: "[PR numbers...] [--stack] [--all] [--review path] [--severity blocker|major|minor|nit] [--on-layer-only] [--dry-run]"
---

Read `{{SKILLS_DIR}}/fix-findings/SKILL.md` and follow it exactly as written — it is the
**`fix-findings`** skill.

This phase writes code, commits onto existing PR branches, and can file issues and open a new
stack for out-of-scope findings. Verify every finding before changing anything; never fix a
dismissed finding, never file an on-layer finding, and leave merging to the opt-in `/merge-prs`.

Arguments: $ARGUMENTS
