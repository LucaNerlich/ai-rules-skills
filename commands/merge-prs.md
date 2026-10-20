---
description: Merge the reviewed and fixed PRs — gh-stack bottom-up, regular PRs, or explicit git — only when every finding is handled and checks are green
argument-hint: "[PR numbers...] [--stack] [--all] [--review path] [--engine auto|stack|pr|git] [--merge-method squash|merge|rebase] [--dry-run] [--yes]"
---

Read `{{SKILLS_DIR}}/merge-prs/SKILL.md` and follow it exactly as written — it is the
**`merge-prs`** skill.

This phase merges code. Only the reviewed set with a verdict, every finding handled, green checks,
and a mergeable PR is eligible. Never bypass branch protection, never merge an unreviewed PR, and
never merge the out-of-scope stack from the same run.

Arguments: $ARGUMENTS
