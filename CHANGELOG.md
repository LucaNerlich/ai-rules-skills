# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.0] - 2026-10-19

### Added

- `release-version` skill for cutting releases in any repo — Node, Maven, Gradle, Rust,
  Python, .NET, Go, PHP, Ruby, Elixir, Helm, Tauri/Electron, and tag-only projects — with
  per-ecosystem adapters in `references/ecosystems.md`.
- A release plan gate, changelog promotion (including Keep a Changelog link references),
  exact-path staging, verification, and a recovery/resume path.
- Optional `gh` integration: repo and default-branch resolution, GitHub Releases
  (`--release`), and release-branch PRs for protected branches, with a git-only fallback.
- `sweep` pipeline (`find-problems` → `create-issues` → `fix-issues` → `review-issues`)
  with scope resolution, grouping controls, and stacked PRs.
- `session-summary` skill for local and cloud agents.
- Obsidian workspace-search skills.
- Vendored skill bundles: pstack, the Ponytail ruleset, Better Auth, rams, UI skills,
  React best practices, and web design guidelines.
- Practical `references/usage.md` guides for every sweep-chain skill.

### Changed

- `install.sh` installs whole skill bundles, prunes stale files, writes command wrappers
  against each harness's installed copy, and never touches machine state.
- `sweep` is scope-first-class and passes the confirmed repo, scope token, and resolved
  paths to its child skills.
- `session-summary` supports cloud agents and safer triggers.
- README documents the skill chain, install options, and MCP configuration.

### Fixed

- `sweep` no longer forks, stalls, or re-asks; blocked issues resume and the review loop
  closes.
- `review-issues` line typing, dedupe, dismissal authority, and out-of-scope routing
  corrected.
- `fix-issues` no longer re-fixes in-flight issues; stack caps and blocked retries are
  handled.
- `create-issues` hardened for standalone installs, with clustered and detailed issue
  bodies.
- `find-problems` Ponytail ruleset contradictions resolved.
