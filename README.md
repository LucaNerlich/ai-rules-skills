# ai-rules-skills

## Install

```sh
./install.sh            # sync skills + /command wrappers into every harness on this machine
./install.sh --check    # report missing, changed, or stale files; change nothing, exit 1 if out of sync
./install.sh --init     # also create command dirs where the harness has none
./install.sh --only sweep find-problems
```

Harnesses are discovered as any `~/.<harness>/skills` or `~/.config/<harness>/skills`
that already exists, so a renamed or uninstalled harness is skipped rather than guessed at.
A skill ships its `SKILL.md` and everything under `references/`; a file left in an installed
skill that the repo no longer ships is stale, and a sync removes it. Command wrappers point at
the copy installed in the same harness.

## Sweep — the problem pipeline

One command runs the pipeline to **ready-to-merge** by default, with one gate and no phase handoffs. A review finding in the fix goes back onto that layer; only a genuine new bug becomes an issue — and gets fixed in its own file-disjoint stack:

```
/sweep                          (default --depth review)
  ├─ find-problems   → findings report                              (read-only)
  ├─ create-issues   → priority:high|medium|low issues             [run gate]
  ├─ fix-issues      → file-disjoint stacked PR chains (gh-stack)
  ├─ review-issues   → PR review comments + agent instructions
  ├─ fix-findings    → verify + fix every finding
  │   ├─ on-layer      → commit on that layer, never a new stack
  │   ├─ out-of-scope  → create-issues → file-disjoint stack off trunk
  │   └─ not reproduced → reply with evidence, change nothing
  └─ merge-prs       → merge the reviewed, fixed PRs          (opt-in: --depth merge)
```

Each phase is also a skill (and a `/command`) of its own. `/sweep` defaults to `--depth review`:
one run gate, then scan → file → fix → review → fix findings, ending with **ready to merge**. A
lower `--depth` (`report`, `file`, `fix`) is an explicit stop, and `--depth merge` adds the opt-in
merge gate. The skills live in [`skills/`](skills/), the slash-command wrappers in
[`commands/`](commands/).

`/fix-findings` is the fifth phase and a standalone skill: it verifies each posted finding,
commits on-layer findings onto their reviewed branch, and files then fixes out-of-scope findings
in a separate file-disjoint stack. A finding that does not reproduce gets a reply and no change.

`/merge-prs` is the opt-in sixth phase: it merges a stack bottom-up with `gh stack merge` up to the
longest eligible prefix, regular PRs with `gh pr merge`, and plain git only when explicitly asked.
A PR is eligible only with a `review-issues` verdict, every finding handled, green checks, and a
mergeable state; it never merges the out-of-scope stack from the same run.

Every skill has a practical guide next to it — `skills/<name>/references/usage.md` — with recipes,
worked examples, and troubleshooting. `SKILL.md` is the contract; `usage.md` is the walkthrough.
Both ship to every harness via `install.sh`.

Anti-sprawl controls, all shown at the one run gate rather than chosen silently:

| Flag | Effect |
| --- | --- |
| `--scope <path\|module\|feature>` (or a bare positional) | narrow the run to one module or area; the default (or `.`) is the whole repo. Resolved to an explicit path set and confirmed before scanning |
| `--issue-grouping recommended\|coarse\|strict` | how findings become issues. Default `recommended`; the run gate shows the projected count |
| `--pr-grouping recommended\|strict\|coarse` | how issues become PRs. A separate knob — `coarse` on both double-folds |
| `--grouping <level>` | shorthand that sets both grouping knobs to the same level |
| `--max-layers N` | cap layers per stack (default 5). Overlap past the cap stays one stack |
| `--stacks auto\|by-module\|by-priority\|N` | how the batch is split. Stacks share no files; `auto` makes one stack per group of issues that share files, so an unrelated blocker never holds another fix |
| `--max N` | cap issues filed / fixed (counts issues after clustering, never cuts a cluster in half) |
| `--priority high\|medium\|low` | lowest priority to file and fix (default `low`) |
| `--include-speculative` | also file `confidence: speculative` findings (off by default) |
| `--merge-method squash\|merge\|rebase` | method for `gh stack merge` / `gh pr merge`; default is the repo's only allowed method, else asked (squash with `--yes`) |
| `--merge-engine auto\|stack\|pr\|git` | how to merge; raw `git` is explicit only and never for a stack |
| `--fix-on-layer` | deprecated no-op — `--depth review` fixes the on-layer findings by default |

## release-version

`/release-version` cuts a release in **any** repo: it derives the bump from history, promotes the
changelog, updates every version manifest and lockfile, commits, tags, and pushes — after showing a
plan you approve. It adapts to Node, Maven, Gradle, Cargo, Python, .NET, Go, PHP, Ruby, Elixir,
Helm, Tauri/Electron, and tag-only projects; `skills/release-version/references/ecosystems.md` is
the per-ecosystem table, `references/usage.md` the walkthrough. `gh` is optional: when installed and
authenticated it resolves the repo and default branch, creates the GitHub Release (`--release`), and
turns a protected-branch release into a PR; without it the skill degrades to plain git.

```sh
./install.sh --only release-version   # ship the skill + /release-version wrapper
```

## pstack

[`skills/pstack/`](skills/pstack/) is poteto's engineering bundle — 54 skills (`poteto-mode`,
`setup-pstack`, `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, the 24 `principle-*`
leaves, …) — ported from the Cursor plugin `cursor/plugins/pstack` v0.15.25 for this machine's
OpenCode/agents harnesses. [`PORTING.md`](skills/pstack/PORTING.md) records the provenance and
every adaptation; `port/refresh.sh` re-syncs from a newer upstream release.

```sh
./install.sh --only pstack           # ship the bundle + /setup-pstack /poteto-mode /poteto-help wrappers
./install.sh --only pstack --check   # drift check for the bundle
```

Per-role model choices are written at runtime by `/setup-pstack` to
`~/.agents/skills/pstack/pstack-models.md` — machine state, never synced or pruned by `install.sh`.

- https://cursor.com/docs/context/skills
- https://vercel.com/blog/introducing-react-best-practices
- https://vercel.com/design/guidelines
- npx npx skills i vercel-labs/agent-skills
- npx skills add better-auth/skills
- curl -fsSL https://ui-skills.com/install | bash
- curl -fsSL https://rams.ai/install | bash
- https://github.com/millionco/react-doctor

## MCP

### Cursor

```json
{
  "mcpServers": {
    "strapi-docs": {
      "type": "http",
      "url": "https://strapi-docs.mcp.kapa.ai",
      "headers": {}
    },
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    },
    "aem-content-readonly":{
      "url": "https://mcp.adobeaemcloud.com/adobe/mcp/content-readonly"
    },
    "aem-content":{
      "url": "https://mcp.adobeaemcloud.com/adobe/mcp/content"
    }
  }
}
```
