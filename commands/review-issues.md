---
description: Adversarially review the PR stack in a fresh context and post verify-first agent instructions
argument-hint: "[PR numbers...] [--stack] [--all]"
---

Load and follow the **`review-issues`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/review-issues/SKILL.md`
and treat that file as the skill.

This phase posts comments only — no pushes, no merges. End with two handoff lists: on-layer
findings stay on that branch; only out-of-scope findings go to `/create-issues`.

Arguments: $ARGUMENTS
