---
name: codebase-cleanup
description: Deep codebase cleanup and code quality improvement using 8 specialized subagents. Use this skill whenever the user wants to clean up their codebase, improve code quality, reduce complexity, remove dead code, fix types, untangle dependencies, or generally whip a project into shape. Triggers include phrases like "clean up my codebase", "improve code quality", "remove dead code", "fix my types", "untangle dependencies", "remove slop", "code hygiene", "tech debt", "refactor", or any request that involves systematically improving an existing codebase across multiple dimensions. Even if the user only mentions one aspect (e.g., "find unused code"), consider whether the full sweep would serve them better and offer it.
---

# Codebase Cleanup

Orchestrate a systematic codebase cleanup by dispatching 8 specialized tasks to subagents in parallel.

## Before You Start

1. **Verify clean git state.** Run `git status`. If the working tree is dirty, ask the user to commit or stash first. Then create a cleanup branch: `git checkout -b cleanup/sweep`.
2. **Detect the stack.** Check the project root for `package.json`, `tsconfig.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc. Note the language, framework, build command, and test command — you'll pass these to each subagent.
3. **Scope check.** If it's a monorepo, ask which packages are in scope.

## Dispatch

Spawn 8 subagents, one per task. Pass each subagent the project root path, language/framework, and build/test commands. Each subagent should create its own git branch from the cleanup branch (e.g., `cleanup/1-dedup`, `cleanup/2-types`, etc.) so their changes don't collide.

Use these prompts verbatim as the task for each subagent:

### Task 1 — Deduplication
> Deduplicate and consolidate all code, and implement DRY where it reduces complexity

### Task 2 — Type Consolidation
> Find all type definitions and consolidate any that should be shared

### Task 3 — Unused Code Removal
> Use tools like knip to find all unused code and remove, ensuring that it's actually not referenced anywhere

### Task 4 — Circular Dependencies
> Untangle any circular dependencies, using tools like madge

### Task 5 — Weak Types
> Remove any weak types, for example 'unknown' and 'any' (and the equivalent in other languages), research what the types should be, research in the codebase and related packages to make sure that the replacements are strong types and there are no type issues

### Task 6 — Defensive Programming Audit
> Remove all try catch and equivalent defensive programming if it doesn't serve a specific role of handling unknown or unsanitized input or otherwise has a reason to be there, with clear error handling and no error hiding or fallback patterns

### Task 7 — Legacy Code Removal
> Find any deprecated, legacy or fallback code, remove, and make sure all code paths are clean, concise and as singular as possible

### Task 8 — AI Slop and Comment Cleanup
> Find any AI slop, stubs, larp, unnecessary comments and remove. Any comments that describe in-motion work, replacements of previous work with new work, or otherwise are not helpful should be either removed or replaced with helpful comments for a new user trying to understand the codebase-- but if you do edit, be concise

## After All Tasks Complete

1. **Merge task branches.** Merge each task branch into the cleanup branch one at a time, resolving conflicts as they arise. A sensible merge order: unused code removal (3) first since it shrinks the codebase, then type consolidation (2), dedup (1), circular deps (4), weak types (5), defensive programming (6), legacy removal (7), and slop cleanup (8) last.
2. **Verify the build.** Run the build command. Fix anything that broke.
3. **Run the tests.** Investigate failures — some may be legitimate (tests covering removed dead code) vs. accidental breakage.
4. **Summary.** For each task, report what was found, what changed, and any items intentionally left alone. Run `git diff --stat cleanup/sweep..HEAD` for the overall impact.

## If Subagents Aren't Available

Run the 8 tasks sequentially in the order listed. Work on the same branch — no need for per-task branches when running serially. Verify the build compiles after each task before moving to the next.
