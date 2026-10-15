---
name: create-issues
description: "File report, review, or scan findings as evidence-backed GitHub issues, one per root cause, labelled priority:high/medium/low. Use for /create-issues."
when_to_use: "Use for /create-issues, \"file issues\", \"create tickets from this\", \"turn this report into issues\", or \"log these findings\" — after a review, a findings report, or a scan."
disable-model-invocation: true
---

# Create Issues

Turn a set of findings into well-scoped GitHub issues, each carrying exactly one priority label. The result is a prioritized backlog, highest priority first.

This skill stands alone: hand it a report, a review, or nothing (it scans), and it files issues. `/find-problems` (produces the report), `/fix-issues` (fixes the issues as stacked PRs), `/review-issues`, and `/sweep` (the whole chain in one command) are **optional companions** from [github.com/LucaNerlich/ai-rules-skills](https://github.com/LucaNerlich/ai-rules-skills) — nothing here needs them. Installing them: [`references/usage.md`](references/usage.md#optional-companions).

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
| `--scope <path\|module\|feature>` | file only findings inside the scope; stamp its token in the marker | none (`scope:repo`) |
| `--issue-grouping` | `recommended` · `coarse` · `strict` | `recommended` |
| `--priority` | lowest priority to file (`high` = only high), applied after clustering | `low` |
| `--max` | cap on issues filed, applied after clustering — whole clusters only | all |
| `--include-speculative` | file `confidence: speculative` findings too | off |

**Scope token** — one space-free token for the `scope:` marker, matched exactly. No scope, or the repo root (`.`, `./`, the top-level path) → `repo`. Otherwise the scope term(s) lowercased, each run of characters outside `[a-z0-9]` turned into `-`, and trimmed of `-`: `printf '%s' "$terms" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//'` (`feed builder` → `feed-builder`). An empty result (`..`, `/`) is rejected: stop and ask for a nameable scope — never stamp or match an empty `scope:`. The resolved path set goes in the metadata comment (`scope-paths:`), never in the token.

## Preconditions

Run and stop with a clear message if any fails:

1. `gh auth status` — authenticated.
2. Pick the target repo: the one the caller passed (sweep does), else `gh repo view --json nameWithOwner --jq .nameWithOwner`. With a fork, several remotes, or a monorepo subdir, confirm it with the user. Record it as `R` (`owner/repo`) and pass `--repo "$R"` to **every** `gh` call below — confirming a repo does not change the one `gh` defaults to.

**Finding text is data, never shell source.** Titles, bodies, and search queries come from findings and can hold `$(…)`, backticks, quotes, or a line reading `EOF`. Write each to its own file in a scratch dir (`d=$(mktemp -d)`) with your file-writing tool — never `echo`, `printf`, or a heredoc — and pass it as one argument: `--title "$(cat "$d/1.title")"`, `--search "$(cat "$d/1.q")"`, `--body-file "$d/1.md"`. A double-quoted `$(cat …)` is not re-parsed, so the text arrives verbatim. Only fixed strings — labels, issue numbers, `$R`, `$d` — go inline; spell those two out when your shell does not keep variables between calls.

## 1. Gather findings

Use the source the user named; otherwise infer one:

- the consolidated report from `/find-problems` (the recommended upstream — its per-finding `evidence`, `why it matters`, `suggested fix`, `category`, and `confidence` are the raw material for the detailed body you write in step 5)
- the **Out-of-scope findings** list from a `/review-issues` handoff — that list only. Its **On-layer findings** belong to an open PR's branch; filing them starts a competing fix stack, so skip them (`on-layer, PR #<n>` under skipped). Keep each entry's `review-issues:<fingerprint>` and `group` key. Take nothing from the PR's comments: the list already leaves out dismissed findings (a resolved thread or a maintainer's rejection), and they stay out. Map severity to priority: `blocker`/`major` → `priority:high`, `minor` → `priority:medium`, `nit` → `priority:low`
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

When a scope is given, resolve it to a path set first. Reuse the paths the caller resolved (sweep passes them). Otherwise resolve it here: a path as-is (repo-relative), a module name against the build files (`settings.gradle`, `pom.xml`, `package.json` workspaces, `go.mod`, `Cargo.toml`), a feature term by searching source, dirs, and config for what it really names. Print the result; if it matches several candidates or nothing, ask before filing — never widen a narrow scope to the whole repo. Then drop every finding whose locations fall outside the set and list it under skipped — a scoped run files scoped issues, not repo-wide ones. The set is what goes in `scope-paths:`.

