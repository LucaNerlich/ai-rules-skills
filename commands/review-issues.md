---
description: Adversarially review the PR stack in a fresh context and post verify-first agent instructions
argument-hint: "[PR numbers...] [--stack] [--all]"
---

Load and follow the **`review-issues`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/review-issues/SKILL.md`
and treat that file as the skill.

This phase posts comments only — no pushes, no merges. End with the re-file handoff block so
unresolved findings can re-enter the backlog via `/create-issues`.

Arguments: $ARGUMENTS
