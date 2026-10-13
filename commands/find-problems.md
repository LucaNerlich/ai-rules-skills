---
description: Scan a codebase module-by-module with parallel subagents and produce an evidence-backed findings report (read-only)
argument-hint: "[scope...]"
---

Load and follow the **`find-problems`** skill exactly as written.

If this harness does not expose the skill, read `{{SKILLS_DIR}}/skills/find-problems/SKILL.md` and
treat that file as the skill. Also read its vendored ruleset at
`{{SKILLS_DIR}}/skills/find-problems/references/ponytail.md` and paste it into every scan
subagent, as the skill requires.

This phase is read-only: it produces a report and files nothing.

Arguments: $ARGUMENTS
