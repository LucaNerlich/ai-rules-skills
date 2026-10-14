---
name: create-issues
description: "Turn findings from a review, plan, codebase scan, or conversation into well-scoped, evidence-backed GitHub issues with detailed bodies (finding, root cause, reproduction, suggested fix), each labelled priority:high, priority:medium, or priority:low. Groups related findings into one issue per root cause instead of one per site. The middle link between /find-problems (which produces the report) and /fix-issues (which consumes the labels). Use for /create-issues, \"file issues\", \"create tickets from this\", \"turn this report into issues\", or \"log these findings\"."
disable-model-invocation: true
---

# Create Issues

Turn a set of findings into well-scoped GitHub issues, each carrying exactly one priority label. The result is a prioritized backlog that `/fix-issues` consumes, highest priority first. Run the whole chain in one command with `/sweep`.

Practical how-to — sources, the grouping levels, rollups, labels, dedupe behaviour, troubleshooting: [`references/usage.md`](references/usage.md).

## Priority labels (shared contract)

| Label | Use for |
| --- | --- |
| `priority:high` | Broken behaviour, security, data loss, auth/billing/correctness bugs, regressions, anything blocking users or the team now. |
| `priority:medium` | Degraded UX or performance, missing validation, incidents waiting to happen, tech debt that impedes work, small features. |
| `priority:low` | Nits, style, docs, typos, refactors, nice-to-haves. |

`/fix-issues` orders by these exact strings. Do not rename them.

## Arguments

| Arg | Meaning | Default |
| --- | --- | --- |
| `--scope <path\|module\|feature>` | file only findings inside the scope; stamp it in the body | none (every finding) |
| `--issue-grouping` | `recommended` · `coarse` · `strict` | `recommended` |
| `--include-speculative` | file `confidence: speculative` findings too | off |

## Preconditions

Run and stop with a clear message if any fails:

1. `gh auth status` — authenticated.
2. `gh repo view --json nameWithOwner` — inside a GitHub repo with a remote.
3. Confirm the target repo with the user when the remote is ambiguous (forks, monorepo subdirs).

## 1. Gather findings

Use the source the user named; otherwise infer one:

- the consolidated report from `/find-problems` (the recommended upstream — its per-finding `evidence`, `why it matters`, `suggested fix`, `category`, and `confidence` are the raw material for the detailed body you write in step 5)
- the handoff block from `/review-issues` (PR findings with their `review-issues:<fingerprint>` markers) — so review findings re-enter the backlog and `/fix-issues` picks them up. Map severity to priority there: `blocker`/`major` → `priority:high`, `minor` → `priority:medium`, `nit` → `priority:low`
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

When a scope is given, drop every finding whose locations fall outside it — a scoped run files scoped issues, not repo-wide ones. Do not re-resolve the scope; the caller already did, and if a location sits outside it, say so in the skipped list rather than filing it anyway.

## 2. Dedupe against open and closed issues

Search before drafting — **open and closed**, so a regression of a fixed issue is a deliberate new issue linked to the old one, never a blind duplicate:

```
gh issue list --state all --search "<key terms>" --limit 20 --json number,title,state,labels,url
```

Match on the concept, not the wording.

- An open issue covers it → skip it and name the issue that covers it.
- A closed issue matches → file only when the problem is genuinely back (a regression) and link it (`Regressed in #<old>`). Do not re-file a closed issue that was fixed and has not recurred.

## 3. Cluster related findings

A scan finds the same defect many times over — one missing null-check per handler, one unvalidated field per endpoint, one Ponytail over-engineering pattern per module. Filing one issue per site pollutes the backlog and buries the real problems, so **group before you draft**. This step is where the noise dies.

Cluster findings that share a **root cause**, a **fix**, or a **fix surface**. All three hold for a good cluster:

- **Root cause** — the same mistake repeated, not two coincidentally adjacent bugs.
- **Fix** — a single edit (or one small series of edits) resolves every instance.
- **Fix surface** — the instances live in one module, file, or pattern the reviewer can verify together.

When the source is a `/find-problems` report, its `cluster` key is the first grouping signal: identical keys are the same root cause and belong in one issue. A `/review-issues` handoff carries a `group` key that plays the same role. Trust the key but verify it — split a cluster whose instances need different fixes.

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

