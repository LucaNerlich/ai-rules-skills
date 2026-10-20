---
description: Run the sweep pipeline to ready-to-merge by default — scan, file issues, fix as stacks, review every PR, fix every finding; optionally merge
argument-hint: "[scope...] [--scope path|module|feature] [--depth report|file|fix|review|merge] [--priority high|medium|low] [--max N] [--issue-grouping recommended|coarse|strict] [--pr-grouping recommended|strict|coarse] [--grouping recommended|coarse|strict] [--max-layers N] [--stacks auto|by-module|by-priority|N] [--include-speculative] [--merge-method squash|merge|rebase] [--merge-engine auto|stack|pr|git] [--resume id] [--yes]"
---

Read `{{SKILLS_DIR}}/sweep/SKILL.md` and follow it exactly as written — it is the **`sweep`**
skill. It runs `find-problems`, `create-issues`, `fix-issues`, `review-issues`, `fix-findings`,
and `merge-prs` from the sibling directories beside it. (These skills set
`disable-model-invocation`, so a skill tool may refuse to load them; the path always works.)

The default is `--depth review`: one run gate, then create → fix → review → fix findings with no
phase handoffs, ending at ready-to-merge. Lower depths are explicit stops. `--depth merge` adds
the opt-in merge gate; `--yes` skips the questions.

Arguments: $ARGUMENTS
