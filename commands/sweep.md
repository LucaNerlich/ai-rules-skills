---
description: Run the full sweep chain — scan for problems, file clustered issues, fix them as a stacked PR chain, review the PRs, and re-file the findings
argument-hint: "[scope...] [--depth report|file|fix|review] [--priority high|medium|low] [--max N] [--grouping recommended|coarse|strict] [--max-layers N] [--stacks auto|by-module|by-priority|N] [--yes]"
---

Load and follow the **`sweep`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/sweep/SKILL.md` and treat
that file as the skill (it delegates to `find-problems`, `create-issues`, `fix-issues`, and
`review-issues`, which sit beside it).

Arguments: $ARGUMENTS