### Rollup: the long tail of the same nit

Many low-priority findings of the same kind (a typo pattern, a naming inconsistency, twelve missing docstrings) must **not** become twelve issues. File **one rollup issue** per kind and area, title `<Kind> in <area> (N items)`, with each instance as a checkbox under `### Where`. Rollups are `priority:low` as a whole unless one instance is genuinely higher, in which case that instance gets its own issue and the rest stay in the rollup.

### Confirm the grouping — once, and only if nobody already did

| Level | Result |
| --- | --- |
| `recommended` (default) | one issue per root cause, plus rollups for the long tail |
| `coarse` | fold clusters that share a module/fix surface into one issue with sub-checklists — fewer, larger issues |
| `strict` | one issue per finding instance (only when the user asks) |

This is **issue** grouping (`--issue-grouping`). It does not decide PR grouping; `/fix-issues` asks that separately, and passing `coarse` into both double-folds.

- Invoked from `/sweep` with a level and an approved batch → do not ask. Use what sweep passed.
- Invoked on its own → ask **once**, in the same question as the create go-ahead (step 7). Do not ask here and again there.

Drop every finding with `confidence: speculative` unless the caller passed `--include-speculative` or the user, after seeing the list, asked to file them. List the dropped ones under skipped. A `file:line` is not enough to file a guess.

## 4. Classify

Assign exactly one priority label from the table. When torn, pick the lower one only if the impact is cosmetic; otherwise pick the higher one and say why in the body.

## 5. Verify and expand (read-only)

A one-line report row makes a one-line issue. Before writing the body, **open the cited locations and read the surrounding code** so the issue states the real mechanism, not a restatement of the scan. This is read-only: you are gathering detail for the body, never editing or fixing.

For each cluster, collect:

- the **actual offending code**, quoted (a few lines, not the whole file) — the report's `file:line` is a pointer, prove it
- the **mechanism**: the input, state, or sequence that leads to the wrong outcome, step by step
- the **call path**: who reaches this code (endpoint, job, scheduler, UI action) — an unreachable branch is lower risk than one hit on every request
- the **root cause**: the underlying mistake, and for a cluster why the pattern repeated (missing helper, wrong default, copy-paste)
- the **blast radius**: severity, whether it is live in production, and who is affected
- the **detection**: the exact request, test command, or steps that expose it, or how you confirmed it by reading

If a detail cannot be verified, write what you know and mark it (`unverified` / `confidence: likely|speculative`). **Never invent detail to fill a section** — a short, true body beats a padded one, and padding is the same pollution as too many issues.

## 6. Draft issues

One issue per **cluster** from step 3 (or per single finding that stands alone). Each issue must be independently shippable: a reviewer can verify the whole cluster with one acceptance check. If a cluster spans two unrelated fixes, split it and note the relationship.

Body template — fill every section; mark the optional ones `N/A` only when they truly do not apply:

````markdown
<One-sentence TL;DR: what is broken and where.>

## Finding

### What is wrong
The mechanism, in prose: given <input/state>, <control flow>, the result is <wrong
outcome> because <reason>. For a cluster, describe the pattern once and say how many
sites repeat it.

### Where
- `path/to/file.ext:123` — the offending code, quoted:
  ```<lang>
  <2-5 lines of the actual code>
  ```
- Add every location the cluster covers; a table is fine when there are many.

### Why it matters
Who or what is affected, how badly, and how often. State whether this is live in
production and what the worst observed or plausible consequence is (data loss, 500s,
silent wrong result, security exposure).

### Root cause
The underlying mistake, not the symptom. For a cluster, why the same mistake recurs
(missing shared helper, wrong default, inconsistent contract, copy-paste).

### Reproduction / detection
The exact steps, request, or command that shows the defect — or, if it is only
read-confirmed, say how. Include the observed vs expected result.

### Evidence
- quoted code, command output, stack trace, or report line
- how it was verified (test run, trace, code read)
- `confidence: confirmed | likely | speculative`

## Suggested fix

### Approach
The leanest correct change, in order of preference: delete > shrink > reuse an existing
helper > rewrite. Name the types, functions, and behaviours to change — not file paths
that will drift.

