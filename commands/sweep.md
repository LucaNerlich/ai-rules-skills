---
description: Run the full sweep chain — scan, file clustered issues, fix them as file-disjoint stacks, review every stack, fix every finding, and optionally merge the reviewed PRs
argument-hint: "[scope...] [--scope path|module|feature] [--depth report|file|fix|review|merge] [--priority high|medium|low] [--max N] [--issue-grouping recommended|coarse|strict] [--pr-grouping recommended|strict|coarse] [--grouping recommended|coarse|strict] [--max-layers N] [--stacks auto|by-module|by-priority|N] [--include-speculative] [--merge-method squash|merge|rebase] [--merge-engine auto|stack|pr|git] [--resume id] [--yes]"
---

Read `{{SKILLS_DIR}}/sweep/SKILL.md` and follow it exactly as written — it is the **`sweep`**
skill. It runs `find-problems`, `create-issues`, `fix-issues`, `review-issues`, `fix-findings`,
and `merge-prs` from the sibling directories beside it. (These skills set
`disable-model-invocation`, so a skill tool may refuse to load them; the path always works.)

`--depth merge` is the only path that merges; it still refuses unreviewed PRs, unhandled findings,
failing checks, and branch protection.

Arguments: $ARGUMENTS
