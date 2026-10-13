---
name: create-issues
description: "Turn findings from a review, plan, codebase scan, or conversation into well-scoped GitHub issues, each labelled priority:high, priority:medium, or priority:low. The middle link between /find-problems (which produces the report) and /fix-issues (which consumes the labels). Use for /create-issues, \"file issues\", \"create tickets from this\", \"turn this report into issues\", or \"log these findings\"."
disable-model-invocation: true
---

# Create Issues

Turn a set of findings into well-scoped GitHub issues, each carrying exactly one priority label. The result is a prioritized backlog that `/fix-issues` consumes, highest priority first. Run the whole chain in one command with `/sweep`.

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

## 3. Cluster related findings

A scan finds the same defect many times over — one missing null-check per handler, one unvalidated field per endpoint, one Ponytail over-engineering pattern per module. Filing one issue per site pollutes the backlog and buries the real problems, so **group before you draft**. This step is where the noise dies.

Cluster findings that share a **root cause**, a **fix**, or a **fix surface**. All three hold for a good cluster:

- **Root cause** — the same mistake repeated, not two coincidentally adjacent bugs.
- **Fix** — a single edit (or one small series of edits) resolves every instance.
- **Fix surface** — the instances live in one module, file, or pattern the reviewer can verify together.

One cluster → one issue. The issue names the *pattern* as its title and lists every instance as evidence, so nothing is lost.

Merge when instances share the fix:

- the same defect repeated across sites (N handlers with the same unchecked input, N endpoints with the same missing authorization, N ad-hoc string builders replacing one helper)
- one root cause with several symptoms (a wrong state transition that surfaces in three call sites)
- a family of nits of the same kind (the same typo pattern, the same deprecated API called throughout)

Keep separate when anything differs:

- **different root causes** — two bugs that merely sit near each other
- **different blast radius or severity** — a crash and a cosmetic nit do not share a ticket
- **independent shipping** — if one can land and be verified without the other, they are two issues
- **unrelated fixes** — never bundle to hit a quota

Size guide: a cluster is well-formed when its instances share one acceptance check a reviewer can run once. If the instances need *different* verification, split. If two findings would pass the *same* check, merge them. Default to merging; split only for a reason named above.

Priority of a cluster = the **highest** priority among its members — one `high` instance lifts the whole issue, so it is never buried by its `low` siblings. Say so in the body when the mix is wide.

Related-but-distinct issues stay distinct and reference each other in the body (`Related to #123` / `Part of #123` for a cluster of clusters). Cross-reference, never duplicate.

## 4. Classify

Assign exactly one priority label from the table. When torn, pick the lower one only if the impact is cosmetic; otherwise pick the higher one and say why in the body.

## 5. Draft issues

One issue per **cluster** from step 3 (or per single finding that stands alone). Each issue must be independently shippable: a reviewer can verify the whole cluster with one acceptance check. If a cluster spans two unrelated fixes, split it and note the relationship.

Body template:

```markdown
## Context
What this is and why it matters, for a cold reader. For a cluster, name the pattern
and how many sites it spans.

## Evidence
- `path/to/file.ext:123` — what is wrong there
- command output or report quote when relevant

## Instances
Checklist of every site the cluster covers — one line per instance, so nothing is lost:
- [ ] `path/to/file.ext:123` — <what is wrong here>
- [ ] `path/to/other.ext:45` — <same pattern>

## Impact
Who or what is affected, and how badly. Call out the worst instance and the priority mix.

## Acceptance criteria
- [ ] Observable check that proves this is done.
- [ ] Test that should exist after the fix.

## Related
Optional. `Related to #123` / `Part of #456` when the issue sits beside a distinct one.

## Suggested approach
Optional. The one fix that covers every instance — direction, not a full design. Name
types and behaviours, not file paths that will drift.
```

Rules for bodies:

- No secrets: strip tokens, keys, credentials, and `.env` values.
- Evidence, not speculation. If you did not verify something, say so.
- Titles under ~80 characters, imperative, and unique — for a cluster name the pattern ("Guard every presign path against empty keys"), not one site.
- Every instance of the cluster appears in `## Instances`; do not silently drop members to keep the issue short.

## 6. Show the batch, then create

Present a table first — priority, title, evidence, **findings folded in (cluster size)** — and get the user's go-ahead unless they already said "create them" / "just file them". State the collapse: "N findings → M issues". Then ensure the labels exist and create the issues:

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

## 7. Report

Print a table of what was created: priority, `#number`, title, URL, cluster size. List what was skipped and why (duplicate → existing issue; merged → the issue that folded it in). Give counts per priority and the raw-findings → issues ratio. This table is the handoff to `/fix-issues`.

## Rules

- Never file an issue without evidence.
- Never duplicate an open issue.
- Cluster before drafting: one issue per root cause, not one per site. Merge repeated findings; split only for a named reason (different root cause, blast radius, or shipping).
- Every instance of a cluster is listed in the issue; grouping never drops a finding.
- Exactly one priority label per issue; a cluster takes its highest member's priority.
- Never touch code, branches, or PRs — this skill only writes issues.