### Sketch
Optional. A short diff-shaped outline or pseudocode of the fix. Direction, not a full
design.

### Alternatives considered
Optional but encouraged. The heavier or tempting fix and why it is not the right one.

### Out of scope
What this issue deliberately does not touch, so the fix-issues pass stays bounded.

## Acceptance criteria
- [ ] Observable check per instance in the cluster — the reviewer runs it once.
- [ ] Test that should exist after the fix (name the case, not just "add tests").

## Rollback / risk
Optional. Risk of the change, migration or compatibility notes, and how to revert.

## Related
Optional. `Related to #123` / `Part of #456` when the issue sits beside a distinct one.

<!-- sweep-run:<id> scope:<resolved-or-repo> cluster:<key> -->
<!-- metadata, keep for /fix-issues: category: <bug|security|refactor|over-engineering|
dead-code|test-gap|perf> · effort: <S|M|L> · confidence: <confirmed|likely> -->
````

Rules for bodies:

- No secrets: strip tokens, keys, credentials, and `.env` values.
- Evidence, not speculation. If you did not verify something, say so and label it.
- Titles under ~80 characters, imperative, and unique — for a cluster name the pattern ("Guard every presign path against empty keys"), not one site.
- Every instance of the cluster appears under `### Where`; do not silently drop members to keep the issue short.
- Detail means the mechanism, the reproduction, and a concrete fix — not longer prose. No filler, no restating the same evidence in three sections, no speculative "could also affect…" chains.
- Aim for a body a cold reader can act on without re-running the scan: roughly 20-40 lines for a single finding, scaling with the number of instances, not with adjectives.

## 7. Show the batch, then create

Present one table — priority, title, evidence, cluster size, collapse (`N findings → M issues`) — and, if this skill was invoked on its own, ask **once** for the grouping level and the go-ahead together. If `/sweep` already approved filing, create without asking. A "just file them" said before the table was shown does not skip the question; an approval after the table does.

Then ensure the labels exist and create the issues:

```
gh label create "priority:high"   --color B60205 --force
gh label create "priority:medium" --color D93F0B --force
gh label create "priority:low"    --color 0E8A16 --force
gh label create "sweep"           --color 1D76DB --force
```

`--force` makes label creation idempotent. If a label cannot be created, do not abort: file with the labels that exist (`priority:*` without `sweep`, or with neither) and report the exact commands a maintainer must run. Never let a missing label cost you the issue. If the caller passed no run id, mint `sweep-YYYYMMDD-HHMM` and print it — every body still gets `<!-- sweep-run:<id> scope:<resolved-or-repo> cluster:<key> -->`, with `scope:repo` when none was given.

Create issues one at a time so each returned URL is captured:

```
gh issue create --title "<title>" --label "priority:<p>,sweep" --body-file - <<'EOF'
<body>
EOF
```

## 8. Report

Print a table of what was created: priority, `#number`, title, URL, cluster size. List what was skipped and why (duplicate → existing issue; merged → the issue that folded it in). Give counts per priority and the raw-findings → issues ratio. This table is the handoff to `/fix-issues`.

## Rules

- Never file an issue without evidence.
- Never duplicate an open issue.
- Cluster before drafting: one issue per root cause, not one per site. Merge repeated findings; split only for a named reason (different root cause, blast radius, or shipping).
- Every instance of a cluster is listed in the issue; grouping never drops a finding.
- Write the mechanism, not the symptom: verify the cited code (read-only), state input → wrong outcome → root cause, and give a concrete `Suggested fix`. A thin body is a bug in this skill.
- Detail is mechanism and reproduction, never filler. Do not pad, repeat evidence, or speculate beyond what you verified.
- Exactly one priority label per issue; a cluster takes its highest member's priority.
- Ask the grouping level once, and only when this skill was invoked on its own. Sweep's answer is final.
- Never file `confidence: speculative` unless the user opted in after seeing it.
- Stamp every body with `<!-- sweep-run:<id> scope:<resolved-or-repo> cluster:<key> -->`. That marker is how a later run resumes this batch, and how `fix-issues` picks a scoped batch.
- Offer a rollup for a long tail of same-kind nits instead of a river of near-identical issues.
- Never touch code, branches, or PRs — this skill only writes issues.
