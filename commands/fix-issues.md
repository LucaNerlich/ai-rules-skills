---
description: Fix the priority-labelled backlog as a gh-stack stacked PR chain
argument-hint: "[issue numbers...] [--priority high|medium|low] [--max N] [--grouping recommended|coarse|strict] [--max-layers N] [--stacks auto|by-module|by-priority|N]"
---

Load and follow the **`fix-issues`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/fix-issues/SKILL.md` and
treat that file as the skill.

This phase writes code and opens PRs. Never open a PR on a failing or unrun check, and never
merge from the CLI.

Arguments: $ARGUMENTS