## 2. Dedupe against open and closed issues

Search before drafting — **open and closed**, so a regression of a fixed issue is a deliberate new issue linked to the old one, never a blind duplicate:

```
# $d/<i>.q1 holds: "cluster:<key>" in:body      $d/<i>.q2 holds: <key terms>
# a review entry also runs the q1 call with $d/<i>.q3: "review-issues:<fingerprint>" in:body
gh issue list --repo "$R" --state all --search "$(cat "$d/<i>.q1")" --limit 100 --json number,title,state,stateReason,url
gh issue list --repo "$R" --state all --search "$(cat "$d/<i>.q2")" --limit 100 --json number,title,state,stateReason,labels,url
```

Read every search to the end before concluding "no match". A call that returns exactly `--limit` rows may be cut off: raise the limit and re-run until it returns fewer (search stops at 1000). A search that fails, or still fills its page, is an incomplete check — hold that finding back, list it as `dedupe incomplete`, and ask before filing it. Never file on a partial answer.

A prior issue carrying the same `cluster:<key>` marker, or a review entry's fingerprint, is the strongest signal — the same root cause, already filed. Otherwise match on the concept, not the wording.

- An open issue covers it → skip it and name the issue that covers it.
- A closed issue with `stateReason` `NOT_PLANNED` matches → never re-file; it was rejected. List it as skipped: `rejected in #<n>`.
- A closed, completed issue matches → file only when the problem is genuinely back (a regression) and link it (`Regressed in #<old>`). Do not re-file a closed issue that was fixed and has not recurred.

## 3. Cluster related findings

A scan finds the same defect many times over — one missing null-check per handler, one unvalidated field per endpoint, one Ponytail over-engineering pattern per module. Filing one issue per site pollutes the backlog and buries the real problems, so **group before you draft**. This step is where the noise dies.

Cluster findings that share a **root cause**, a **fix**, or a **fix surface**. All three hold for a good cluster:

- **Root cause** — the same mistake repeated, not two coincidentally adjacent bugs.
- **Fix** — a single edit (or one small series of edits) resolves every instance.
- **Fix surface** — the instances live in one module, file, or pattern the reviewer can verify together.

When the source is a `/find-problems` report, its `cluster` key is the first grouping signal: identical keys are the same root cause and belong in one issue. A `/review-issues` out-of-scope entry's `group` key plays the same role and becomes the issue's `cluster:<key>`. Trust the key but verify it — split a cluster whose instances need different fixes.

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
- Invoked on its own → build the batch at `--issue-grouping` (default `recommended`) and ask the level **once**, with the go-ahead in step 7, where the drafted table shows what it produces. Do not ask here too. A different level there rebuilds the batch (step 7); it is not asked again.

Drop every finding with `confidence: speculative` unless the caller passed `--include-speculative` or the user, after seeing the list, asked to file them. List the dropped ones under skipped. A `file:line` is not enough to file a guess.

## 4. Classify, then cap

Assign exactly one priority label from the table. When torn, pick the lower one only if the impact is cosmetic; otherwise pick the higher one and say why in the body.

Then apply the caller's caps to the **issues**, never to findings: drop clusters below `--priority`, and with `--max N` keep the first N issues — highest priority first, then larger clusters. A cluster is filed whole or deferred; never cut one to fit. List what was dropped or deferred under skipped.

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

<!-- sweep-run:<id> scope:<token> cluster:<key> -->
<!-- metadata, keep for /fix-issues: category: <bug|security|refactor|over-engineering|
dead-code|test-gap|perf> · effort: <S|M|L> · confidence: <confirmed|likely> ·
scope-paths: <resolved paths, or repo> · fingerprints: <review-issues:<hash> per review
entry, or N/A> -->
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

