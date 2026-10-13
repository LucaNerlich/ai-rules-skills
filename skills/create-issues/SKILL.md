---
name: create-issues
description: "Turn findings from a review, plan, codebase scan, or conversation into well-scoped GitHub issues, each labelled priority:high, priority:medium, or priority:low. The middle link between /find-problems (which produces the report) and /fix-issues (which consumes the labels). Use for /create-issues, \"file issues\", \"create tickets from this\", \"turn this report into issues\", or \"log these findings\"."
disable-model-invocation: true
---

# Create Issues

Turn a set of findings into well-scoped GitHub issues, each carrying exactly one priority label. The result is a prioritized backlog that `/fix-issues` consumes, highest priority first.

## Priority labels (shared contract)

| Label | Use for |
| --- | --- |
| `priority:high` | Broken behaviour, security, data loss, auth/billing/correctness bugs, regressions, anything blocking users or the team now. |
| `priority:medium` | Degraded UX or performance, missing validation, incidents waiting to happen, tech debt that impedes work, small features. |
| `priority:low` | Nits, style, docs, typos, refactors, nice-to-haves. |

`/fix-issues` orders by these exact strings. Do not rename them.

## Preconditions

Run and stop with a clear message if any fails:

1. `gh auth status` — authenticated.
2. `gh repo view --json nameWithOwner` — inside a GitHub repo with a remote.
3. Confirm the target repo with the user when the remote is ambiguous (forks, monorepo subdirs).

## 1. Gather findings

Use the source the user named; otherwise infer one:

- the consolidated report from `/find-problems` (the recommended upstream — it already carries evidence, category, and a suggested priority per finding)
- a review report, plan file, or PR/issue URL they pasted
- a codebase scan (below)
- findings already present in this conversation

When scanning, only keep concrete, evidenced work — never invent issues:

- `TODO` / `FIXME` / `HACK` / `XXX` comments
- failing or skipped tests (`@Disabled`, `it.skip`, `xit`, `t.Skip`)
- build, lint, or type errors from the repo's own command
- security smells: missing authorization, unvalidated input, secrets, wildcard CORS, disabled TLS checks
- dead code, unused dependencies, deprecated patterns

Every candidate needs evidence: a `file:line` reference, a command output, or a quoted report line. Drop anything you cannot point at.

## 2. Dedupe against open issues

Search before drafting:

```
gh issue list --state open --search "<key terms>" --limit 20 --json number,title,labels,url
```

Match on the concept, not the wording. If an open issue already covers a candidate, skip it and name the issue that covers it. Never file a duplicate.

## 3. Classify

Assign exactly one priority label from the table. When torn, pick the lower one only if the impact is cosmetic; otherwise pick the higher one and say why in the body.

## 4. Draft issues

One issue per discrete, independently shippable problem. Do not bundle unrelated fixes. If a finding needs two fixes, file two issues and note the relationship.

Body template:

```markdown
## Context
What this is and why it matters, for a cold reader.

## Evidence
- `path/to/file.ext:123` — what is wrong there
- command output or report quote when relevant

## Impact
Who or what is affected, and how badly.

## Acceptance criteria
- [ ] Observable check that proves this is done.
- [ ] Test that should exist after the fix.

## Suggested approach
Optional. Direction, not a full design. Name types and behaviours, not file paths that will drift.
```

Rules for bodies:

- No secrets: strip tokens, keys, credentials, and `.env` values.
- Evidence, not speculation. If you did not verify something, say so.
- Titles under ~80 characters, imperative ("Guard presign against empty key"), and unique.

## 5. Show the batch, then create

Present a table first — priority, title, evidence — and get the user's go-ahead unless they already said "create them" / "just file them". Then ensure the labels exist and create the issues:

```
gh label create "priority:high"   --color B60205 --force
gh label create "priority:medium" --color D93F0B --force
gh label create "priority:low"    --color 0E8A16 --force
```

`--force` makes label creation idempotent. Create issues one at a time so each returned URL is captured:

```
gh issue create --title "<title>" --label "priority:<p>" --body-file - <<'EOF'
<body>
EOF
```

## 6. Report

Print a table of what was created: priority, `#number`, title, URL. List what was skipped and why (duplicate → existing issue). Give counts per priority. This table is the handoff to `/fix-issues`.

## Rules

- Never file an issue without evidence.
- Never duplicate an open issue.
- Exactly one priority label per issue.
- Never touch code, branches, or PRs — this skill only writes issues.
