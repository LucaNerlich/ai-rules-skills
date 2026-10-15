---
description: Run the full sweep chain — scan, file clustered issues, fix them as file-disjoint stacks, review every stack, and commit review fixes onto the reviewed layer
argument-hint: "[scope...] [--scope path|module|feature] [--depth report|file|fix|review] [--priority high|medium|low] [--max N] [--issue-grouping recommended|coarse|strict] [--pr-grouping recommended|strict|coarse] [--max-layers N] [--stacks auto|by-module|by-priority|N] [--include-speculative] [--fix-on-layer] [--resume id] [--yes]"
---

Read `{{SKILLS_DIR}}/sweep/SKILL.md` and follow it exactly as written — it is the **`sweep`**
skill. It runs `find-problems`, `create-issues`, `fix-issues`, and `review-issues` from the
sibling directories beside it. (These skills set `disable-model-invocation`, so a skill tool
may refuse to load them; the path always works.)

Arguments: $ARGUMENTS
