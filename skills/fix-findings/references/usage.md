# Fix Findings — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to: input formats, worked
examples, and the failure modes that actually happen. If the two disagree, `SKILL.md` wins.

## Run it

```
/fix-findings --stack                  # findings on the stack currently checked out
/fix-findings 12 14 21                 # findings on exactly these PRs
/fix-findings --all                    # findings on every open fix/* PR you authored
/fix-findings --review .git/sweep/sweep-20261014-0930-k3f9/review.md
/fix-findings --stack --on-layer-only  # commit on the branches, file nothing new
/fix-findings --stack --dry-run        # verify and report; change nothing
```

From `/sweep` you never invoke it by hand and never pick the set: sweep passes `review.md`, every
PR from every stack the run opened, and the approval from the fix gate.

## Where the findings come from

Two inputs, same result:

- **`review.md`** — the handoff `/review-issues` produced in a sweep run. Each entry carries
  `fingerprint`, `severity`, `title`, `PR`, `branch`, `location`, `claim`, `suggested fix`, and
  (out-of-scope only) `group`.
- **The PR comments** — for a standalone run, scan review threads and conversation comments for
  `<!-- review-issues:<fingerprint> -->`, then take the header and the fenced agent instruction
  from the comment body.

Prefer `review.md` when it exists: it is structured, and it already excludes dismissed findings.
The comments are the fallback, and they are the only source for a standalone run.

## Verify first

Every finding was posted with a verify-first instruction for exactly this reason. The instruction
is a script for that finding, not a command to obey:

1. Read the code at `path:line` and the flow around it.
2. Run the check it names — failing test, request, scenario — or prove the defect by reading.
3. Fix only if it holds. If it does not, reply with evidence and change nothing.

A finding that cannot be verified here — missing service, credentials, or environment — is not
fixed on a hunch. Security, auth, billing, data, and migrations are never guessed.

## The three outcomes

| Finding | Goes to | Thread |
| --- | --- | --- |
| Defect in the fix under review | commit on that PR's branch | reply `fix-findings:fixed`, resolve |
| A real bug the diff exposed, outside this PR | issue, then a file-disjoint stack off trunk | reply `fix-findings:filed`, resolve |
| Does not hold against the code | nowhere | reply `fix-findings:not-reproduced`, leave open |

`--on-layer-only` drops the middle row: on-layer fixes are committed and nothing is filed.

## Markers

Each reply carries a marker so a later pass, or a resume in a new session, knows what happened
(`<fingerprint>` is the full `review-issues:<hash>` token):

```
<!-- fix-findings:fixed <fingerprint> <sha> <diffHash> -->
<!-- fix-findings:not-reproduced <fingerprint> -->
<!-- fix-findings:filed <fingerprint> #<n> -->
```

- `fixed` — the commit is on the branch and `<diffHash>` is the pushed PR diff at the time of the fix;
  `/merge-prs` compares it to the current diff. Skipped next time. If a rebase later drops the
  commit, verify the sha is still there before trusting the marker.
- `not-reproduced` — verified and rejected; not re-verified next time. The thread stays **open** so
  it is never read as a dismissal.
- `filed` — the finding is tracked by an issue. The thread is resolved because the issue owns it now.

Resolving fixed and filed threads is deliberate: `/review-issues` treats a resolved thread as
dismissed, which is right — those findings are handled. Leaving a not-reproduced thread open keeps
a human in the loop without the bot reposting it.

## On-layer work is fix-issues step 5

Do not re-invent the branch mechanics. `gh stack checkout <branch>` (always with the branch),
smallest fix, verify, `git commit -F`, `gh stack rebase --upstack` if needed, `gh stack top`,
`gh stack submit --auto`. One submit per stack, after all its findings are committed — not one per
comment.

If a fix really belongs to a lower layer, use `fix-issues`' mid-stack move: commit in the layer
that owns it, `gh stack rebase --upstack`, `gh stack top`. Never put a lower-layer change in the
higher PR.

## Out-of-scope work is filed, then fixed

The order matters:

1. File the out-of-scope list through `/create-issues` — fingerprint and `group` kept, severity
   mapped to `priority:*`.
2. Check file-disjointness against **every** open stack's changed files.
3. Build a new stack off trunk for the non-overlapping issues; leave an overlapping one filed and
   deferred until its blocking stack merges.

Filing first gives the fix a tracker. It also means a deferred finding is never lost: the issue
carries the evidence, the fingerprint, and the reason it waited.

## Inside sweep

`--depth review` now ends by running this skill, after the fix-findings gate. You do not call it
separately, and answering yes at that gate approves both halves: commits on the reviewed layers
and the filed-and-fixed out-of-scope work. `--yes` answers yes. Answer no and the run stops at
`depth=review` with the review comments posted; the printed `/fix-findings` command picks it up
without re-reviewing.

`--depth merge` continues into `/merge-prs` after this step. That is the only depth that merges;
this skill never does. The out-of-scope stack created here was not reviewed, so it is not merged
in the same run.

One round per sweep: the fixes are not reviewed in the same run. Run `/review-issues` again if you
want them reviewed — that is a new pass, not part of the same sweep.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| Nothing to fix | every finding was dismissed, already fixed, or the batch was empty | a clean result; say so and stop |
| Same finding returns next pass | the reply was posted without its marker, or on the wrong PR | re-reply with `fix-findings:fixed`/`not-reproduced` on the finding's own thread |
| Thread will not resolve | no permission, or it is a general comment rather than a review thread | report the thread id; a general comment cannot be resolved — the reply is the record |
| `422` on a line-anchored finding reply | it was posted as a review comment, not a conversation comment | use the thread reply mutation; read the error instead of falling back |
| Out-of-scope issue not fixed | its files overlap an open stack | that is the file-disjoint rule; it is filed and deferred until the stack merges |
| New stack will not start | no `gh` auth, gh-stack missing, or dirty tree | fix the precondition and resume; never force a second stack |
| Finding is preference, not a defect | the review slipped a taste call through | reply, leave it open, change nothing — do not implement taste |
| Fix commit vanished after a rebase | the finding was `fixed` before a rebase dropped the hunk | re-check the claim, re-fix, re-reply with the new sha |

## What this skill will not do

- Fix a dismissed finding, a preference, or a finding on a closed unmerged PR.
- File an on-layer finding as an issue.
- Fix an out-of-scope finding on a reviewed layer, or start a stack that overlaps an open one.
- Guess on security, auth, billing, data, or migrations.
- Review its own fixes, review the new stack, or merge anything.
