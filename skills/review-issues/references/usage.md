# Review Issues — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/review-issues --stack              # the stack currently checked out
/review-issues 12 14 21             # exactly these PRs
/review-issues --all                # every open fix/* PR you authored
```

From `/sweep` you never pick the set by hand — sweep passes **every PR from every stack the run
opened**. If a run made more than one stack, `--stack` alone would only see the one you are
standing on.

## Fresh context is the whole point

A review runs in a subagent that did **not** write the code, gets the diff plus the linked issue
and repo conventions, and reads the surrounding code rather than only the diff. Reviewing your own
work in the same context finds nothing.

## What gets posted

One comment per finding, anchored to the changed line where possible, and it ends with a fenced
block that GitHub renders with a copy button:

```text
Verify the following first, then act ONLY if it holds.
...
If it does NOT hold: reply with what you found and change nothing.
```

That verify-first shape matters: the instruction is meant to survive being pasted into a different
agent, in a different context, days later. Do not rewrite it into prose — the fenced block is the
copy button.

Then one summary review per PR (`gh pr review --comment`), since GitHub will not let you approve
or request changes on your own PR.

## Dedupe

Two guards. First, semantic: the findings already on the PR (severity · path:line · title) go
into the reviewer's prompt as "already raised — do not report again", so a reworded title does
not slip through. Second, exact: each finding carries `<!-- review-issues:<fingerprint> -->`, a
12-char `shasum` of `path|normalized title` — deliberately not the line number. `/fix-issues`
rebases the chain constantly, so a line-based fingerprint would mint a new hash after every
rebase and repost the same finding.

A finding counts as dismissed when its review thread is resolved or a maintainer (`OWNER`,
`MEMBER`, `COLLABORATOR`) rejected it in a reply. A drive-by "this is fine" from anyone else is
read as context, not as a dismissal.

## The two handoff lists

Every pass ends with:

- **On-layer findings** — defects in the fix itself. These stay on that PR: a comment, or a commit
  on the branch. They are *not* filed as issues; a new issue starts a second stack from trunk and
  forks the work off the PR that was reviewed.
- **Out-of-scope findings** — a new bug the diff happened to expose, outside this PR's acceptance
  criteria. These go to `/create-issues`.

Both are grouped by fix surface, and a long tail of `nit`s is rolled up into one entry. A review
that posts twelve comments must not become twelve issues.

## A clean PR is a result

`Looks good` with nothing posted is a complete review. A reviewer asked to find problems always
finds some — that pull is how a good PR collects a page of nits and a `nit` becomes an issue and
an issue becomes a PR.

A `nit` still has to be a defect or a real clarity win. Preference is not a finding: naming you
would do differently, formatting, "consider extracting this", "could be more generic", or an
alternative design that is simply another way to do it. Those belong in the PR conversation at
most, never as a finding with an agent instruction. And never raise a severity to look valuable.

## Watch mode

```
/loop 10m /review-issues --stack
```

Each pass reviews only what changed since the last reviewed `headOid`, recorded as
`<!-- review-issues:reviewed <sha> -->`. Unmoved heads are skipped and findings are never
reposted.

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| Same finding posted twice | the reviewer was not given the already-raised list, or an older line-based marker | delete the duplicate; check step 2 built the list from comments **and** review threads |
| `422` on a line-anchored comment | a wrongly typed field (`line` sent with `-f` instead of `-F`), or the line is not part of the diff | read the error message; fix the call, and fall back to a general comment only for a line outside the diff |
| Cannot approve the PR | it is your own | that is what the `--comment` verdict is for |
| Review found nothing | diff reviewed without the surrounding code | re-run; the subagent must trace the flow, not just read the diff |
| A finding you dismissed returns next pass | the thread was left open and the reply was not from a maintainer | resolve the thread, or reply as an owner/member/collaborator |

## What this skill will not do

- Push code, merge, or change labels.
- File an on-layer finding as a new issue.
- Post an unverified hunch as a `blocker`.
- Review the review-fix in the same run — one round per sweep cycle.
