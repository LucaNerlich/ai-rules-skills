# pstack port notes (OpenCode / ~/.agents)

## Provenance

- Upstream: <https://github.com/cursor/plugins> → `pstack` plugin, `poteto-mode` and friends by Lauren Tan (poteto).
- Version ported: **0.15.25**
- Source on this machine: `~/.cursor/plugins/cache/cursor-public/pstack/850d7f2e9f5e55dff7eb00a0a479337fe79eb22f`
- Ported: 2026-10-15; the canonical copy now lives in this repo (`skills/pstack/`) and is installed to the harnesses with `./install.sh --only pstack` (which never touches `pstack-models.md`). The OpenCode session loads `~/.agents/skills/pstack/`.

## What's here

- `*/SKILL.md` — the 54 skills (`poteto-mode`, `setup-pstack`, `poteto-help`, `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `reflect`, `unslop`, `technical-writing`, `no-comments`, `tdd`, `show-me-your-work`, the 24 `principle-*` leaves, …), with their `playbooks/`, `references/`, `scripts/` as shipped.
- `docs/guide/` — upstream user guide.
- `agents/` — `poteto-agent.md`, `comment-sicko.md` subagent definitions.
- `README.md`, `LICENSE`, `plugin.json` — upstream metadata.
- `SKILL.md` — root entry point (added by this port).
- `port/refresh.sh` — re-sync this bundle from a newer upstream copy.

## Adaptations applied (diff vs upstream — keep small)

Mechanical replacements across all ported `.md` files:

| Upstream | Ported |
|---|---|
| `~/.cursor/rules/pstack-models.mdc` | `~/.agents/skills/pstack/pstack-models.md` |
| bare `pstack-models.mdc` mentions | `pstack-models.md` |
| `~/.cursor/skills`, `.cursor/skills` (skill authoring paths, e.g. verify-* / *-mode) | `~/.agents/skills`, `.agents/skills` |
| `Task tool` | `subagent tool` (OpenCode's equivalent) |
| `AskQuestion` | `question tool` |

Plus: each skill's frontmatter `name:` is normalized to its directory name (`poteto-mode`, `make-bot-ui` had display-case names upstream).

## Cursor-isms that remain, and their substitutes

- `subagent_type: "poteto-agent"` / `"comment-sicko"` — not registered OpenCode agent types. Spawn the general subagent and have it read `agents/poteto-agent.md` / `agents/comment-sicko.md` first.
- Model slugs — written per machine by `setup-pstack` into `pstack-models.md` as `provider/model#variant`; `auto` / `inherit-parent` mean "omit the subagent `model`".
- Cursor modes (`/poteto-mode` kept on via option+enter as a "custom mode") — no equivalent; keep the skill attached per message or per session instead.
- `environment: "cloud"` / Cursor cloud agents / `~/.cursor/projects/*/agent-transcripts` — run local instead; transcripts are not available to `recall` / `show-me-your-work` / `reflect` here.
- `cursor-team-kit` (`deslop`, `control-cli`, `control-ui`) — not installed. `/no-comments` (part of this bundle) works; for the others substitute an available skill or a named driver.
- `/create-verification-skill` and `maintain-verification-skill` write `verify-*` skills into the project — already adapted to `.agents/skills/`. Their `enable-model.sh`-style helpers and `recall` transcript paths assume Cursor; treat as best-effort.

## Re-syncing after a pstack update

This repo is the source of truth; installed copies are synced from it. When the Cursor plugin
updates (or from a fresh clone of `cursor/plugins`):

```sh
# refresh the repo copy in place…
skills/pstack/port/refresh.sh ~/.cursor/plugins/cache/cursor-public/pstack/<new-hash>
# …then fan the bundle out to every harness
./install.sh --only pstack
```

The script wipes+recopies the skill dirs, re-applies the replacements above, normalizes names, and fails if any `*.mdc` reference survived. Then bump the version line in this file.

## Uninstall

```sh
rm -rf ~/.agents/skills/pstack
rm -f ~/.config/opencode/command/{setup-pstack,poteto-mode,poteto-help}.md
```
