---
description: Run the full sweep chain — scan, file clustered issues, fix them as file-disjoint stacks, review every stack, and commit review fixes onto the reviewed layer
argument-hint: "[scope...] [--scope path|module|feature] [--depth report|file|fix|review] [--priority high|medium|low] [--max N] [--issue-grouping recommended|coarse|strict] [--pr-grouping recommended|strict|coarse] [--max-layers N] [--stacks auto|by-module|by-priority|N] [--include-speculative] [--fix-on-layer] [--resume id] [--yes]"
---

Load and follow the **`sweep`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/sweep/SKILL.md` and treat
that file as the skill (it delegates to `find-problems`, `create-issues`, `fix-issues`, and
`review-issues`, which sit beside it).

Arguments: $ARGUMENTS
