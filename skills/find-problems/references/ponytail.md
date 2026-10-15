# Ponytail ruleset (vendored)

A slim, pinned subset of **Ponytail 4.9.0 — "lazy senior dev mode"** by Dietrich Gebert
(MIT License, Copyright (c) 2026 DietrichGebert; full text in `ponytail.LICENSE` beside this
file). Vendored so every scanning subagent operates under the same lens even in harnesses
where the Ponytail plugin is not installed.

Prefer the installed Ponytail commands when they are present (`/ponytail`, `/ponytail-review`,
`/ponytail-audit`, `/ponytail-debt`); this file is the canonical fallback and the exact text
the subagents are given. Upstream may drift — re-vendor when it changes.

## The ladder

Stop at the first rung that holds, **after** understanding the problem:

1. Does this need to exist at all? (YAGNI)
2. Already in this codebase? Reuse the helper, util, type, or pattern.
3. Does the standard library do it? Use it.
4. Does a native platform feature cover it? Use it.
5. Does an already-installed dependency solve it? Use it.
6. Can it be one line? Make it one line.
7. Only then: the minimum code that works.

The ladder runs after you understand the problem, not instead of it — read the task and the
code it touches, trace the real flow end to end, then climb.

**Bug fix = root cause, not symptom.** A report names a symptom. Grep every caller of the
function you touch and fix the shared function once — one guard there is a smaller diff than
one per caller, and patching only the path the ticket names leaves sibling callers broken.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one
  product, no config for a value that never changes.
- No new dependency if it can be avoided. No boilerplate nobody asked for.
- Deletion over addition. Boring over clever. Fewest files possible.
- Shortest working diff wins — but only once you understand the problem. The smallest change
  in the wrong place isn't lazy, it's a second bug.
- Question complex requests; ship the lazy version and name what you skipped.
- Between two same-size stdlib options, take the one correct on edge cases. Lazy means less
  code, not the flimsier algorithm.
- Mark a deliberate simplification that cuts a real corner (global lock, O(n²) scan, naive
  heuristic) with a `ponytail:` comment naming the ceiling and the upgrade path.

## Never lazy about

Understanding the problem; input validation at trust boundaries; error handling that prevents
data loss; security; accessibility; resource cleanup; concurrency correctness; the calibration
real hardware needs. A "leaner" change that removes any of these is itself a defect, not a
simplification.

## Finding tags and formats

Tags: `delete` · `stdlib` · `native` · `yagni` · `shrink`

- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

**Review (a diff or one module)** — one line per finding:

```
L<line>: <tag> <what>. <replacement>.        (or <file>:L<line>: <tag> ...)
```

End with `net: -<N> lines possible.` — or `Lean already. Ship.` when there is nothing to cut.

**Audit (whole repo)** — one line per finding, ranked biggest cut first:

```
<tag> <what to cut>. <replacement>. [path]
```

End with `net: -<N> lines, -<M> deps possible.` — or `Lean already. Ship.`

**Debt (harvest deferred shortcuts)** — grep the repo for the marker (skip `node_modules`,
`.git`, build output):

```
grep -rnE '(#|//) ?ponytail:' .
```

One row per marker, grouped by file:

```
<file>:<line>, <what was simplified>. ceiling: <limit named>. upgrade: <trigger to revisit>.
```

Tag each row `no-trigger` when the comment names no upgrade path (those rot silently). End with
`<N> markers, <M> with no trigger.` — or `No ponytail: debt. Clean ledger.`

The scope of these formats is **complexity only**: correctness bugs, security holes, and
performance are separate findings, routed through the main checklist, not tagged away here.
