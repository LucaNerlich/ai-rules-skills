---
title: Scroll-driven Animations
type: concept
created: 2026-06-15
updated: 2026-06-15
sources:
  - "[[css-native-parallax-effect]]"
tags:
  - web-development
  - css
  - frontend
  - animation
---

# Scroll-driven Animations

A CSS capability that drives a keyframe animation's progress from **scroll position** instead of elapsed time, letting effects like parallax run declaratively and off the main thread — no JavaScript scroll event listener required. Demonstrated for parallax in [[css-native-parallax-effect]].

## How it works

A scroll-driven animation binds an animation's clock to a **timeline** rather than to seconds:

- **View progress timeline** — `view-timeline-name: --name` on an element creates a timeline whose progress measures how far that element has travelled through the scrollport: 0% as it begins to enter the viewport, 100% once it has fully left. `view-timeline-axis: block` tracks the block (vertical, in normal writing mode) axis. (A related *scroll progress timeline* tracks a scroll container's own scroll position.)
- **Binding the animation** — on the animated element, `animation-timeline: --name` swaps the animation clock from time to the timeline. The `animation` shorthand then uses `auto` duration (the timeline supplies it), `linear` so scroll maps straight onto progress, and `both` to hold the start/end frames outside the active range.
- **Declaration-order gotcha** — `animation-timeline` is **not** part of the `animation` shorthand and must be declared *after* it, because the shorthand resets non-included longhands to their initial value (per [[css-native-parallax-effect]]).

## Parallax application

In the parallax example, the child slides `translate: 0 ±offset%` across the timeline. To prevent the slide from exposing empty space, the child is scaled up (`scale: 1 + offset*2/100`) and the container clips the surplus with `overflow: hidden`. A single `--parallax-offset` custom property drives both translate and scale, so the cover stays correct when the effect is tuned. `will-change: translate` hints layer promotion.

## Accessibility

Movement tied to scrolling should respect motion preferences: under `@media (prefers-reduced-motion: reduce)`, disable the effect (`animation: none; scale: 1`).

## Relationship to the old approach

Replaces the traditional JS scroll-listener pattern (recalculate positions every frame). Advantages: better performance (runs off the main thread) and a small, declarative footprint applied via a single utility class. Trade-off: a recent feature with progressive browser support — treat as progressive enhancement.

## See Also

- [[css-native-parallax-effect]]
- [[web-development]]
- [[semantic-html]]
