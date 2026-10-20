# Sweep — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to: recipes, worked
examples, and the failure modes that actually happen. If the two disagree, `SKILL.md` wins.

## One command, one gate

By default, `/sweep` runs the whole pipeline to **ready-to-merge**:

```
/sweep
  → scan → file issues → fix as stacks → review every PR → fix every finding
  → stop: reviewed PRs are ready to merge
```

It asks **once**, after the report, showing the scope, projected issues, stack plan, and what the
run will do. Answer yes and it does not stop again — no "Next: run /review-issues", no "Next:
/fix-findings", no per-phase confirmation. That is the point of the command.

`--yes` skips the question. `--depth merge` adds one more question, the merge gate, because
merging is irreversible.

## Pick a depth

```
/sweep                                   # default: scan → file → fix → review → fix findings
/sweep --depth review                    # same, explicit
/sweep --depth report                    # scan only, file nothing
/sweep --depth file                      # scan + file issues, then stop
/sweep --depth fix                       # + open the stacks, then stop
/sweep --depth merge                     # + merge the reviewed, fixed PRs (opt-in)
```

The default is `review`. A lower depth is an **explicit stop**, not a fallback and not a failure.
When you only want the list, pass `report`; when you want to inspect the PRs before review, pass
`fix`.

## The usual run

```
/sweep --scope directwerk-podcast
```

1. It scans the podcast module, files clustered issues, and asks **once** with the full plan.
2. You approve; it builds the file-disjoint stacks and opens the PRs.
3. It reviews every PR, then fixes every finding — on-layer commits, out-of-scope work filed and
   fixed in its own file-disjoint stack — without stopping in between.
4. It ends with **Ready to merge** and the reviewed PR list.

Add `--depth merge` if you also want it to land the reviewed, fixed PRs after the merge gate.

## Narrow it

```
/sweep directwerk-digital                # a module (matched from the build files)
/sweep --scope Directwerk/directwerk-app # a path
/sweep --scope feed-builder              # a feature term, resolved to the paths it names
```

Any of the three prints the resolved path set and asks you to confirm it. If a term resolves to
nothing, the run stops — it does not fall back to the whole repo. That is deliberate: a narrow
run that silently widens is how you get 40 unrelated issues.

## Scope is a contract, not a filter

With `--scope`, findings outside it are not reported, issues outside it are not filed, and
`fix-issues` will not pick them up. Every issue carries a scope token in its marker — the term
slugified, `scope:storage` for `--scope storage`, `scope:repo` with none or `.` — and the resolved
paths in its metadata, so a scoped batch stays scoped even weeks later. `/fix-issues --scope
storage` matches that token exactly; `scope:storage-legacy` is a different scope. A scope that
slugifies to nothing (`..`, `/`) is refused, never stamped as an empty `scope:`.

The repo you confirm at the start (a fork or its upstream) is passed to every phase, and every
`gh` call names it with `--repo`, so issues and PRs never land in `gh`'s default repo by accident.

## Resuming

Each run gets an id, `sweep-YYYYMMDD-HHMM-xxxx` (four random characters, so two runs in the same
minute never collide), printed at the end and stamped into every issue it filed. Its state —
the report, the stacks and PRs, the review handoff and reviewed PR set, and the fix and merge
results — is saved untracked under `.git/sweep/<id>/`, so you can continue from a new session:

```
/sweep --resume sweep-20261014-0930-k3f9   # continue exactly that run
```

- Run state present → it reuses the report and its scope, and the stacks it already opened.
- A resumed run continues in **auto mode**: it does not re-ask the run gate. Only `--depth merge`
  adds the merge gate, unless `--yes`.
- `review.md` exists with the reviewed PR set → the review is done. Resume at `fix-findings` (or
  the merge gate); it never re-reviews those PRs just because a fix or merge failed.
- Issues already filed under that run id → it skips straight to the fix phase for those.
- Issues already in an open PR or on a `fix/<n>-*` branch → reported as in flight, never re-fixed.
- Findings already replied to with `fix-findings:fixed|not-reproduced|filed` → not retried.
- Run state missing (another clone) → issues are found by marker and PRs through their links; a
  lost report means a re-scan.

A repo full of older `priority:*` issues is **not** a resume. If you want to work that backlog,
that is `/fix-issues`, not `/sweep --resume`.

## Unattended runs

`--yes` answers the run gate with the flag values. At `--depth merge` it also answers the merge
gate. It does not mean "one PR per issue", it does not file speculative findings, and it never
bypasses branch protection.

```
/sweep --scope storage --yes                 # full run to ready-to-merge, no questions
/sweep --scope storage --depth merge --yes   # also merge what is eligible
```

Use it in CI-style runs where nobody is watching. Read the defaults first — they are the
anti-sprawl ones (recommended/recommended, 5 layers per stack, file-disjoint stacks).

## No phase handoffs

In auto mode, a phase ending on success is not a stop. The pipeline does **not** end with:

- `Next: run /fix-issues` after filing issues;
- `Next: run /review-issues` after opening the stacks;
- `Next: run /fix-findings` after posting review comments;
- `Next: run /merge-prs` after fixing findings.

Those commands appear only when you passed a lower `--depth` explicitly, or when a phase failed.
If you see "nothing was merged" as a status at the default depth, that is the bug this mode fixed:
the run should end with a **Ready to merge** list, not a handoff.

