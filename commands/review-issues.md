---
description: Adversarially review the PR stack in a fresh context and post verify-first agent instructions
argument-hint: "[PR numbers...] [--stack] [--all]"
---

Read `{{SKILLS_DIR}}/review-issues/SKILL.md` and follow it exactly as written — it is the
**`review-issues`** skill.

This phase posts comments only — no pushes, no merges. End with two handoff lists: on-layer
findings stay on that branch; only out-of-scope findings go to `/create-issues`. `/fix-findings`
consumes both lists as the next step; `/merge-prs` uses the verdict marker in step 5.

Arguments: $ARGUMENTS
