---
name: session-summary
description: Summarize the current coding session and write structured notes into Obsidian. Use when the user says "summarize session", "write session notes", "session debrief", "log what we did", "write a summary", or asks to document what happened in the session.
---

# Session Summary

Write a structured session debrief note into the user's Obsidian vault.

## Vault Path

Resolve the vault path in this order:
1. Environment variable `OBSIDIAN_VAULT` (e.g. `export OBSIDIAN_VAULT=~/Documents/notizen`)
2. Fallback: `~/Documents/notizen`

Run `echo $OBSIDIAN_VAULT` via Shell to check. If unset, use the fallback path. Verify the resolved path exists before writing.

## Parameters

The user provides:
- **project** (required): folder name under the vault root (e.g. `m10z`, `Adobe`, `GBR`)
- **ticket** (optional): ticket identifier (e.g. `PROJ-1234`), used as filename prefix and tag

If the user hasn't provided the project name, ask for it before proceeding.

## Workflow

### 1. Gather context from the conversation

Review the entire conversation history and extract:
- **Issue title**: concise one-line summary
- **Issue description**: what the problem was, including context, symptoms, error messages
- **Solution**: what was done to resolve it
- **Steps taken**: chronological list of investigation and implementation steps
- **Files changed**: list of files modified with brief descriptions of each change
- **Knowledge gained**: key takeaways, patterns discovered, gotchas encountered
- **Open questions**: anything unresolved or worth revisiting
- **References**: links to docs, PRs, issues, or related resources mentioned

If a **ticket** was provided, also extract:
- **PR summary**: a concise management-level summary suitable for a pull request description (see PR Summary section below)

### 2. Build the file path

```
VAULT = $OBSIDIAN_VAULT or ~/Documents/notizen
DIR   = {VAULT}/sessions/{project}/
```

Filename rules:
- With ticket: `{ticket}_{YYYY-MM-DD}_{title}.md` (e.g. `PROJ-1234_2026-02-18_fix-auth-redirect.md`)
- Without ticket: `{YYYY-MM-DD}_{title}.md` (e.g. `2026-02-18_fix-auth-redirect.md`)

Derive `{title}` from the issue title: lowercase, replace spaces with hyphens, strip special characters, max 50 chars.
Sanitize the project name the same way: lowercase, replace spaces with hyphens, strip special characters.

### 3. Check for an existing session doc

Before writing, check whether a session doc for this session already exists in `{DIR}`:

1. **With ticket:** use Glob to search for `{DIR}/{ticket}_{YYYY-MM-DD}_*.md`. If one or more matches are found, pick the first match — that is the existing session doc.
2. **Without ticket:** use Glob to search for `{DIR}/{YYYY-MM-DD}_*.md`. If one or more matches are found, read each candidate and check the frontmatter `type: session-summary` field to confirm it is a session doc (not some other note). Pick the first confirmed match.

If an existing doc is found:
- **Update it in-place** by overwriting its content with the freshly generated note (using the template below). Preserve the original filename — do NOT rename or create a new file.
- The updated note should incorporate information from both the previous content and the current conversation. Read the existing file first, then merge: keep any steps, files, knowledge, and references from the old note that are still relevant, and append/update with new information from the current session.

If no existing doc is found:
- Create a new file using the filename rules above.
- If the computed filename collides with a non-session file, append `_2`, `_3`, etc. before `.md`.

### 4. Create directories and write the note

Resolve the vault path (see "Vault Path" above), then use `mkdir -p` via Shell to ensure `{VAULT}/sessions/{project}/` exists.

Write (or overwrite) the note using the template below.

## Note Template

```markdown
---
type: session-summary
project: {project}
ticket: {ticket or empty string}
date: {YYYY-MM-DD}
tags: [session, {project}, {ticket if present}]
---

# {Issue Title}

## Issue
{Issue description: context, symptoms, error messages}

## Solution
{High-level description of what was done to resolve it}

## Steps Taken
1. {Step-by-step chronology of what was investigated and changed}

## Files Changed
- `{path/to/file}` -- {brief description of change}

## Knowledge Gained
- {Key takeaways, patterns discovered, gotchas encountered}

## Open Questions / Follow-ups
- [ ] {Anything remaining or worth revisiting}

## References
- {Links to docs, PRs, issues, or related Obsidian notes using [[wikilinks]]}
```

## PR Summary

When a **ticket** is provided, append a `## PR Summary` section to the note **after References**. This block is designed to be copied directly into a pull request description.

Write it from the perspective of someone presenting the change to reviewers and stakeholders -- focus on *what* and *why*, not the investigation journey. Keep it concise; reviewers should be able to understand the change in under 30 seconds.

```markdown
## PR Summary

> **{ticket}: {Issue Title}**
>
> ### What changed
> - {1-4 bullet points: what was modified and why, at a level a reviewer or PM can follow}
>
> ### How it was tested
> - {Build/compile results, test suite results, manual verification -- whatever actually happened in the session}
>
> ### Notes for reviewers
> - {Optional: anything reviewers should pay attention to, edge cases, related follow-ups, or "None."}
```

If no ticket was provided, omit the entire PR Summary section.

## Rules

- Derive ALL content from the current conversation. Do not fabricate steps or changes that didn't happen.
- If a section has no content (e.g. no open questions), write "None." instead of leaving it empty.
- Use Obsidian `[[wikilinks]]` when referencing other notes in the vault.
- Keep the issue title short (under 80 characters).
- The PR Summary must be self-contained -- someone reading only that block should understand the change without reading the rest of the note.
- After writing, confirm the full file path to the user and indicate whether the file was **created** or **updated**. If a PR Summary was generated, also print it separately so the user can copy it.
- When updating an existing doc, do not discard prior content blindly. Merge old and new information so the note reflects the full history of work on that session/ticket for the day.
