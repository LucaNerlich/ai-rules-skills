---
name: session-summary
description: Summarize the current coding session and write structured notes into Obsidian. Use when the user says "summarize session", "write session notes", "session debrief", "log what we did", "write a summary", or asks to document what happened in the session.
---

# Session Summary

Write a structured session debrief note into the user's Obsidian vault, and print a ready-to-paste ticket comment.

## Vault Path

Resolve the vault path in this order:
1. Environment variable `OBSIDIAN_VAULT` (e.g. `export OBSIDIAN_VAULT=~/Documents/notizen`)
2. Fallback: `~/Documents/notizen`

Run `echo $OBSIDIAN_VAULT` via Shell to check. If unset, use the fallback path. Verify the resolved path exists before writing.

## Parameters

The user provides:
- **project** (required): folder name under the vault root (e.g. `m10z`, `Adobe`, `GBR`)
- **ticket** (optional): ticket identifier (e.g. `PROJ-1234`), used as filename prefix, tag, and ticket comment header

If the user hasn't provided the project name, ask for it before proceeding.

## Workflow

### 1. Gather context from the conversation

Review the entire conversation history and extract:

- **Context**: what system/feature this touches, what the expected behaviour was, why this was being worked on — written for someone with no prior knowledge
- **Issue title**: concise one-line summary
- **Issue description**: what the problem was, including symptoms and any error messages or log output (verbatim where relevant)
- **Reproduction steps**: exact steps to reproduce, plus environment details (versions, config, data state) — include only if this was a debugging/bug-fix session
- **Solution**: what was done to resolve it
- **Decision log**: what alternative approaches were considered, why each was rejected, and why the chosen approach was selected — omit if no meaningful decisions were made
- **Steps taken**: chronological list of investigation and implementation steps
- **Files changed**: list of files modified with brief descriptions of each change
- **Knowledge gained**: key takeaways, patterns discovered, gotchas — each item must contain at least one specific artifact (file path, function name, error message, config key, version number, or direct quote)
- **Open questions**: anything unresolved or worth revisiting
- **References**: links to docs, PRs, issues, or related resources mentioned

Always extract:
- **Ticket comment**: a compact, past-tense block designed to be pasted directly into Jira/Linear/GitHub Issues (see Ticket Comment section below)

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
- Read the existing file first and merge: keep steps, files, knowledge, decisions, and references from the old note that are still relevant, and append/update with new information from the current session.
- If the solution changed significantly from what the old note described, set `status: superseded` on the old content and note the change at the top of the Steps Taken section.

If no existing doc is found:
- Create a new file using the filename rules above.
- If the computed filename collides with a non-session file, append `_2`, `_3`, etc. before `.md`.

### 4. Create directories and write the note

Resolve the vault path (see "Vault Path" above), then use `mkdir -p` via Shell to ensure `{VAULT}/sessions/{project}/` exists.

Write (or overwrite) the note using the template below.

### 5. Print the Ticket Comment

After writing the file, print the Ticket Comment block to the console so the user can copy it directly — no further action required from the user.

---

## Note Template

```markdown
---
type: session-summary
project: {project}
ticket: {ticket or empty string}
date: {YYYY-MM-DD}
status: active
superseded_by:
tags: [session, {project}, {ticket if present}]
---

# {Issue Title}

## Context
{2-3 sentences: what system/feature this touches, what the expected behaviour was, and why this was being worked on — written for a cold reader with no prior knowledge of this session}

## Issue
{What the problem was: symptoms, error messages (verbatim where useful), affected behaviour}

## Reproduction
{Only include for bug/debugging sessions. Exact steps to reproduce.}

**Environment at the time:** {versions, config flags, data state, or "N/A"}

## Solution
{High-level description of what was done to resolve it}

## Decision Log
- **Considered:** {alternative approach}
  **Rejected because:** {specific reason — constraint, risk, evidence}
- **Chose:** {approach taken}
  **Because:** {specific reason}

## Steps Taken
1. {Step-by-step chronology of what was investigated and changed}

## Files Changed
- `{path/to/file}` — {brief description of change}

## Knowledge Gained
- {Key takeaways, patterns discovered, gotchas. Every bullet must contain at least one specific artifact: file path, function name, error message, config key, version number, or direct quote.}

## Open Questions / Follow-ups
- [ ] {Anything remaining or worth revisiting}

## References
- {Links to docs, PRs, issues, or related Obsidian notes using [[wikilinks]]}
```

---

## Ticket Comment

Always generate this block, with or without a ticket. It is designed to be pasted directly into a Jira/Linear/GitHub issue comment by someone who was not present in the session.

Write it in past tense. Keep it under 150 words. Do not repeat the solution in generic terms — every sentence must contain a specific artifact (function name, file, error, config key, version, or decision).

```markdown
## Ticket Comment (copy into Jira/Linear/GitHub)

---
**Root cause:** {one specific sentence — name the actual cause, not "a bug was found"}
**Fix:** {one specific sentence — name the file, function, or config that changed and why}
**Why it wasn't caught earlier:** {if applicable — test gap, missing guard, assumption that was wrong}
**Regression risk:** {what related areas could be affected, or "None identified"}
**Decision note:** {one sentence on the key tradeoff made, if any — omit if no meaningful decision}
---
```

---

## PR Summary

When a **ticket** is provided, append a `## PR Summary` section to the note **after References**. This block is designed to be copied directly into a pull request description.

Write it from the perspective of someone presenting the change to reviewers and stakeholders — focus on *what* and *why*, not the investigation journey. Keep it concise; reviewers should be able to understand the change in under 30 seconds.

```markdown
## PR Summary

> **{ticket}: {Issue Title}**
>
> ### What changed
> - {1-4 bullet points: what was modified and why, at a level a reviewer or PM can follow}
>
> ### How it was tested
> - {Build/compile results, test suite results, manual verification — whatever actually happened in the session}
>
> ### Notes for reviewers
> - {Anything reviewers should pay attention to, edge cases, related follow-ups, or "None."}
```

If no ticket was provided, omit the entire PR Summary section.

---

## Rules

- Derive ALL content from the current conversation. Do not fabricate steps or changes that didn't happen.
- Every bullet point in Knowledge Gained must contain at least one specific artifact: a file path, error message, function name, config key, version number, or direct quote from the conversation. Generic observations ("the code was complex", "debugging took time") must be omitted.
- If a section has no content (e.g. no open questions, no decisions made), write "None." instead of leaving it empty. Omit the Reproduction section entirely if this was not a debugging session.
- Use Obsidian `[[wikilinks]]` when referencing other notes in the vault.
- Keep the issue title short (under 80 characters).
- The Ticket Comment must be self-contained — someone reading only that block should understand the root cause and fix without reading the rest of the note.
- The PR Summary must be self-contained — someone reading only that block should understand the change without reading the rest of the note.
- After writing, confirm the full file path and whether the file was **created** or **updated**.
- Print the Ticket Comment block separately at the end so the user can copy it without opening the file.
- If a PR Summary was generated, also print it separately after the Ticket Comment.
- When updating an existing doc, do not discard prior content blindly. Merge old and new information so the note reflects the full history of work on that session/ticket for the day.
- If the solution described in an existing note was significantly revised during the current session, note this explicitly at the top of Steps Taken and consider setting `status: superseded` and `superseded_by:` if a new ticket now owns the work.
