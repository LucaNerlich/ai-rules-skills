# Create Issues — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/create-issues                      # infer the source (usually the last /find-problems report)
/create-issues path/to/report.md    # a report or plan file you have
/create-issues --scope storage      # only findings in one area
/create-issues --priority medium --max 5   # at most 5 issues, high and medium only
```

Inside `/sweep` you never invoke this directly — sweep passes the report, the run id, the scope,
the caps, and the grouping level, and this skill files without asking again.

`--max` counts issues after clustering, not findings: a 9-instance cluster is one issue, filed
whole or deferred whole.

## Where findings come from

Best source is a `/find-problems` report: it already has `evidence`, `root cause`, `trigger`,
`blast radius`, `repro`, `suggested fix`, and `confidence`. A `/review-issues` handoff also works
(severity maps to priority). A pasted plan or PR description works if it is specific enough to
cite a `file:line`.

If it cannot be pointed at, it is not an issue. That includes a `TODO` with no context.

## Grouping: the one question

| Level | Result | Use when |
| --- | --- | --- |
| `recommended` | one issue per root cause, rollups for the long tail | default |
| `coarse` | fold same-surface clusters into one issue with sub-checklists | you want a short backlog and are happy with bigger tickets |
| `strict` | one issue per finding instance | a very small, high-stakes batch |

The level is asked **once** — inside sweep at the file gate, or here when invoked directly. It is
issue grouping only; `fix-issues` asks the PR-side question separately.

## Rollups

Twelve missing docstrings are one issue called `Missing docstrings in directwerk-podcast (12
items)`, not twelve. A rollup is `priority:low` unless one instance is genuinely worse, in which
case that instance gets its own issue and the rest stay rolled up.

This is the single biggest lever on backlog noise. If a scan produces a long tail of tiny
findings, the rollup is the answer — not lowering the volume knob on the scan.

## What one issue looks like

Title is imperative and under ~80 chars ("Guard every presign path against empty keys"), and
names the pattern rather than one site. The body has `## Finding` (what is wrong, where with
quoted code, why it matters, root cause, reproduction, evidence + confidence) and `## Suggested
fix` (approach, optional sketch, alternatives, out of scope), then acceptance criteria.

Two footers are load-bearing:

```
<!-- sweep-run:<id> scope:<token> cluster:<key> -->
<!-- metadata, keep for /fix-issues: category: ... · effort: S|M|L · confidence: ... · scope-paths: ... -->
```

The first is how a later run resumes this batch, how `fix-issues` picks a scoped batch, and how
a later dedupe recognizes the cluster. The scope token is the scope term slugified (`--scope
storage` → `scope:storage`, none → `scope:repo`), so `/fix-issues --scope storage` matches it
exactly and never matches `scope:storage-legacy`. The resolved paths live in `scope-paths:`. Do
not strip either footer when editing.

## Labels

Requires `priority:high|medium|low` plus `sweep`. Only missing labels are created, never with
`--force`, so an existing label keeps its color and description. If you cannot create labels (no
permission), the skill files unlabelled and prints the commands a maintainer must run — it will
not abort.

## Dedupe behaviour

Searches open **and** closed issues, first for the same `cluster:<key>` marker, then by concept.

- Open match → skipped, and the existing issue is named.
- Closed as not planned → never re-filed; skipped as `rejected in #<n>`.
- Closed as completed, problem genuinely back → filed with `Regressed in #<old>`.
- Closed as completed, fixed and quiet → not re-filed.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| Far fewer issues than findings | clustering + rollups did their job | read the "N findings → M issues" line in the report |
| A finding you wanted is missing | speculative, outside `--scope`, below `--priority`, past `--max`, or rejected before | `--include-speculative`, widen the scope or caps; a `rejected in #n` finding stays rejected |
| Issues created without labels | label creation was denied | run the printed `gh label create` commands |
| Nothing filed | nothing cleared the bar, or the verdict was `CLEAN` | correct outcome — an empty batch is a valid result, not a failed run |
| Duplicate filed anyway | titles differed but the concept matched | say so; the search matched on wording, not the root cause |
| Bodies look thin | the finding came from a scan that skipped the code read | re-run with the report from `/find-problems`, which carries the mechanism |

## Handoff

The report table (priority, `#number`, title, URL, cluster size) is what `/fix-issues` consumes.
Nothing here touches code, branches, or PRs.
