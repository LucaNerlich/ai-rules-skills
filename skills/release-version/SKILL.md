---
name: release-version
description: Automate project releases — updates CHANGELOG.md, bumps the version in package.json, commits, tags, and pushes. Use this skill whenever the user says "release", "bump version", "cut a release", "new version", "update changelog and release", "ship it", "tag a release", "prep a release", or asks to bump a patch/minor version. Also trigger when the user asks to update the changelog and push a new version, or when they mention versioning workflow, release workflow, or semver bumping in the context of a Node/JS project with a package.json.
---

# Release Version

Automate the full release cycle for a project: changelog → version bump → commit → tag → push.

## Prerequisites

- The project must have at least one recognisable version manifest (see **Supported project types** below).
- Git must be initialised and have a remote configured.
- The working tree should be clean before starting (no uncommitted changes unrelated to the release). If it is not, warn the user and ask whether to proceed.

## Supported project types

Detect the project type by looking for these files in the subproject directory (or the repo root for single-project repos):

| File | Project type | Version field |
|---|---|---|
| `package.json` | Node.js / JS / TS | `"version"` JSON field |
| `pom.xml` | Java / Maven | `<version>` element (first one, directly under `<project>`, not inside `<dependencies>`) |
| `build.gradle` or `build.gradle.kts` | Java / Kotlin / Gradle | `version = "..."` or `version = '...'` at the top level |
| `gradle.properties` | Gradle (properties style) | `version=...` line |
| `Cargo.toml` | Rust | `version = "..."` under `[package]` |
| `pyproject.toml` | Python (PEP 517/518) | `version = "..."` under `[project]` or `[tool.poetry]` |
| `setup.py` / `setup.cfg` | Python (legacy) | `version=` argument |
| `*.csproj` | .NET / C# | `<Version>` element |

If none of these files are found, stop and tell the user — this skill cannot proceed without a recognised version manifest.

If **multiple** manifests are found in the same directory (e.g. a Gradle project that also has a `package.json` for frontend tooling), prefer the one that is the primary build file for the project (use heuristics: if `pom.xml` or `build.gradle` exists alongside `package.json`, treat the JVM file as primary and mention to the user that `package.json` was skipped).

## Workflow

### Step 0 — Detect monorepo context

Before anything else, determine whether you are operating inside a monorepo:

```bash
# Count package.json files under the git root (excluding node_modules)
git rev-parse --show-toplevel   # → <git-root>
find <git-root> -name "package.json" -not -path "*/node_modules/*" | wc -l
```

**If more than one `package.json` exists** (monorepo), derive the subproject name:

```bash
# The subproject name is the name of the directory containing the nearest package.json
# relative to the git root. Use the basename of the current working directory if it
# sits directly under the git root, or read the "name" field from package.json.
basename $(pwd)   # use this as <subproject> unless package.json has a cleaner name
```

Prefer the `name` field from the nearest `package.json` (strip any `@scope/` prefix and
replace `/` with `-` to make it a valid path component). If ambiguous, use the directory
basename. Store this as **`<subproject>`** — it will prefix every tag and commit message.

**If only one `package.json` exists** (single-project repo), set `<subproject>` to an
empty string and skip all prefixing below.

### Step 1 — Understand what changed

Before touching any files, gather context about what has changed since the last release.

**In a monorepo**, look for subproject-prefixed tags first:

```bash
# Find the latest subproject-scoped tag  (e.g. pilates/v1.4.1)
git describe --tags --abbrev=0 --match="<subproject>/v*" 2>/dev/null || echo "no-previous-tag"
```

**In a single-project repo**, use the plain `v*` pattern:

```bash
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

### Step 4 — Bump the version in the manifest

Read the current version, compute the new version, then update the appropriate file(s):

#### Node.js (`package.json`)

```bash
# Updates package.json (and package-lock.json if present). Does NOT commit or tag.
npm version <patch|minor|major> --no-git-tag-version
```

If `yarn.lock` is present instead of `package-lock.json`, run `yarn install --mode update-lockfile` (or equivalent) after the bump to sync the lockfile.

#### Java / Maven (`pom.xml`)

```bash
mvn versions:set -DnewVersion=<new-version> -DgenerateBackupPoms=false
```

If Maven is not available, edit `pom.xml` directly: replace the `<version>` element that is a direct child of `<project>` (not inside `<dependencies>` or `<parent>`).

#### Java / Kotlin — Gradle (`build.gradle` or `build.gradle.kts`)

Edit the file directly and replace the `version = "..."` (or `version = '...'`) line at the top level with the new version. Do not use `sed` — use the Edit tool to make a targeted replacement.

If the project uses `gradle.properties`, update the `version=` line in that file instead.

#### Rust (`Cargo.toml`)

Edit `Cargo.toml` directly: replace `version = "..."` under `[package]`. Then run:

```bash
cargo update --workspace   # regenerates Cargo.lock
```

#### Python — pyproject.toml

Edit `pyproject.toml` directly: replace `version = "..."` under `[project]` (PEP 621) or `[tool.poetry]` (Poetry). If using Poetry:

```bash
poetry version <patch|minor|major>
```

#### .NET / C# (`.csproj`)

Edit the `.csproj` directly: replace `<Version>...</Version>`. If `<AssemblyVersion>` or `<FileVersion>` are also present and match the old version, update them too.

---

Record the new version string (e.g. `1.2.3`) — you will need it for the commit message and tag.

### Step 5 — Commit

Stage the changed files and commit. Stage only the manifest file(s) that were actually modified:

```bash
git add CHANGELOG.md
# Node.js
git add package.json package-lock.json yarn.lock 2>/dev/null; true
# Java / Maven
git add pom.xml 2>/dev/null; true
# Gradle
git add build.gradle build.gradle.kts gradle.properties 2>/dev/null; true
# Rust
git add Cargo.toml Cargo.lock 2>/dev/null; true
# Python
git add pyproject.toml 2>/dev/null; true
# .NET
git add *.csproj 2>/dev/null; true

# Monorepo: "chore: release <subproject> v<new-version>"
# Single-project: "chore: release v<new-version>"
git commit -m "chore: release <subproject> v<new-version>"
```

### Step 6 — Tag

Create an annotated tag using the appropriate format:

```bash
# Monorepo:        git tag -a "<subproject>/v<new-version>" -m "<subproject>/v<new-version>"
# Single-project:  git tag -a "v<new-version>" -m "v<new-version>"
git tag -a "<tag>" -m "<tag>"
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
# Monorepo example:
✅ Released pilates/v<new-version>
   Subproject: pilates
   Bump:       <patch|minor|major>
   Changelog:  updated (X new entries)
   Commit:     <short-sha>
   Tag:        pilates/v<new-version>
   Pushed:     yes

# Single-project example:
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
- **Monorepo — which subproject:** If the CWD sits directly under the git root and contains a `package.json`, that is the target subproject. If the user is at the repo root (no `package.json` there, or multiple at the same level), ask them which subproject to release. Do not guess.
- **Monorepo — tag conflicts:** If a tag `<subproject>/v<new-version>` already exists, stop and warn the user before overwriting.
- **User explicitly requests a specific bump level:** Honour their request instead of auto-detecting.
