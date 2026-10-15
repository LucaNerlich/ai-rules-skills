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

One command runs the whole cycle. A review finding in the fix goes back onto that layer; only a new bug becomes another issue:

```
/sweep
  ├─ find-problems   → findings report                              (read-only)
  ├─ create-issues   → priority:high|medium|low issues                     [gate]
  ├─ fix-issues      → file-disjoint stacked PR chains (gh-stack)          [gate]
  ├─ review-issues   → PR review comments + agent instructions             [gate]
  ├─ on-layer finding → commit on that layer, never a new stack
  └─ out-of-scope finding → create-issues → next /fix-issues pass
```

Each phase is also a skill (and a `/command`) of its own; `/sweep --depth report|file|fix|review`
stops where you want. The skills live in [`skills/`](skills/), the slash-command wrappers in
[`commands/`](commands/).

Every skill has a practical guide next to it — `skills/<name>/references/usage.md` — with recipes,
worked examples, and troubleshooting. `SKILL.md` is the contract; `usage.md` is the walkthrough.
Both ship to every harness via `install.sh`.

Anti-sprawl controls, all confirmed with you at their gate rather than chosen silently:

| Flag | Effect |
| --- | --- |
| `--scope <path\|module\|feature>` (or a bare positional) | narrow the run to one module or area; the default is the whole repo. Resolved to an explicit path set and confirmed before scanning |
| `--issue-grouping recommended\|coarse\|strict` | how findings become issues. Asked once, at the file gate |
| `--pr-grouping recommended\|strict\|coarse` | how issues become PRs. A separate knob — `coarse` on both double-folds |
| `--max-layers N` | cap layers per stack (default 5). Overlap past the cap stays one stack |
| `--stacks auto\|by-module\|by-priority\|N` | how a long batch is split. Stacks share no files |
| `--max N` | cap issues filed / fixed (counts issues, never cuts a cluster in half) |
| `--include-speculative` | also file `confidence: speculative` findings (off by default) |
| `--fix-on-layer` | commit review fixes onto the open layer instead of leaving the comment |

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
