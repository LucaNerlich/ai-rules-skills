---
description: Cut a release — derive the next semver, update changelog and every version manifest, commit, tag, push
argument-hint: "[--bump patch|minor|major] [--version x.y.z] [--tag name] [--from ref] [--prerelease rc|beta|alpha] [--no-changelog] [--no-push] [--sign] [--release|--no-release] [--dry-run] [--yes]"
---

Read `{{SKILLS_DIR}}/release-version/SKILL.md` and follow it exactly as written — it is the
**`release-version`** skill. Read `{{SKILLS_DIR}}/release-version/references/ecosystems.md` for the
manifest mechanics of the repo you are in.

Show the release plan and wait for approval before writing anything (unless `--yes`). Never
`git push --tags`, never force an existing tag, and stage exact paths rather than globs.

Arguments: $ARGUMENTS
