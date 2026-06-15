---
title: Scroll-Driven Animations (CSS)
type: concept
created: 2026-06-15
updated: 2026-06-15
sources:
  - "[[css-native-parallax-effect]]"
tags:
  - web-development
  - css
  - frontend
---

# Scroll-Driven Animations (CSS)

A CSS feature that drives a keyframe animation's progress from **scroll position** instead of elapsed time, letting effects like parallax run declaratively with no JavaScript scroll listener. Because the work runs off the main thread, it should perform better than the classic per-frame JS recalculation approach. From [[css-native-parallax-effect]].

## Timelines

The animation's clock is swapped from time to a *progress timeline* via the `animation-timeline` property. Two timeline kinds exist; the parallax recipe uses the **view progress timeline**:

- **View progress timeline** — `view-timeline-name: --name` on an element creates a timeline measured by how far that element travels through the scrollport: **0%** as it begins to enter the viewport, **100%** once it has fully left. `view-timeline-axis: block` tracks the block (vertical) axis in normal writing mode.
- A child then sets `animation-timeline: --name` plus `animation: <name> auto linear both` — `auto` duration (supplied by the timeline), `linear` so scroll maps straight onto progress, `both` to hold start/end frames outside the active range.

## Gotcha: `animation-timeline` is not in the shorthand

`animation-timeline` is a **longhand** and is *not* reset by the `animation` shorthand — but the shorthand *does* reset other non-included longhands to their initial values. So `animation-timeline` must be declared **after** the `animation` shorthand, or it will be wiped.

## Parallax application

In [[css-native-parallax-effect]], a single `--parallax-offset` custom property drives both the translate distance (`from { translate: 0 -20% } to { translate: 0 20% }`) and a compensating `scale: calc(1 + var(--parallax-offset, 20) * 2 / 100)`, so the surplus (clipped by `overflow: hidden`) always covers the box and tuning one value never reintroduces empty edges.

## Accessibility

Movement tied to scroll should respect `@media (prefers-reduced-motion: reduce)` — disable the animation (`animation: none`) and reset `scale: 1`.

## See Also
- [[css-native-parallax-effect]]
- [[web-development]]
- [[semantic-html]]
