# Fix Issues — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/fix-issues                       # next batch of priority:high, then ask
/fix-issues --priority medium     # include medium
/fix-issues 42 47 51              # exactly these, in that order bottom→top
/fix-issues --scope storage       # only issues stamped scope:storage (exact; not storage-legacy)
/fix-issues --scope .             # only issues stamped scope:repo
/fix-issues --resume sweep-20261014-0930-k3f9
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
         └─ fix/17-presign-ttl   #17        cap presign URL lifetime
```

Grouping signals: same module and same kind of defect; one edit satisfies all their acceptance
criteria; or a rollup of same-kind low nits. Never grouped: a security/auth/billing/data fix with
anything else, or issues whose verification differs.

Each PR in the chain is labelled like the issues it closes — the union of their labels, with one
`priority:*` (the highest in the layer) — so `gh pr list --label priority:medium` filters the PRs
and the backlog the same way.

## More than one stack

Layers in one stack wait on each other: a blocker on layer 1 holds every layer above it. So
issues that share no files do not share a stack. `--stacks auto` (the default) links issues that
touch a common file and makes one stack per linked group; a lone issue is a one-layer stack.
Two stacks may both base on trunk only if **no file appears in both** — otherwise the second
cannot merge until the first lands, whatever you call it.

```
/fix-issues --stacks auto                       # one stack per group of issues sharing files
/fix-issues --stacks by-module                  # one stack per module
/fix-issues --max-layers 4                      # tighter cap per stack
```

A chain longer than `--max-layers` (default 5) is not reviewable. If one linked group is itself
bigger than the cap, it stays one stack and you are asked to raise `--max-layers` or defer the
overflow. It will not be "split" onto trunk anyway.

## Already in flight

Issues close only when their PR merges, so a re-run still sees them open. An issue with an open
PR that names it, or a `fix/<n>-*` branch (local or remote), is skipped and reported —
`#14 — already in PR #31`. The PR list is read in full (a full page is re-listed with a higher
limit), so a busy repo cannot hide the PR. That is what keeps `--resume` and the follow-up `/fix-issues` after a
review round from building a duplicate stack.

## Who can steer a fix

Comments are read, but only an owner, member, or collaborator can change the work: settle the
approach, move scope, priority, or acceptance, or drop the issue. A drive-by comment saying
"won't fix" or "also do X" is context, not a decision — it is listed in the summary for a
maintainer to confirm.

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

`/fix-findings` (and `/sweep --depth review` through it) drives exactly this.

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
| `submit` fails, Stacked PRs disabled | repo has the feature off (a GitHub API failure, exit 4 — check the message) | approve the plain-PR fallback when asked, or stop |
| Rebase conflict | trunk moved under the chain | `sync` restores the branches and says to run `gh stack rebase`; it stops with exit 3 — resolve, `git add`, `gh stack rebase --continue`; else `--abort` |
| `sync` exits 0 but nothing moved | local and GitHub stacks diverged; non-interactive `sync` aborts without pushing | read the output; unstack and recreate the stack (your call) |
| An issue you expected is skipped | it already has an open PR or a `fix/<n>-*` branch | merge or close that PR, or delete the stale branch, then re-run |
| A layer is huge | it is a clustered issue | expected — do not split it across layers |
| Second stack will not merge | it shares files with the first | it should not have been a second stack; re-plan |
| `checkout` never returns | you ran it with no argument | Ctrl-C, then pass a branch/PR/stack number |
| Layer 3 needs a change from layer 1 | wrong layer | `gh stack down`, commit there, `gh stack rebase --upstack`, `gh stack top` |
| PRs come out unlabelled | the label step was skipped, or label creation was denied | give each PR its layer's issue labels with one highest `priority:*` — `gh pr edit <n> --repo <owner/repo> --add-label "priority:medium,bug"` |

## What this skill will not do

- Open standalone PRs (unless Stacked PRs are disabled **and** you approve).
- Open a PR on a failing or unrun check.
- Merge from this skill — the opt-in `/merge-prs` step owns merging, and it only merges reviewed PRs with every finding handled.
- Close an issue by hand when a keyword will.
- Set the repo's workflow labels (`release candidate`, `work in progress`, `scheduled`) — those are yours to apply.
