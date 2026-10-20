# Ponytail ruleset (vendored)

A slim, pinned subset of **Ponytail 5.3.2 — "lazy senior dev mode"** by Dietrich Gebert
(MIT License, Copyright (c) 2026 DietrichGebert; full text in `ponytail.LICENSE` beside this
file). Vendored so every scanning subagent operates under the same lens even in harnesses
where the Ponytail plugin is not installed.

Prefer the installed Ponytail commands when they are present (`/ponytail`, `/ponytail-review`,
`/ponytail-audit`, `/ponytail-debt`); this file is the canonical fallback and the exact text
the subagents are given. Upstream may drift — re-vendor when it changes.

## Before you write

Read the task and the code it touches. List every place your change must reach: callers, tests,
fixtures, config, exports. Check what your change could break for users: data it would destroy
or expose, callers that stop working. That is scope. Extra features are not.

## The smallest complete change

Take the first option that fully works:

1. Does it need to exist? Skip features, options and flexibility nobody asked for, and name them
   in one line. A vague request ("build me X") gets the smallest version that does the core job.
2. Already in this codebase (a helper, component, service, pattern)? Use it the way the
   surrounding code does.
3. Standard library or a platform feature? Use it, unless the project has its own. A house
   component beats a native widget.
4. An installed dependency? Use it. Never add a dependency for a few lines.
5. Can it be one line a reader gets at a glance? One line.
6. Otherwise: the minimum code that works.

- Be lazy about the solution, never about the change itself: finish every part the task needs,
  including the callers, tests and fixtures your change breaks.
- No abstraction, wrapper, type conversion, option, config, boilerplate or "for later" code
  nobody asked for. Keep values in the form the platform already gives you. Deletion beats
  addition. Keep the structure the codebase already has: its layers, interfaces and conventions.
- The shortest working diff wins, once you know everything it must touch. A one-liner that needs
  decoding is not short.
- Comment only the why the code cannot show, in one line.
- Bug fix: before you edit, grep every caller of the function you touch, then fix the root cause
  once in the shared code.
- Code you move or merge keeps its error handling and validation.
- Between options of equal size, take the one that is correct on edge cases.
- Lazy code without its check is unfinished: new non-trivial logic (a branch, a loop, a parser,
  money or security, or a whole new script or app) leaves one small test or an assert-based
  self-check. Trivial changes need none.
- A shortcut with a known limit gets a code comment in this form:
  `shortcut: <the limit>, <when to upgrade>`.

## Never cut

Validation at trust boundaries, error handling that prevents data loss, security, accessibility,
the calibration real hardware needs, anything the user asked for. A "leaner" change that removes
any of these is itself a defect, not a simplification.

## Lean tags

Use these in a finding's tag or fix field: `delete` · `reuse` · `stdlib` · `native` · `yagni` ·
`merge` · `split`

- `delete:` dead code, unused options, speculative features. Replacement: nothing.
- `reuse:` the repo already has this helper. Name the path.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller.
- `merge:` near-copies that must change together.
- `split:` one function doing several unrelated jobs. Split by job, never by line count, and
  never into helpers that exist only to make a function shorter.

## Finding formats

**Review and audit** — one finding at a time, each with a concrete case: what this is, the
problem (the input or state that reaches it), the smallest fix, and what happens if skipped.
Group findings as `Must fix`, `Should fix`, `Nice to have`; end with a verdict and the lean
savings. Nothing found: `Looks good. Ship.` for a review, `Healthy. Nothing to fix.` for an
audit. Say what you could not check under `Not checked:`.

**Debt** — grep for `shortcut:` markers (older code may say `ponytail:`), skipping `.git` and
ignored/build output:

```sh
git grep --no-index --exclude-standard -nE '(#|//|/[*]) ?(shortcut|ponytail):'
```

One row per marker, grouped by file:

```
<file>:<line>, <what was simplified>. ceiling: <limit named>. upgrade: <trigger to revisit>.
```

Tag a row `no-trigger` when the comment names no upgrade path (those rot silently). End with
`<N> markers, <M> with no trigger.` — or `No shortcut debt. Clean ledger.`

The scope of these formats is **complexity only**: correctness bugs, security holes, and
performance are separate findings, routed through the main checklist, not tagged away here.
