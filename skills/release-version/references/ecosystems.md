# Release Version — ecosystem adapters

One row per ecosystem. `SKILL.md` owns the policy; this file owns the mechanics. When a repo does
something not listed here, follow its existing convention and add the row.

Each row answers: **where the version lives**, **how to edit it**, **what else must move**, **how
to verify**, and **what bites**.

---

## Node.js / JavaScript / TypeScript

**Detect:** `package.json`.

**Source of truth:** the `"version"` field of the release unit's `package.json`. If the field is
missing, the package is private-only or versionless — do not add one unasked; treat as tag-only.

**Edit:**

```bash
npm version <new-version> --no-git-tag-version --ignore-scripts
```

- `--ignore-scripts` matters: `preversion`/`version`/`postversion` hooks in some repos commit, tag,
  or build.
- In a **workspace root**, `npm version` with `--workspaces` bumps every package. For one package,
  `cd` into it or pass `--workspace <name>`. Prefer a targeted JSON edit when the tool would touch
  siblings.
- In a **pnpm** repo: `pnpm version <ver> --no-git-tag-version` (pnpm also refuses dirty trees —
  check `git status` first). Workspace bumps use `pnpm -r exec npm version …` only if the repo
  releases in lockstep.
- In a **yarn** repo: `yarn version --new-version <ver> --no-git-tag-version` (Yarn 2+ also updates
  the lockfile in place). Yarn 1: same flag.

