# Sweep — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to: recipes, worked
examples, and the failure modes that actually happen. If the two disagree, `SKILL.md` wins.

## Pick a depth

```
/sweep                                   # scan + file issues, then stop  (default)
/sweep --depth report                    # scan only, file nothing
/sweep --depth fix                       # + fix as file-disjoint stacks
/sweep --depth review                    # + review every stack, handle findings
```

Report → file are the two cheap steps. `fix` writes code, `review` posts comments. When you only
want the list, stop at `report`.

## Narrow it

```
/sweep directwerk-digital                # a module (matched from the build files)
/sweep --scope Directwerk/directwerk-app # a path
/sweep --scope feed-builder              # a feature term, resolved to the paths it names
```

Any of the three prints the resolved path set and asks you to confirm it. If a term resolves to
nothing, the run stops — it does not fall back to the whole repo. That is deliberate: a narrow
run that silently widens is how you get 40 unrelated issues.

## The usual run

```
/sweep --scope directwerk-podcast --depth fix
```

1. It scans the podcast module, files clustered issues, and stops to ask how to fix them.
2. You approve the plan; it builds the stacks and opens the PRs.
3. It hands you the `/review-issues` command for those PRs.

## Scope is a contract, not a filter

With `--scope`, findings outside it are not reported, issues outside it are not filed, and
`fix-issues` will not pick them up. Every issue carries the scope in its body
(`scope:<resolved>`), so a scoped batch stays scoped even weeks later.

## Resuming

Each run gets an id, `sweep-YYYYMMDD-HHMM`, printed at the end and stamped into every issue it
filed. Two ways to continue:

```
/sweep --resume sweep-20261014-0930      # continue exactly that run
```

- Session still open → it offers to reuse the report it already produced.
- Issues already filed under that run id → it skips straight to the fix gate for those.

A repo full of older `priority:*` issues is **not** a resume. If you want to work that backlog,
that is `/fix-issues`, not `/sweep --resume`.

## Unattended runs

`--yes` answers the gates with the flag values. It does not mean "one PR per issue", it does not
file speculative findings, and it does not commit review fixes onto open layers.

```
/sweep --scope storage --depth file --yes        # scan, file, done
/sweep --scope storage --depth review --yes --fix-on-layer
```

Use it in CI-style runs where nobody is watching. Read the defaults first — they are the
anti-sprawl ones (recommended/recommended, 5 layers per stack, file-disjoint stacks).

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
| Fix gate shows fewer issues than filed | some were `sweep:blocked` | answer the question on that issue, then re-run |
| Stacked PRs disabled | repo has no Stacked PRs | it asks; approve the plain-PR fallback or stop |
| Nothing happens at all | `/sweep` not in the harness | `./install.sh`, then restart the harness |

## What sweep will not do

- Widen a scope you set.
- File a guess (`confidence: speculative`) unless you asked.
- Open anything to justify the run: a `CLEAN` report ends the cycle.
- Build a stack longer than `--max-layers`, or a second stack touching the same files.
- File a defect in one of its own PRs as a new issue — that goes back onto the layer.
- Merge anything. Opening PRs is where it stops.