## After the review: what gets fixed where

The review and the fixes are one uninterrupted step. `fix-findings` verifies every posted finding
before acting, and each one lands in exactly one place:

| Finding | Where it goes |
| --- | --- |
| a defect in the reviewed fix | committed onto that PR's branch, reply + resolved thread |
| a real bug the diff exposed, outside the PR | filed as an issue, then fixed in a new file-disjoint stack off trunk |
| out-of-scope but its files overlap an open stack | filed and deferred until that stack merges |
| does not reproduce against the code | reply with evidence, no change, thread left open |
| dismissed (resolved thread or a maintainer's rejection) | never touched |

The fixes are not reviewed in the same run. If you want them reviewed, that is another
`/review-issues` pass — one round per sweep. The out-of-scope stack created in the run is new work
and is not reviewed either; it is not part of the ready-to-merge set.

## Merging: opt-in and last

`--depth merge` adds one gate and one step after the fixes. It merges only the PRs the review
covered, never the out-of-scope stack the fix step created — that stack was not reviewed. A PR is
eligible only with a `review-issues:verdict` marker, the reviewed diff (or a recorded
`fix-findings` hash), every finding handled, green checks, and a mergeable state.

- A stack merges bottom-up with `gh stack merge`, up to the **longest eligible prefix**. The layer
  above the first hold stays open; the stack can land piecewise.
- Regular PRs merge with `gh pr merge`, bottom-up.
- A merge queue reports `queued`, not `merged`; the method is the queue's choice.
- `--merge-method squash|merge|rebase` and `--merge-engine auto|stack|pr|git` are optional. Raw
  git is explicit only, never for a stack, and never a way around a failing check.
- A held layer stops everything above it. A failed merge is the answer — never `--admin`, force,
  or a different method.

```
/sweep --scope storage --depth merge --merge-method squash
```

The merge gate is the last word: nothing eligible, nothing merged.

## Tuning the two knobs

```
--issue-grouping recommended|coarse|strict   # findings → issues
--pr-grouping    recommended|strict|coarse   # issues → PRs
```

They are independent. `coarse` on both double-folds: several findings become one mega-issue, then
mega-issues get bundled into mega-PRs. `--grouping <level>` sets both and warns when you do.

`strict` is the "one issue per finding instance, one PR per issue" path. It is available, and it
is the sprawl you were trying to avoid — reach for it only for a tiny batch.

## When it stops early

| Symptom | Cause | Do |
| --- | --- | --- |
| "scope did not resolve" | feature term matched nothing | give a path or module name |
| Files nothing, report says `CLEAN` | the code is fine | this is the correct outcome, not a failed run |
| Files nothing, report looks fine | everything was duplicate or speculative | check the skipped list; `--include-speculative` to file guesses |
| Stopped after filing | you passed `--depth file` | drop it; the default continues to review and fixes |
| Stopped after opening PRs with "Next: review" | you passed `--depth fix` (or a phase failed) | drop it; the default continues. If it happens without `--depth fix`, that is a bug — re-run with the default |
| Stopped after review, findings unfixed | a pre-auto `--depth review` run, or a failed fix phase | re-run `/sweep --resume <id>`; it continues and does not re-review |
| An out-of-scope finding is filed but not fixed | its files overlap an open stack | that is the file-disjoint rule; it waits until that stack merges |
| A finding came back "not reproduced" | it did not hold against the code when verified | the reply carries the evidence; the thread stays open for a maintainer |
| Nothing merged at `--depth merge` | the merge gate was answered no, or nothing was eligible | read the held reasons; fix the finding or wait for green, then `/merge-prs` |
| A PR is held on an unhandled finding | the thread is unresolved and has no `fix-findings` reply | run `/fix-findings`, then merge again |
| Merge reported `queued` | the base branch uses a merge queue | wait for the queue; do not re-enqueue |
| `gh stack merge` says "not a stack" | the PRs are base-chained but not a GitHub stack | use `--merge-engine pr` |
| A merge failed on branch protection | the repo needs an approval or check the pipeline cannot provide | get a human approval or fix the check; never bypass |
| Stacked PRs disabled | repo has no Stacked PRs | it asks; approve the plain-PR fallback or stop |
| Nothing happens at all | `/sweep` not in the harness | `./install.sh`, then restart the harness |

## What sweep will not do

- Widen a scope you set.
- File a guess (`confidence: speculative`) unless you asked.
- Open anything to justify the run: a `CLEAN` report ends the cycle.
- Stop after a successful phase with a "Next: run …" handoff in auto mode.
- Build a stack longer than `--max-layers`, or a second stack touching the same files.
- File a defect in one of its own PRs as a new issue — that goes back onto the layer.
- Fix an out-of-scope finding on a reviewed layer, or start a stack that overlaps an open one.
- Review the review-fix in the same run — one round per sweep.
- Merge anything unless `--depth merge` was chosen (or `/merge-prs` was run).
- Merge an unreviewed PR, or the out-of-scope stack created in the same run.
- Merge a PR with an unhandled finding, a failing check, or an approval the pipeline cannot give.
- Bypass branch protection, force a merge, or rebase a PR to make it mergeable.
