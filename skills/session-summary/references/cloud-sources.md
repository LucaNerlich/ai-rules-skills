# Cloud Agent evidence for session summaries

Use only when `cursor-cloud` (or equivalent) tools are available in this run. Skip silently on local-only chats.

## Flow

1. `run-info` — current `bcId`, URL, branch, repo, status.
2. `get-events` — setup, PR, artifact, and MCP auth outcomes for this run.
3. `list-cloud-agents` — related runs in the same environment (or same repo when no environment is attached). Prefer filters: recent `createdAfter`, `didMakeCodeChanges`, exclude unrelated `internal` miners unless they belong to this work.
4. `batch-fetch-details` — for the current run plus related runs that touched the same ticket/feature:
   - `includeDiffMetadata: true`
   - `includeEvents: true` when dashboard events matter
   - `includeTranscripts: true` only for runs whose work must enter the note
5. Spawn one subagent per large `transcript.json`. Each returns: goal, decisions, files touched, PR/branch, open threads, concrete errors. Do not load full transcripts into the main thread.

## What to copy into the note

- Agent display name, URL, `bcId`
- Branch and PR link from diff metadata when present
- One-line outcome (merged, draft PR, blocked, idle)
- Steps/files/knowledge that the subagent verified against the transcript — not the subagent's speculation

## Limits

- Max 50 `bcId`s per `batch-fetch-details` call; page `list-cloud-agents` when needed.
- Treat setup-log and environment fetches as optional; include them only when the session was about environment/setup failure.
- Never paste secrets from transcripts into the Obsidian note.