**Sync:** `package-lock.json` (npm), `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn). Only when the
lockfile records the root package version.

| Package manager | Refresh lockfile |
|---|---|
| npm | the `npm version` call above already does it |
| pnpm | `pnpm install --lockfile-only` |
| yarn 1 | `yarn install --ignore-scripts` |
| yarn 2+ | `yarn install --mode update-lockfile` (**Yarn 2+ only**) |
| bun | `bun install --lockfile-only` |

**Verify:** `npm pkg get version` (or `jq -r .version package.json`) prints `<new-version>`;
`npm ls --depth=0` still resolves.

**Bites:** `version` inherited from a workspace root (bump the root, not the member); `workspace:*`
protocol deps; `private: true` packages published by a different tool; `engines` unaffected;
`bun.lockb` binary lockfile (use `bun install`, never hand-edit).

---

## Java / Maven

**Detect:** `pom.xml`.

**Source of truth:** the `<version>` that is a **direct child of `<project>`**. It may be absent
(inherited from `<parent>`) — then the parent owns it, or the project uses `${revision}`.

**Edit (default, single module):**

```bash
mvn -q versions:set -DnewVersion=<new-version> -DgenerateBackupPoms=false
```

**Edit (multi-module — do not use `versions:set` blindly):** it rewrites every module's version and
every `<parent>` reference. Use a targeted XML-aware edit of the root `<project><version>`, then
check whether children declare their own `<version>`.

**CI-friendly versions:** if the POM uses `<revision>` (with `flatten-maven-plugin`), edit the
`<revision>` property, not `<version>`. Detect with
`grep -n '<revision>' pom.xml`.

**Sync:** `pom.xml` only. Update `<parent><version>` only if it points at this same project.

**Verify:** `mvn -q help:evaluate -Dexpression=project.version -DforceStdout` prints
`<new-version>`; `mvn -q validate` passes.

**Bites:** `-SNAPSHOT` suffixes (strip at release only if the repo's convention says so); module
versions that intentionally differ from the parent; `<dependencyManagement>` entries that reference
sibling modules; Gradle-generated POMs.

---

## Java / Kotlin — Gradle

**Detect:** `build.gradle`, `build.gradle.kts`, or `gradle.properties`.

**Source of truth:** in priority order —
1. `gradle.properties` `version=` (most common),
2. `version = "..."` / `version = '...'` at the top level of the build script,
3. a plugin (`axion-release`, `nebula-release`, `researchgate/gradle-release`) computing from git →
   **tag only, do not edit**,
4. `-Pversion` passed by CI → **not editable in the repo**.

**Edit:** your file-editing tool, targeting the top-level `version` line only. Not `sed` — it
matches dependency coordinates and `version =` inside blocks.

**Sync:** nothing. `gradle/libs.versions.toml` is for dependencies, not this project.

**Verify:** `./gradlew -q properties | grep '^version:'` (or `./gradlew properties -q`) prints the
new version; `./gradlew -q help` succeeds.

**Bites:** `version` declared in `subprojects {}`/`allprojects {}`; Android `versionName` +
`versionCode` in `defaultConfig` (bump `versionName`; `versionCode` is a separate integer that
usually increments by 1); Kotlin DSL `version = "x"` vs Groovy `version = 'x'`; `gradle.properties`
may hold `version` for one module and `projectVersion` for another.

---

## Rust / Cargo

**Detect:** `Cargo.toml`.

**Source of truth:** `[package] version`, or `[workspace.package] version` when members declare
`version.workspace = true`.

**Edit:** your file-editing tool on that key. Do not use `cargo set-version` unless
`cargo-edit` is installed and the repo is a single crate; in a workspace it needs
`-p <crate>` and `--workspace` care.

**Sync:** `Cargo.lock` records workspace package versions — refresh it:

```bash
cargo check --workspace --offline   # or: cargo metadata --format-version 1 >/dev/null
```

Prefer `cargo check`/`metadata` over `cargo update --workspace`: `cargo update` resolves and moves
unrelated dependencies.

**Verify:** `cargo metadata --no-deps --format-version 1 | jq -r '.packages[] | select(.name=="<crate>") | .version'`
prints `<new-version>`; `cargo check` succeeds.

**Bites:** members inheriting `version.workspace = true` (edit the root only); `[workspace.dependencies]`
path deps with `version =` fields that must match; `publish = false` crates that still version;
workspaces that release crates independently (ask which); `Cargo.lock` v4.

---

## Python

**Detect:** `pyproject.toml`, `setup.py`, `setup.cfg`.

**Source of truth:**

| Marker | Where |
|---|---|
| `[project] version = "x"` | `pyproject.toml` (PEP 621) |
| `[tool.poetry] version = "x"` | `pyproject.toml` (Poetry) |
| `[tool.hatch.version] path = "…"` | that path (often `src/pkg/__init__.py`) |
| `[metadata] version = x` | `setup.cfg` |
| `version="x"` in `setup(...)` | `setup.py` |
| `dynamic = ["version"]` + setuptools-scm/hatch-vcs | **not in a file — tag only** |
| `__version__ = "x"` | package `__init__.py` (mirror) |

**Edit:** your file-editing tool on the exact key. For Poetry, `poetry version <new-version>`
edits `pyproject.toml` and leaves the lock hash stale.

**Sync:** `poetry.lock` → `poetry lock` (Poetry 2.x no longer refreshes dependencies by default;
on 1.x use `poetry lock --no-update`). `uv.lock` → `uv lock --offline`. `Pipfile.lock` is
dependency-only — leave it.

**Verify:** `python -c "import tomllib,pathlib;print(tomllib.loads(pathlib.Path('pyproject.toml').read_text())['project']['version'])"`
(or the `[tool.poetry]` equivalent); `python -m build --sdist --no-isolation` succeeds if a build
toolchain is present.

**Bites:** PEP 440 is not semver — use `1.2.3rc1`, not `1.2.3-rc.1`, unless the repo already uses
hyphens; `dynamic` versions must not be edited; keep `__version__` in sync when both exist; namespace
packages; `setup.cfg` `[metadata]` indentation.

---

## .NET / C#

**Detect:** `Directory.Build.props`, `*.csproj`, `*.fsproj`, `*.vbproj`.

**Source of truth:** `<Version>` in the nearest `Directory.Build.props` (repo-wide, far more common
than per-project) or in the project file.

**Edit:** your file-editing tool. Update `<AssemblyVersion>` / `<FileVersion>` / `<VersionPrefix>` /
`<VersionSuffix>` only when present and mirroring the version.

**Sync:** `Directory.Packages.props` is central *package* management — unrelated. `packages.lock.json`
only if the repo uses locked restore.

**Verify:** `dotnet msbuild -getProperty:Version` prints `<new-version>`.

**Bites:** `VersionPrefix` + `VersionSuffix` compose the version (e.g. `1.2.3` + `beta` →
`1.2.3-beta`); `Directory.Build.props` files can nest per directory; a solution may contain several
independently versioned projects (ask which).

---

## Go

**Detect:** `go.mod` — but **there is no version field**. Tags are the version.

**Action:** tag only; no manifest edit, no commit if nothing else changes.

**Tag shape:** `v1.2.3` (mandatory `v`). For `v2+`, the **module path** must end in `/v2`
(`module example.com/foo/v2`). A `v2.0.0` tag on a `v1` module path is invalid — stop and tell the
user to update `go.mod` first, in a separate commit.

**Verify:** `go build ./...`; `git tag --list '<tag>'`.

**Bites:** `+incompatible` for `v2+` without a module path bump; submodule tags
(`sub/v1.2.3` for nested modules — tag each module); `retract` directives in `go.mod`.

---

## PHP / Composer

**Detect:** `composer.json`.

**Source of truth:** Composer packages are usually versioned by **tag**, not by a field. A `version`
key is discouraged and often absent. If present, edit it; if absent, tag only.

**Verify:** `composer validate --no-check-publish`; `composer show --self` prints the version when
derived from a tag or branch alias.

**Bites:** branch aliases (`dev-main` → `1.2.x-dev`); monorepo split packages tagged per
subdirectory; `composer.lock` is dependency-only.

---

## Ruby

**Detect:** `*.gemspec`, `lib/**/version.rb`, `Gemfile`.

**Source of truth:** usually `VERSION = "x.y.z"` in `lib/<gem>/version.rb`, referenced by the
gemspec. Sometimes the gemspec literal.

**Edit:** your file-editing tool on the constant.

**Sync:** `Gemfile.lock` only if the gem depends on itself (rare). Never bump dependency versions.

**Verify:** `ruby -e "require './lib/<gem>/version'; puts <Gem>::VERSION"`; `gem build <gem>.gemspec`.

**Bites:** `Gem::Version` ordering (`.rc1` sorts before the release); `Bundler.locked_gems`
mirroring the version in some setups; `-pre` suffixes.

---

## Elixir

**Detect:** `mix.exs`.

**Source of truth:** `version: "x.y.z"` in `def project do … end`.

**Edit:** your file-editing tool on that key. `mix hex.publish` does not bump it for you.

**Sync:** `mix.lock` is dependency-only — leave it.

**Verify:** `mix run -e 'IO.puts(Mix.Project.config()[:version])'`.

**Bites:** umbrella apps version each child app separately; `@version` module attributes mirroring
the project version.

---

## Helm

**Detect:** `Chart.yaml`.

**Source of truth:** `version` (the chart version) **and** `appVersion` (the app it ships) — both
must move, and they are not always equal.

**Edit:** your file-editing tool on both keys. Quote `appVersion` if the existing file does.

**Verify:** `helm lint .`; `helm show chart .` prints both values.

**Bites:** `appVersion` may be a non-semver string or contain build metadata; `Chart.lock` is for
dependencies only; chart `version` must increase even when only `appVersion` changes (chart repos
reject a duplicate).

---

## Tauri / Electron / browser extensions

These own **several** manifests that must move together.

| Project | Files to bump |
|---|---|
| Tauri | `package.json` `version`, `src-tauri/Cargo.toml` `[package] version`, `src-tauri/tauri.conf.json` `version` (and `package.productName`/`version` if present) |
| Electron (electron-builder) | `package.json` `version`; `electron-builder.yml`/`build` block only if it hard-codes a version |
| Browser extension | `manifest.json` `version` (MV3 requires 1–4 dot-separated integers — **no** prerelease suffixes) |

**Verify:** Tauri: `cargo metadata --manifest-path src-tauri/Cargo.toml --no-deps`; extension: the
manifest still parses and `version` matches the plan.

**Bites:** Tauri reads the Cargo version at build time — bump *before* building. Chrome Web Store
rejects `1.2.3-beta`.

---

## Tag-only / git-describe projects

**Detect:** no version field anywhere, or a `dynamic`/plugin-computed version.

**Action:** create the tag only. Skip Step 5 and the commit entirely if nothing else changed — do
not invent an empty release commit.

**Bites:** a build that stamps `git describe --tags --dirty` must run **after** the tag; annotated
tags are required for `git describe` to see them by default; shallow CI clones need
`fetch-depth: 0`.

---

## Versionless / unusual schemes

- **Calendar versioning (`2026.10.0`):** derive from the date (`date +%Y.%m`) and the repo's
  existing release count. Ask when the scheme is not obvious from the last three tags.
- **Non-semver schemes** (`1.2`, `1.2.3.4`, date-based): follow the existing shape exactly; do not
  "correct" it to semver.
- **Independent multi-package monorepos** (Nx, Turborepo, pnpm workspaces, Lerna): each package is
  its own release unit with its own tag and changelog. Release one per invocation unless the repo
  uses fixed/lockstep versioning — check `lerna.json` `version`, `nx.json` release config, or a
  shared `version` in the root.
