# Merge PRs — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/merge-prs --stack                 # the reviewed PRs in the current stack
/merge-prs 12 14 21                # exactly these reviewed PRs
/merge-prs --all                   # every open fix/* PR you authored with a review verdict
/merge-prs 12 14 --dry-run         # check eligibility, merge nothing
/merge-prs 12 14 --merge-method squash
/merge-prs 12 14 --engine pr       # regular PR merging, no gh-stack
```

From `/sweep` you never invoke it by hand: `--depth merge` runs it after the fixes, with the
phase-6 PR list and the merge gate's approval.

## What is eligible

A PR merges only when **all** of these are true:

| Gate | Why |
| --- | --- |
| in the reviewed set | merging an unreviewed PR is not a pipeline action |
| has `review-issues:verdict` | proof the review actually ran |
| every finding handled | resolved thread, or `fix-findings:fixed/filed/not-reproduced` |
| checks green | no failing, pending, cancelled, or timed-out check |
| mergeable | no conflicts, not a draft, not `BLOCKED`/`UNSTABLE` |
| no `CHANGES_REQUESTED` | a requested change is not a merge |
| no missing required approval | the pipeline cannot approve its own PR; branch protection wins |
| reviewed diff (or a fix) | the current diff matches the verdict's `diffHash`, or the latest `fix-findings:fixed` reply's hash |

A clean PR with a `Looks good` verdict and no findings is eligible. A PR with findings is
eligible only after `/fix-findings` handled every one. The verdict's old `Blocked`/`Concerns`
label does not block by itself — the findings list is what decides — but say so in the report.

The verdict records a hash of the reviewed diff. If the diff changed and the latest
`fix-findings:fixed` reply does not record the **same** current hash, someone pushed after the
review or the fix: the PR is not eligible. A rebase preserves the diff, so a moved head alone is
fine.

A PR with no verdict marker was not reviewed. Do not merge it and do not guess: run
`/review-issues` first, or leave it out.

## The engines

| Engine | What it calls | Use it for |
| --- | --- | --- |
| `auto` (default) | `gh stack merge` for chains, `gh pr merge` for standalone PRs | the normal pipeline |
| `stack` | `gh stack merge <top> --yes --<method>` | a gh-stack chain, including a single layer |
| `pr` | `gh pr merge <n> --<method>` bottom-up | regular PRs, or gh-stack unavailable |
| `git` | local `git merge` + push | an explicit last resort, never a stack |

`gh stack merge` is all-or-nothing: it merges every member up to the chosen PR, and if any member
cannot merge, none do. That is why the plan merges the **longest eligible prefix** of open PRs: the
top open PR of the prefix is the target, and everything above it is held.

`gh stack merge` only checks that PRs are open and not drafts before it starts. GitHub evaluates
branch protection and repository rules when the merge runs. Bypassing merge requirements is not
supported, so a rejected merge is the answer — never retry with `--admin` or a raw push.

The `pr` engine merges one layer at a time. Re-fetch the next PR's base after each merge: GitHub
retargets a stacked PR when its base lands.

## Merge queue

If the base branch uses a merge queue, `gh stack merge` adds the stack to the queue instead of
merging directly. The method flags are ignored with a warning, and the layers may land in separate
groups. Report **queued**, not merged, and do not enqueue a second time.

## Partial stacks

A stack is designed to land piecewise. Merge the bottom prefix that is fully eligible, then stop:
a merged lower PR is skipped, and the next open PR becomes the bottom of the remaining chain.

```
1. #12  eligible      → merged
2. #14  eligible      → merged
3. #15  unhandled     → held
4. #16  eligible      → held (layer 3 is below it)
```

Never skip layer 3 to merge layer 4. Never rebase the upper layers just to make them mergeable:
that moves the reviewed head. Run `/fix-issues` (or `/fix-findings`) and `/review-issues` again
on the next pass. `gh stack sync --prune` after a **complete** stack is safe; after a partial one
it rewrites open layers, so print it instead of running it.

## Raw git

`--engine git` exists for the case where GitHub PR merging is unavailable and the user explicitly
wants a local merge:

- It bypasses GitHub's checks and branch protection on the local merge, then pushes. A protected
  trunk will reject the push; that is the correct outcome.
- It never runs for a stack. Confirm with `gh stack checkout <pr>` + `gh stack view --json`; if the
  PR is in a stack, use `stack` or `pr`. The base must be trunk — if it is another open PR's
  branch, merge the lower PR first.
- It refuses `rebase`; use `gh pr merge --rebase`.
- It closes the PR with a comment naming the merge commit only after the push succeeds.

If you are reaching for `--engine git` to get around a failing check or a required approval, stop.
The merge is not ready.

## Inside sweep

`--depth merge` runs the whole chain through the fixes, then the merge gate, then this skill.
`--depth review` stops before merging. The merge set is the PRs from phase 6 — the ones the review
actually covered. The out-of-scope stack created in phase 9 was never reviewed, so it is **not**
merged in the same run; review it in a later pass.

Answering yes at the merge gate approves only the eligible set shown. `--yes` answers yes, still
without bypassing checks or branch protection. If you answer no, nothing is merged and the run
ends at `depth=review`.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| "not reviewed" despite an open PR | no `review-issues:verdict` marker | run `/review-issues` on it; do not merge on faith |
| "changed since review" | the diff matches neither the verdict's `diffHash` nor a `fix-findings:fixed` hash | run `/review-issues` on the new head; do not merge an unreviewed change |
| Held on an unhandled finding | the thread is unresolved and has no `fix-findings` reply | run `/fix-findings`, then merge again |
| Held on checks | failing, pending, or cancelled checks | fix the failure, wait for green, re-run |
| Held on `REVIEW_REQUIRED` | branch protection needs an approval the pipeline cannot give | get a human approval, or lower the rule — do not bypass |
| `gh stack merge` says "not a stack" | the PRs are base-chained but not a GitHub stack | use `--engine pr` |
| `gh stack merge` fails, Stacked PRs disabled | the repo has the feature off | use `--engine pr`; do not treat it as a merge failure |
| `gh stack merge` fails on a layer | branch protection, a conflict, or a required check | read the error; fix and re-run. Do not fall back to per-PR merges |
| Merge queued, not merged | base branch uses a merge queue | report queued; wait for the queue, do not enqueue again |
| Stack merged but branches remain | partial merge, or `sync` not run | `gh stack sync --prune` after the whole stack lands |
| A `not-reproduced` blocker was merged | the fix step verified it was not a defect | deliberate; the report names it. Re-open the finding if you disagree |

## What this skill will not do

- Merge an unreviewed PR, or the out-of-scope stack from the same run.
- Merge with an unresolved, unmarked finding.
- Merge a draft, a conflicting PR, or one with failing/pending checks.
- Bypass branch protection, required approvals, or required checks.
- Rebase or push to make a PR mergeable.
- Review, fix, or open anything after merging.
- Run `--engine git` on a stack, or without an explicit choice.
