# Find Problems — practical guide

`SKILL.md` is the normative instruction set. This file is the how-to. If the two disagree,
`SKILL.md` wins.

## Run it

```
/find-problems                         # whole repo
/find-problems directwerk-digital      # one module
/find-problems --scope feed-builder    # a feature term, resolved first
```

It is **read-only**. No edits, no issues, no commits. The output is a report you hand to
`/create-issues`.

## Reading the report

Each finding carries `module`, `location`, `category`, `suggested priority`, `cluster`, `root
cause`, `trigger`, `evidence`, `why it matters`, `blast radius`, `repro / detection`,
`suggested fix`, `effort`, and `confidence`.

The one that matters most is **`cluster`**: findings sharing a key are one root cause and become
one issue. If two modules report the same pattern, they should carry the same key — that is what
stops a cross-cutting bug from being filed three times.

`confidence: speculative` findings are kept in the report so you can see them, and are not filed
unless you opt in. That is a feature, not a gap.

## `CLEAN` is a result

The scan answers "is anything actually wrong here?", not "what can be said about this code?". A
module — or a whole report — can come back `CLEAN`, and that is a success, not a failed scan.

The report says so explicitly:

```
Verdict: CLEAN — nothing to file. Ship.
```

If you see that, there is nothing to hand to `/create-issues`, and `/sweep` stops there. Do not
widen the scope and scan again unless you actually want a different answer.

The bar a finding has to clear: it is a real defect, a security/data/concurrency risk, or
something that measurably removes complexity a reader is already paying for — and you can name
the input or state that triggers it. Everything else is not a finding, including: taste
(naming, formatting, "I'd write it differently"), "could be more generic/extensible", an
abstraction debate, a trivial test gap, doc polish, and a trade-off the code already names with a
`ponytail:` marker (unless the marker names no upgrade trigger, or its ceiling is demonstrably
hit).

## How big a run is

One subagent per module, a handful per wave. Modules come from the build files, not the folder
names — a Gradle subproject or a workspace package is a module; two tiny folders are one module.

A huge repo with a fine-grained module split means a lot of subagents. Narrow with `--scope`
rather than waiting; the report is per-scope anyway.

## The Ponytail lens

Every scan runs in Ponytail mode with the ruleset vendored at
[`references/ponytail.md`](ponytail.md). If the Ponytail plugin is installed, prefer its commands:

| Need | Invoke |
| --- | --- |
| Base mode | `/ponytail full` (`ultra` for maximum deletion) |
| Cross-module complexity audit (over the scope) | `/ponytail-audit` |
| Diff/PR over-engineering review | `/ponytail-review` |
| Harvest deferred `ponytail:` markers | `/ponytail-debt` |

The vendored copy travels with the skill so the lens works in harnesses without the plugin. It is
a pinned subset — do not edit it to "improve" a finding; re-vendor when upstream changes.

## Targeted scans

These run over the scope when one is set, the whole repo otherwise.

- **One diff or PR:** run `/ponytail-review` on the diff and scan only the touched modules.
- **Deferred shortcuts:** `/ponytail-debt` harvests the `ponytail:` markers. A marker is a
  decision, not a finding — only a `no-trigger` one (no upgrade path) or one whose named ceiling
  is demonstrably hit becomes a finding.
- **Cross-module complexity:** `/ponytail-audit` gives the cut list, ranked biggest first —
  better than asking each module subagent for a global view.

Their one-line output becomes regular finding blocks, each pinned to a `path:line`, before the
report is consolidated; subagents never use the Ponytail closing lines (`net: ...`,
`Lean already. Ship.`).

## Troubleshooting

| Symptom | Cause | Do |
| --- | --- | --- |
| "Module is clean" everywhere | scope too narrow, or generated/vendor trees skipped | check what the scope excluded; widen it |
| Same bug reported twice | two subagents invented different `cluster` keys | the consolidate step should unify them — the keys must not be module-prefixed |
| A finding has no `location` | not a finding | it should have been dropped; report it as a skill bug |
| Tons of low-value nits | scan too broad | prefer a scoped run; the report is meant to be high-signal |
| Findings you disagree with | Ponytail prefers deletion | correctness outranks leanness — say so, and the fix step will respect it |

## Handing off

The report ends by telling you the next step: `/create-issues`. You do not need to file it
yourself, and this skill never will.
