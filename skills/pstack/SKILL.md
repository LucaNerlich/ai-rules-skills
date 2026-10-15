---
name: pstack
description: poteto's engineering stack — rigorous, unslopped agent workflows you can parallelize with confidence. Ported from the Cursor plugin (cursor/plugins/pstack). Use for pstack, poteto-mode, setup-pstack, poteto-help, or when the user wants deep-first, verified engineering work in this style.
---

# pstack (ported to OpenCode)

"If you want to go fast, go deep first." This bundle is poteto's (Lauren Tan's) engineering skill set, ported from the Cursor plugin `cursor/plugins` → `pstack` v0.15.25. Everything is plain markdown; the port notes live in [PORTING.md](PORTING.md).

## Using it

1. **Setup once:** `setup-pstack` — writes `pstack-models.md` (per-role model choices for this machine).
2. **Work:** `poteto-mode` at the start of a task — it matches a playbook, opens a todo list, and routes to the other skills (`how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `unslop`, `technical-writing`, the `principle-*` leaves, …).
3. Stuck or unsure which skill fits? `poteto-help`.

Commands: `/setup-pstack`, `/poteto-mode`, `/poteto-help` (wrappers in `~/.config/opencode/command/`).

## Subagent notes for this harness

- Where a skill says `subagent_type: "poteto-agent"` or `"comment-sicko"`, spawn the general subagent and have it read `agents/poteto-agent.md` (or `agents/comment-sicko.md`) first. They are not registered as OpenCode agent types.
- Where a role line names a model (from `pstack-models.md`), pass it as the subagent tool's `model` value, format `provider/model#variant`. Omit `model` for `auto` / `inherit-parent`.
- Cursor-only bits (cloud agents, agent-transcripts, `cursor-team-kit`, `/`-menu custom modes) are listed with their substitutions in [PORTING.md](PORTING.md).
