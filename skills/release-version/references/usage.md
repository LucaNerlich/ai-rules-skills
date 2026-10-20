# Release Version — practical guide

`SKILL.md` is the normative instruction set. This file is the walkthrough. If the two disagree,
`SKILL.md` wins.

## Run it

```
/release-version                      # derive the bump from history, show the plan, then release
/release-version --bump minor         # force a minor bump
/release-version --version 2.0.0      # exact version (still shows the plan)
/release-version --dry-run            # print the plan, touch nothing
/release-version --no-push            # commit + tag locally
/release-version --release            # also create a GitHub Release from the tag
/release-version --no-release         # never create one, even if gh is available
/release-version --prerelease rc      # 1.4.0 → 1.4.0-rc.1
```

The skill always shows a **plan** first — old → new, tag name, branch, files, changelog counts —
and waits. `--yes` skips the gate; use it only in a scripted/CI context where a human already
approved the version.

## What it will not do

- Bump a version it cannot find. If the repo is tag-only (Go, git-describe, a gemspec version
  constant) it says so and releases the tag.
- Overwrite an existing tag, local or remote.
- `git push --tags` — it pushes the branch and the one tag it just created.
- Hand-write a changelog that Changesets, release-please, semantic-release, or git-cliff owns.
- Guess which package to release in a monorepo when the CWD does not identify one.

## Worked examples

### Single package, conventional commits

```
$ /release-version
Release plan
  Unit:        repo (Node.js)
  Current:     1.3.2
  New:         1.4.0  (minor — feat: add retry policy)
  Tag:         v1.4.0
  Branch:      main → origin/main (ahead by 6 commits)
  Files:       CHANGELOG.md, package.json, package-lock.json
  Changelog:   4 entries — Added 1, Fixed 2, Changed 1
```

Commits since `v1.3.2` include one `feat:` and two `fix:`, so the bump is minor. The plan is shown,
approved, then: changelog section added, `npm version 1.4.0 --no-git-tag-version --ignore-scripts`,
lockfile refreshed, `git diff --stat` reviewed, commit `chore: release v1.4.0`, tag `v1.4.0`, branch
and tag pushed individually.

### Monorepo, one package

```
$ cd packages/api && /release-version
  Unit:        packages/api (Node.js)
  Tag:         @acme/api@1.2.0        # detected from existing tags, not assumed v*
```

The tag convention comes from `git tag --list --sort=-creatordate`. If the repo tags
`packages/api/v1.2.0` instead, that is what gets created. The CWD is inside `packages/api`, so no
question is asked; from the repo root it would ask.

### Rust workspace

```
$ /release-version --bump patch
  Unit:        repo (Cargo workspace)
  Files:       CHANGELOG.md, Cargo.toml ([workspace.package]), Cargo.lock
```

Members use `version.workspace = true`, so only the root moves. `cargo check` refreshes
`Cargo.lock`; `cargo metadata` confirms the reported version.

### Tag-only (Go)

```
$ /release-version
  Unit:        repo (Go)
  Current:     v0.9.1
  New:         v0.9.2  (patch — 2 fix commits)
  Files:       (none — tag only)
```

No manifest is edited and no release commit is created. If the tag would be `v2.0.0` while
`go.mod` still declares a `v1` module path, the skill stops and asks for the `/v2` path bump as a
separate commit.

### Prerelease

```
$ /release-version --prerelease rc
  Current: 1.4.0
  New:     1.5.0-rc.1
```

The changelog section is labelled `1.5.0-rc.1`; the final `1.5.0` release promotes or replaces it.

## Multi-manifest projects

Tauri, Helm, .NET, and lockstep monorepos need several files to move together. The skill greps for
the old version across manifests before editing, lists every hit in the plan, and re-greps before
committing. If a hit is intentionally left alone (a dependency that happens to share the version
number), it appears under **Skipping** with a reason.

## GitHub CLI

`gh` is optional but worth having: when it is installed **and** authenticated, the skill uses it
for four things plain git does poorly.

| What | Command | Without `gh` |
|---|---|---|
| Repo identity | `gh repo view --json nameWithOwner` | parse `origin`'s URL — wrong on forks/multiple remotes |
| Default branch | `gh repo view --json defaultBranchRef` | `refs/remotes/origin/HEAD`, often missing |
| Existing release | `gh release view "<tag>"` | `git ls-remote --tags origin "<tag>"` |
| Create the release | `gh release create --verify-tag --notes-from-tag` | skipped, manual command printed |

Run `gh auth status` once. The skill does not log you in. If `gh` is missing, logged out, or the
remote is GitLab/Bitbucket/Gitea, it continues in **git-only mode**: branch + tag push still work,
`--release` is ignored with a warning, and the summary says so.

Protected branches are the other reason to install it. Instead of failing the push, the skill puts
the release commit on `release/<tag>`, opens a PR with `gh pr create`, and creates the tag after the
merge:

```
/release-version --release   # on a protected main → branch + PR, tag waits for merge
```

In repos where publishing is wired to a GitHub Release event, `--release` is the step that actually
ships artifacts — the plan says `Release: will create` before anything is pushed.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "no recognised version manifest" | The repo is tag-only, or the manifest is in a subdirectory the CWD does not identify. | `cd` into the package, pass the path, or accept a tag-only release. |
| Bump is one level too high | A commit body contains `BREAKING CHANGE:` or a `!` subject. | Check `git log <tag>..HEAD --format='%s%n%b'`; override with `--bump patch`. |
| Changelog entry lands in the wrong place | The file uses an unusual layout (Unreleased at the bottom, per-package changelogs). | Edit the section by hand after the run, or point the skill at the right file. |
| Push rejected | Branch protection or stale upstream. | The commit and tag stay local; the summary gives the exact resume commands. |
| Tag already exists | A previous partial run, or the version was already released. | Resume from the tag step, or cut a new patch version. |
| Lockfile shows unrelated changes | The bump tool resolved dependencies. | Revert the lockfile and refresh it with the lock-only command from `references/ecosystems.md`. |
| CI releases conflict | release-please / semantic-release owns the version. | Use `--no-changelog` and let CI own the bump, or stop using this skill in that repo. |
| `--release` did nothing | `gh` missing, logged out, or the remote is not GitHub. | The summary says `unavailable (no gh)`; run `gh auth status`, or create the release with the printed command. |

## Optional companions

Nothing here requires another skill. `/sweep`, `/find-problems`, `/create-issues`, `/fix-issues`,
`/review-issues`, `/fix-findings`, and `/merge-prs` live in the same bundle at
[github.com/LucaNerlich/ai-rules-skills](https://github.com/LucaNerlich/ai-rules-skills):

```
git clone https://github.com/LucaNerlich/ai-rules-skills.git
cd ai-rules-skills && ./install.sh                    # everything
./install.sh --only release-version                   # just this one
```

Or copy `skills/release-version/` next to this skill's directory in your harness's skills folder.
