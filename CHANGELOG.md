# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- `fix-findings` skill and `/fix-findings` command: the fifth phase of the pipeline verifies every
  finding `/review-issues` posted, commits on-layer findings onto their reviewed branch, and files
  then fixes out-of-scope findings in a separate file-disjoint stack off trunk. It replies on each
  finding with a `fix-findings:fixed|not-reproduced|filed` marker and resolves the threads it
  handled.
- `--on-layer-only` and `--dry-run` for the new phase.
- `merge-prs` skill and `/merge-prs` command: the opt-in last phase merges a gh-stack chain
  bottom-up with `gh stack merge` (longest eligible prefix), regular PRs with `gh pr merge`, or
  plain git when explicitly chosen. It requires a review verdict, every finding handled, green
  checks, and a mergeable PR; it reports merge-queue enqueues as queued and never bypasses branch
  protection.
- `--depth merge`, `--merge-method`, and `--merge-engine` for sweep, plus `merges.md` run state.
- `review-issues` now writes a `review-issues:verdict` marker with the reviewed head and diff
  hash, which `/merge-prs` uses as proof the review ran and that the merged diff is the reviewed
  one (or a recorded fix).

### Changed

- Re-vendored the Ponytail ruleset at 5.3.2: refreshed the before-you-write/ladder rules,
  renamed deferred markers to `shortcut:` (older `ponytail:` markers still count), and updated
  the review/audit/debt formats.
- `sweep` now defaults to `--depth review` and runs create → fix → review → fix findings in one
  pass behind a single run gate. The separate file, fix, review, and post-review gates are gone;
  a phase ending on success no longer stops the run or prints a next-command handoff. Lower depths
  are explicit stops.
- `--depth merge` is the only depth that merges. `fix-issues` still never merges; the opt-in merge
  step owns it.
- `--fix-on-layer` is accepted as a deprecated no-op: fixing on-layer findings is the default at
  `--depth review`.
- `review-issues` handoff entries now carry a `title`, which `fix-findings` uses for its commit
  messages and replies.
- `fix-findings` fixed replies carry the pushed diff hash, so `/merge-prs` can tell a recorded fix
  from a change pushed after the fix.
- `install.sh` now defaults to `~/.agents`, `~/.copilot`, `~/.cursor`, and `~/.config/opencode`;
  `--harness` adds one, `--all-harnesses` restores discovery, and `--list-harnesses` prints the
  resolved set.

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
