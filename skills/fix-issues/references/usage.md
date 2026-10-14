# Fix Issues — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/fix-issues                       # next batch of priority:high, then ask
/fix-issues --priority medium     # include medium
/fix-issues 42 47 51              # exactly these, in that order bottom→top
/fix-issues --scope storage       # only issues from a scoped sweep run
/fix-issues --resume sweep-20261014-0930
```

Inside `/sweep` you never invoke this directly — sweep passed the batch and the plan, so it builds
without asking again.

## What a stack looks like here

Highest priority at the bottom (it merges first and unblocks everything above it). Related issues
that share a fix surface become **one layer**, so one PR closes them together:

```
main
 └─ fix/12-presign-guard          #12 + #15   guard every presign path
     └─ fix/14-upload-retry      #14        retry upload on 5xx
         └─ fix/21-drop-factory  #21        drop one-caller factory
```

Grouping signals: same module and same kind of defect; one edit satisfies all their acceptance
criteria; or a rollup of same-kind low nits. Never grouped: a security/auth/billing/data fix with
anything else, or issues whose verification differs.

## More than one stack

A chain longer than `--max-layers` (default 5) is not reviewable. Two stacks may both base on
trunk only if **no file appears in both** — otherwise the second cannot merge until the first
lands, whatever you call it.

```
/fix-issues --max-layers 4 --stacks auto        # file-disjoint chunks, highest priority first
/fix-issues --stacks by-module                  # one stack per module
```

If the overlapping set is itself bigger than the cap, it stays one stack and you are asked to
raise `--max-layers` or defer the overflow. It will not be "split" onto trunk anyway.

## Follow-up work: check out what exists first

```
gh stack view --json     # see the current stack
gh stack checkout 7      # by stack number
gh stack checkout 42     # by PR number
gh stack checkout fix/12-presign-guard
```

Never run bare `gh stack checkout` or `gh stack switch` — no argument opens an interactive picker
and hangs the agent.

## Review fixes stay on the layer

A review comment on an open PR is not a new batch. Fixing it by filing an issue starts a second
stack from trunk and forks the work off the PR that was reviewed. Instead:

```
gh stack checkout fix/12-presign-guard
# make the smallest fix that satisfies the comment, commit, no `Fixes` unless it closes something
gh stack rebase --upstack     # if this layer is not the top
gh stack top
gh stack submit --auto        # update the open PRs
```

`/sweep --depth review --fix-on-layer` drives exactly this.

## `Fixes` vs `Refs`

`Fixes #n` closes the issue on merge. Use it only when the layer fully meets that issue's
acceptance criteria. Partial coverage — or an issue another layer still has to touch — gets
`Refs #n`. Close-on-merge work that is not finished is how a stack quietly loses track of an
issue.

## Stuck or blocked issues

An issue that cannot be implemented (missing decision, missing access, unclear requirement) gets
`sweep:blocked`, a comment saying what is missing, and leaves the queue. It does **not** freeze
medium and low work behind it. Re-run after answering the question on the issue.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| `submit` fails, Stacked PRs disabled | repo has the feature off | approve the plain-PR fallback when asked (exit code 9 territory) |
| Rebase conflict | trunk moved under the chain | resolve the paths from stderr, `git add`, `gh stack rebase --continue`; else `--abort` |
| A layer is huge | it is a clustered issue | expected — do not split it across layers |
| Second stack will not merge | it shares files with the first | it should not have been a second stack; re-plan |
| `checkout` never returns | you ran it with no argument | Ctrl-C, then pass a branch/PR/stack number |
| Layer 3 needs a change from layer 1 | wrong layer | `gh stack down`, commit there, `gh stack rebase --upstack`, `gh stack top` |

## What this skill will not do

- Open standalone PRs (unless Stacked PRs are disabled **and** you approve).
- Open a PR on a failing or unrun check.
- Merge from the CLI — including `gh stack merge`, which exists and is deliberately unused.
- Close an issue by hand when a keyword will.
