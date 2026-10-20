# Create Issues — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/create-issues                      # infer the source (a report in this chat), else scan
/create-issues path/to/report.md    # a report or plan file you have
/create-issues --scope storage      # only findings in one area; resolved to paths, confirmed if ambiguous
/create-issues --scope .            # whole repo, stamped scope:repo
/create-issues --priority medium --max 5   # at most 5 issues, high and medium only
```

Standalone, report → issues, is the supported path; it needs only `gh`. Every `gh` call names
the repo you confirmed (`--repo owner/repo`), so a fork never files into its upstream by
accident, or the reverse.

Inside `/sweep` you never invoke this directly — sweep passes the report, the run id, the repo,
the scope token and resolved paths, the caps, and the grouping level, and this skill files
without asking again.

`--max` counts issues after clustering, not findings: a 9-instance cluster is one issue, filed
whole or deferred whole.

## Optional companions

`/find-problems` (writes the report this skill files best), `/fix-issues` (fixes the issues as
stacked PRs), `/review-issues` (reviews those PRs), `/fix-findings` (fixes the findings it posts),
`/merge-prs` (merges the reviewed, fixed PRs when asked), and `/sweep` (all of it in one command)
are not required and may not ship with this copy. They live in
[github.com/LucaNerlich/ai-rules-skills](https://github.com/LucaNerlich/ai-rules-skills):

```
git clone https://github.com/LucaNerlich/ai-rules-skills.git
cd ai-rules-skills && ./install.sh     # syncs every skill + /command wrapper into each harness found
./install.sh --only find-problems      # or just the ones you want
```

Or copy `skills/<name>/` next to this skill's directory in your harness's skills folder.

## Where findings come from

Best source is a `/find-problems` report (an optional companion): it already has `evidence`, `root cause`, `trigger`,
`blast radius`, `repro`, `suggested fix`, and `confidence`. A `/review-issues` handoff also works,
but only its **Out-of-scope findings** list is filed: its **On-layer findings** belong to an open
PR's branch and are skipped as `on-layer, PR #n`, and dismissed findings never come back. Each
entry keeps its `review-issues:` fingerprint, its `group` becomes the issue's cluster key, and
severity maps to priority. A pasted plan or PR description works if it is specific enough to cite
a `file:line`.

If it cannot be pointed at, it is not an issue. That includes a `TODO` with no context.

## Grouping: the one question

| Level | Result | Use when |
| --- | --- | --- |
| `recommended` | one issue per root cause, rollups for the long tail | default |
| `coarse` | fold same-surface clusters into one issue with sub-checklists | you want a short backlog and are happy with bigger tickets |
| `strict` | one issue per finding instance | a very small, high-stakes batch |

The level is asked **once** — inside sweep at the file gate, or here when invoked directly, next
to the drafted table built at `--issue-grouping` (default `recommended`). Pick another level there
and the batch is rebuilt from the deduped findings, `--priority`/`--max` are reapplied, and the
new table comes back for a go-ahead — what gets filed is always exactly the table you approved.
It is issue grouping only; `fix-issues` asks the PR-side question separately.

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
<!-- metadata, keep for /fix-issues: category: ... · effort: S|M|L · confidence: ... · scope-paths: ... · fingerprints: ... -->
```

The first is how a later run resumes this batch, how `fix-issues` picks a scoped batch, and how
a later dedupe recognizes the cluster. The scope token is the scope term slugified (`--scope
storage` → `scope:storage`; none, `.`, or the repo root → `scope:repo`), so `/fix-issues --scope
storage` matches it exactly and never matches `scope:storage-legacy`. A scope that slugifies to
nothing (`..`, `/`) is refused before anything is filed. The resolved paths live in
`scope-paths:`. Do not strip either footer when editing.

## Labels

Requires `priority:high|medium|low` plus `sweep`. Only missing labels are created, never with
`--force`, so an existing label keeps its color and description. The label list is read in full
before a label counts as missing. If you cannot create labels (no
permission), the skill files with the labels that exist and prints two sets of commands for a
maintainer: `gh label create` for each missing label, then `gh issue edit <n> --add-label` for
each issue it filed without them. It will not abort.

## Titles and bodies are data

Finding text can contain `$(…)`, backticks, or a line reading `EOF`. The skill writes each title,
body, and search query to a file and passes it as `--title "$(cat file)"`, `--body-file file`,
`--search "$(cat file)"` — never pasted into a command line or a heredoc — so the text lands in
the issue verbatim and nothing in it runs.

## Dedupe behaviour

Searches open **and** closed issues, first for the same `cluster:<key>` marker (and a review
entry's fingerprint), then by concept. Every search is read to the end: a full page is re-run with
a higher limit, and one that still fills its page or fails holds the finding back as `dedupe
incomplete` and asks you — never "no match" from a partial list.

- Open match → skipped, and the existing issue is named.
- Closed as not planned → never re-filed; skipped as `rejected in #<n>`.
- Closed as completed, problem genuinely back → filed with `Regressed in #<old>`.
- Closed as completed, fixed and quiet → not re-filed.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| Far fewer issues than findings | clustering + rollups did their job | read the "N findings → M issues" line in the report |
| A finding you wanted is missing | speculative, outside `--scope`, below `--priority`, past `--max`, rejected before, or on-layer for an open PR | `--include-speculative`, widen the scope or caps; a `rejected in #n` finding stays rejected; an `on-layer, PR #n` finding is fixed on that PR's branch |
| Asked about a `dedupe incomplete` finding | a search hit its result cap or failed, so a match could not be ruled out | narrow the terms or check the repo by hand, then say file or skip |
| Issues created without labels | label creation was denied | run the printed recovery: `gh label create` for each missing label, then `gh issue edit <n> --repo <owner/repo> --add-label "priority:<p>,sweep"` for each listed issue — creating the labels alone leaves those issues unlabelled |
| "scope is empty" / asked to name a scope | the scope slugified to nothing (`..`, `/`) | pass a path, module, or term; `.` means the whole repo |
| Issues landed in the wrong repo | the target was not confirmed (fork vs upstream) | confirm the repo when asked; every `gh` call then names it with `--repo` |
| Nothing filed | nothing cleared the bar, or the verdict was `CLEAN` | correct outcome — an empty batch is a valid result, not a failed run |
| Duplicate filed anyway | titles differed but the concept matched | say so; the search matched on wording, not the root cause |
| Bodies look thin | the finding came from a scan that skipped the code read | re-run with the report from `/find-problems`, which carries the mechanism |

## Handoff

The report table (priority, `#number`, title, URL, cluster size) is what `/fix-issues` consumes, if
installed.
Nothing here touches code, branches, or PRs.
