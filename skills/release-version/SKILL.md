---
name: release-version
description: Automate project releases — updates CHANGELOG.md, bumps the version in package.json, commits, tags, and pushes. Use this skill whenever the user says "release", "bump version", "cut a release", "new version", "update changelog and release", "ship it", "tag a release", "prep a release", or asks to bump a patch/minor version. Also trigger when the user asks to update the changelog and push a new version, or when they mention versioning workflow, release workflow, or semver bumping in the context of a Node/JS project with a package.json.
---

# Release Version

Automate the full release cycle for a project: changelog → version bump → commit → tag → push.

## Prerequisites

- The project must have a `package.json` with a `version` field.
- Git must be initialised and have a remote configured.
- The working tree should be clean before starting (no uncommitted changes unrelated to the release). If it is not, warn the user and ask whether to proceed.

## Workflow

### Step 1 — Understand what changed

Before touching any files, gather context about what has changed since the last release:

```bash
# Find the latest version tag (v* pattern)
git describe --tags --abbrev=0 --match="v*" 2>/dev/null || echo "no-previous-tag"
```

If a previous tag exists, collect the commit log since that tag:

```bash
git log <previous-tag>..HEAD --oneline --no-merges
```

If no previous tag exists, use the full commit history (or a reasonable recent window).

Read through the commits and categorise them mentally into:
- **Features / enhancements** (new behaviour, new flags, new endpoints, etc.)
- **Bug fixes** (corrections to existing behaviour)
- **Chores / maintenance** (dependency bumps, CI tweaks, refactors, docs)
- **Breaking changes** (anything that changes public API or behaviour in a non-backwards-compatible way)

### Step 2 — Decide the version bump

Apply these rules to decide the bump level:

| Condition | Bump |
|---|---|
| Any breaking change | **major** (but see note below) |
| At least one new feature or enhancement | **minor** |
| Only bug fixes, chores, docs, or refactors | **patch** |

> **Note on major bumps:** Only bump major if the project is already at `>=1.0.0`. For `0.x.y` projects, a breaking change should bump **minor** instead (per semver convention for pre-1.0 software). If you detect a potential major bump, **ask the user to confirm** before proceeding — major releases deserve explicit approval. For patch and minor bumps, proceed without asking.

### Step 3 — Update CHANGELOG.md

Check whether `CHANGELOG.md` exists in the project root.

**If it exists:** read it and insert a new section at the top (below any title/header), following whatever formatting convention the file already uses. Preserve the existing style (e.g. Keep a Changelog format, bullet style, date format). If the existing format is not obvious, default to the template below.

**If it does not exist:** create `CHANGELOG.md` with the following structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [<new-version>] - <YYYY-MM-DD>

### Added
- <feature descriptions>

### Fixed
- <bugfix descriptions>

### Changed
- <other notable changes>
```

Rules for the changelog entry:
- Use today's date in `YYYY-MM-DD` format.
- Only include sections (Added / Fixed / Changed / Removed) that have entries — omit empty sections.
- Write entries from the user's perspective, not the developer's. Prefer "Added support for X" over "Implemented X handler in module Y".
- Each entry should be a single concise line. Group related commits into one entry where it makes sense rather than listing every commit verbatim.

### Step 4 — Bump the version in package.json

Read the current version from `package.json`, compute the new version, and update the file:

```bash
# Use npm version to bump (this only changes package.json, does NOT commit or tag)
npm version <patch|minor|major> --no-git-tag-version
```

If `package-lock.json` exists, `npm version` will update it automatically. If `yarn.lock` is present instead, run `yarn` (no-install/lockfile-only if possible) to sync the lockfile after the bump.

Record the new version string (e.g. `1.2.3`) — you will need it for the commit message and tag.

### Step 5 — Commit

Stage the changed files and commit:

```bash
git add package.json CHANGELOG.md
# Also stage lockfiles if they changed
git add package-lock.json 2>/dev/null; true
git add yarn.lock 2>/dev/null; true

git commit -m "chore: release v<new-version>"
```

### Step 6 — Tag

Create an annotated tag:

```bash
git tag -a "v<new-version>" -m "v<new-version>"
```

### Step 7 — Push

Push the commit and the tag to the remote:

```bash
git push && git push --tags
```

If the push fails (e.g. auth issues, branch protection), report the error clearly and tell the user what manual step is needed.

### Step 8 — Summary

After all steps complete, print a short summary:

```
✅ Released v<new-version>
   Bump:      <patch|minor|major>
   Changelog: updated (X new entries)
   Commit:    <short-sha>
   Tag:       v<new-version>
   Pushed:    yes
```

## Edge Cases

- **No package.json found:** Stop and tell the user. This skill requires a package.json.
- **Dirty working tree:** Warn the user about uncommitted changes and ask whether to stash them, include them in the release commit, or abort.
- **No remote configured:** Skip the push step and inform the user that the commit and tag are local only.
- **Monorepo with multiple package.json files:** Ask the user which package to release. Do not guess.
- **User explicitly requests a specific bump level:** Honour their request instead of auto-detecting.
