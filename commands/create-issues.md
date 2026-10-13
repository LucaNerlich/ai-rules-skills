---
description: Turn findings into clustered, evidence-backed GitHub issues labelled priority:high|medium|low
argument-hint: "[source: report path, PR/issue URL, or nothing to scan]"
---

Load and follow the **`create-issues`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/create-issues/SKILL.md`
and treat that file as the skill.

This phase writes issues only — never code, branches, or PRs. Confirm the batch with the user
before creating anything.

Arguments: $ARGUMENTS
