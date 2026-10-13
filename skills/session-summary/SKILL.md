---
name: session-summary
description: "Write a structured session debrief into Obsidian and print a ready-to-paste ticket comment (and PR summary when relevant). Use for /session-summary, \"summarize session\", \"session debrief\", \"log what we did\", or \"write session notes\". Not for in-chat catch-up (/ketchup) or rebuilding working context (/recall)."
disable-model-invocation: true
---

# Session Summary

Write one durable session debrief note, then print the blocks the user pastes into a ticket and (when relevant) a PR.

## Not this skill

- In-chat catch-up since the user's last message → `/ketchup`
- Rebuild working context before resuming work → `/recall`
- Append-only decision TSV for long unattended runs → `/show-me-your-work`

## Parameters

- **project** (required): vault folder under `sessions/` (e.g. `m10z`, `pnn-it`, `GBR`). Infer from the repo name or path when obvious; otherwise ask once.
- **ticket** (optional): id used in the filename, tags, and ticket-comment header (e.g. `PROJ-1234`)

## Vault path

Resolve in order; stop at the first path that exists as a directory:

1. `$OBSIDIAN_VAULT` (run `echo $OBSIDIAN_VAULT` via Shell)
2. `~/Documents/notizen`

If neither exists (common on Cloud Agents): write under `/opt/cursor/artifacts/sessions/{project}/` instead, say the Obsidian vault was unavailable, and still print the full note plus the ticket/PR blocks so the user can paste into Obsidian locally.

## Workflow

### 1. Gather evidence (read-only)

Pull from every source that applies. Do not invent steps, files, or outcomes.

1. **This chat.** Decisions, errors, fixes, open questions, links.
2. **Live git** (when the workspace is a repo): current branch, `git log` / `git diff` against the base branch, commit subjects, touched paths. Prefer `git` over memory for **Files Changed**.
3. **PR / issue links** when `gh` or an existing PR URL is available.
4. **Cloud Agent runs** when the `cursor-cloud` tools exist: follow `references/cloud-sources.md`. Fold sibling/child agent work into Steps, Files, References, and the new **Agents** section. Mine long transcripts with subagents; keep only the reduced timeline in this thread.

Strip secrets before any write: API keys, tokens, passwords, private URLs with embedded credentials, raw `.env` values, session cookies.

### 2. Extract fields

From the evidence, fill:

| Field | Notes |
| --- | --- |
| Context | System/feature, expected behaviour, why — for a cold reader |
| Issue title | One line, under 80 chars |
| Issue | Symptoms; quote errors/logs when useful |
| Reproduction | Bug/debug sessions only; include environment |
| Solution | What resolved it |
| Decision log | Alternatives considered/rejected/chosen — omit section body with `None.` if none |
| Steps taken | Chronological investigation + implementation |
| Files changed | Path + brief change; verify against `git` when possible |
| Agents | Cloud run names, `bcId`s, URLs, branches, PR links — omit section if none |
| Knowledge gained | Each bullet needs a concrete artifact (path, symbol, error, config key, version, quote) |
| Open questions | Unresolved follow-ups |
| References | Docs, PRs, issues, `[[wikilinks]]` |
| Ticket comment | Always — see template |
| PR summary | When a **ticket** was given **or** this branch has/created a PR |

### 3. Build the file path

```
VAULT = first existing vault path, else /opt/cursor/artifacts
DIR   = {VAULT}/sessions/{project}/
```

Sanitize `{project}` and `{title}`: lowercase, spaces → hyphens, strip special chars; title max 50 chars from the issue title.

- With ticket: `{ticket}_{YYYY-MM-DD}_{title}.md`
- Without: `{YYYY-MM-DD}_{title}.md`

### 4. Update or create

Before writing, look for an existing session doc in `{DIR}`:

1. **With ticket:** Glob `{DIR}/{ticket}_{YYYY-MM-DD}_*.md` — use the first match.
2. **Without ticket:** Glob `{DIR}/{YYYY-MM-DD}_*.md`, read candidates, keep the first with frontmatter `type: session-summary`.

**Existing doc:** overwrite in place; keep the filename. Read first and merge: retain still-relevant steps, files, knowledge, decisions, agents, and references; append new facts from this run. If the solution changed materially, add a one-line note at the top of **Steps Taken** (do not set `status: superseded` on the file you are updating).

**New doc:** create with the filename rules. On collision with a non-session file, append `_2`, `_3`, … before `.md`.

Only set `status: superseded` and `superseded_by:` when a **new** note replaces an **older** note that should stay on disk (different ticket or day owns the work now). Leave the old file in place with those fields; do not delete it.

### 5. Write and print

`mkdir -p` the directory, write the note from the template below, then print:

1. Confirmation: full path + **created** or **updated** (+ **vault fallback** when not Obsidian)
2. Ticket Comment block (always)
3. PR Summary block (when generated)

---

## Note template

```markdown
---
type: session-summary
project: {project}
ticket: {ticket or empty}
date: {YYYY-MM-DD}
status: active
superseded_by:
tags: [session, {project}, {ticket if present}]
---

# {Issue Title}

## Context
{2-3 sentences for a cold reader}

## Issue
{Symptoms, errors verbatim when useful, affected behaviour}

## Reproduction
{Bug/debug only. Exact steps.}

**Environment at the time:** {versions, config, data state, or N/A}

## Solution
{What resolved it}

## Decision Log
- **Considered:** {approach}
  **Rejected because:** {constraint, risk, or evidence}
- **Chose:** {approach}
  **Because:** {reason}

## Steps Taken
1. {Chronology}

## Files Changed
- `{path}` — {brief change}

## Agents
- [{name}]({url}) (`{bcId}`) — {branch, PR, one-line outcome}

## Knowledge Gained
- {Each bullet includes a concrete artifact}

## Open Questions / Follow-ups
- [ ] {Item}

## References
- {URLs, PR/issue links, [[wikilinks]]}
```

Omit the **Reproduction** heading when this was not a bug/debug session. Omit **Agents** when there are no cloud runs to cite. For any other empty section, write `None.`

---

## Ticket comment

Always generate. Past tense. Under 150 words. Every sentence names a concrete artifact.

```markdown
## Ticket Comment (copy into Jira/Linear/GitHub)

---
**Root cause:** {specific cause}
**Fix:** {file, function, or config that changed, and why}
**Why it wasn't caught earlier:** {test gap / missing guard / bad assumption — or omit}
**Regression risk:** {related areas, or None identified}
**Decision note:** {key tradeoff — or omit}
---
```

---

## PR summary

When a ticket was provided **or** a PR exists for this work, append after **References**, and print separately after the Ticket Comment.

```markdown
## PR Summary

> **{ticket or branch}: {Issue Title}**
>
> ### What changed
> - {1-4 bullets a reviewer or PM can follow}
>
> ### How it was tested
> - {What actually ran in the session}
>
> ### Notes for reviewers
> - {Risks, edge cases, follow-ups, or None.}
```

---

## Rules

- Derive content only from gathered evidence. No fabricated steps or files.
- Knowledge Gained bullets without a concrete artifact are deleted, not softened.
- Ticket Comment and PR Summary must each stand alone.
- Prefer `git` paths and PR URLs over recollections when they disagree.
- After writing, state the path and created/updated (and vault fallback if used).