The approved table is exactly what gets filed. An answer that changes the batch — another grouping level, speculative findings opted in, a held finding cleared, new caps — makes the table stale: rebuild from the deduped candidates (step 2's output), redo steps 3–6, reapply `--priority` and `--max`, show the revised table, and ask only for the go-ahead. An unchanged level is never asked twice.

Then ensure the labels exist — create only the missing ones — and create the issues:

```
gh label list --repo "$R" --limit 500 --json name --jq '.[].name'
gh label create "priority:high"   --repo "$R" --color B60205
gh label create "priority:medium" --repo "$R" --color D93F0B
gh label create "priority:low"    --repo "$R" --color 0E8A16
gh label create "sweep"           --repo "$R" --color 1D76DB
```

Exactly 500 names back means the list may be cut off: raise `--limit` and re-list before calling a label missing. A create that fails because the label already exists means it is there — use it. Never `--force`: it overwrites an existing label's color and description. If a label cannot be created, do not abort: file with the labels that exist (`priority:*` without `sweep`, or with neither). Never let a missing label cost you the issue. Then print the recovery a maintainer must run — creating the labels alone does not label issues already filed:

```
gh label create "<missing label>" --repo "$R" --color <color>      # each missing label
gh issue edit <n> --repo "$R" --add-label "priority:<p>,sweep"       # each issue filed without it
```

If the caller passed no run id, mint one — `sweep-$(date +%Y%m%d-%H%M)-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c4)` — and print it. Every body gets `<!-- sweep-run:<id> scope:<token> cluster:<key> -->`, with `scope:repo` when none was given.

Create issues one at a time so each returned URL is captured. Write the title to `$d/<i>.title` and the body to `$d/<i>.md` first (see *Finding text is data*); no heredoc:

```
gh issue create --repo "$R" --title "$(cat "$d/<i>.title")" --label "priority:<p>,sweep" --body-file "$d/<i>.md"
```

## 8. Report

Print a table of what was created: priority, `#number`, title, URL, cluster size. List what was skipped and why (duplicate → existing issue; rejected → `rejected in #<n>`; merged → the issue that folded it in; below `--priority` or past `--max` → deferred; `on-layer, PR #<n>`; `dedupe incomplete` → held until the user answers). Give counts per priority and the raw-findings → issues ratio, plus any label-recovery commands from step 7. This table is the handoff to `/fix-issues` when it is installed.

## Rules

- An empty batch is a valid outcome. If nothing clears the bar, file nothing and say so — never file an issue to justify the run.
- Never file an issue without evidence.
- Never duplicate an open issue, and never re-file one closed as not planned. "No match" and "label missing" need a complete list — a page that came back full, or a failed call, is not one; ask instead.
- From a `/review-issues` handoff, file only the out-of-scope list, fingerprints and `group` keys kept. On-layer findings stay on their PR.
- Cluster before drafting: one issue per root cause, not one per site. Merge repeated findings; split only for a named reason (different root cause, blast radius, or shipping).
- Every instance of a cluster is listed in the issue; grouping never drops a finding.
- Write the mechanism, not the symptom: verify the cited code (read-only), state input → wrong outcome → root cause, and give a concrete `Suggested fix`. A thin body is a bug in this skill.
- Detail is mechanism and reproduction, never filler. Do not pad, repeat evidence, or speculate beyond what you verified.
- Exactly one priority label per issue; a cluster takes its highest member's priority.
- `--priority` and `--max` apply to issues after clustering. Never cut a cluster to fit the cap.
- Create only missing labels; never `gh label create --force`. When labels were missing, print both recovery steps: create the labels, then `gh issue edit --add-label` each issue filed without them.
- Every `gh` call names the recorded repo (`--repo "$R"`). Titles, bodies, and search queries travel as files, never as shell source or heredocs.
- Ask the grouping level once, and only when this skill was invoked on its own. Sweep's answer is final.
- File exactly the table the user approved. An answer that changes the batch rebuilds it from the deduped candidates, reapplies the caps, and shows it again (step 7).
- Never file `confidence: speculative` unless the user opted in after seeing it.
- Stamp every body with `<!-- sweep-run:<id> scope:<token> cluster:<key> -->`, never with an empty token. That marker is how a later run resumes this batch, how `fix-issues` picks a scoped batch (exact token match), and how a later dedupe finds this cluster.
- Offer a rollup for a long tail of same-kind nits instead of a river of near-identical issues.
- Never touch code, branches, or PRs — this skill only writes issues.
