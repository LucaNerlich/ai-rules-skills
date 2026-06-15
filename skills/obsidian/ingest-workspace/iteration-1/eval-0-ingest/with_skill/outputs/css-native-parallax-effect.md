---
title: "CSS-native parallax effect"
type: source
created: 2026-06-15
updated: 2026-06-15
ingested: 2026-06-15
source_file: "[[raw/Clippings/processed/CSS-native parallax effect.md]]"
author:
date: 2023-07-21
tags:
  - web-development
  - css
  - frontend
  - animation
---

# CSS-native parallax effect

A short tutorial (dan-webnotes.com) showing how to build a parallax effect entirely in CSS using [[scroll-driven-animations|scroll-driven animation timelines]], with no JavaScript scroll listener.

## Key Takeaways

- The classic parallax recipe — a JS scroll event listener recalculating positions every frame — can be replaced by a small block of declarative CSS using **scroll-driven animation timelines**.
- A **view progress timeline** (`view-timeline-name` + `view-timeline-axis: block`) measures how far an element has travelled through the scrollport: 0% as it begins entering the viewport, 100% once it has fully left.
- The child element binds its animation to that timeline via `animation-timeline`, with `animation: parallax auto linear both` — `auto` duration (driven by the timeline, not seconds), `linear` mapping, `both` to hold start/end frames.
- `animation-timeline` is **not** part of the `animation` shorthand and must be declared *after* it (the shorthand resets non-included longhands to their initial value).
- A single `--parallax-offset` custom property drives both the `translate` keyframes (±offset% of the child's height) and the `scale` (`1 + offset * 2 / 100`). Scaling the child up gives it surplus content to slide into so no empty strip is exposed; `overflow: hidden` on the container clips the surplus. One value to tune.
- `will-change: translate` hints the browser to promote the element to its own layer.
- Respect `prefers-reduced-motion: reduce` by setting `animation: none; scale: 1` for the child.

## Summary

Parallax (foreground/background moving at different rates to suggest depth) was historically done with a JavaScript scroll listener nudging element positions on every frame. CSS **scroll-driven animations** move this work off the main thread and reduce it to a declarative utility class.

The mechanism is a *view progress timeline*: `view-timeline-name: --parallax-tl` on the container creates a timeline whose progress equals the element's travel through the scrollport, and `view-timeline-axis: block` tracks the vertical (block) axis. The child's `animation-timeline: --parallax-tl` swaps its clock from elapsed time to scroll progress. The `@keyframes` slide the child from `translate: 0 -offset%` to `translate: 0 offset%`.

To avoid exposing empty space at the travel extremes, the child is scaled up by `1 + offset*2/100` (140% at the default offset of 20), with the surplus clipped by the container's `overflow: hidden`. Because both translate and scale read the same `--parallax-offset`, turning the effect up keeps the cover correct automatically.

## Entities Mentioned

- None notable (single-author personal blog post; author not credited in the clipping).

## Concepts

- [[scroll-driven-animations]] — this source is a worked example of the CSS feature.

## Notes

- Published 2023-07-21; clipped 2026-06-02. Scroll-driven animations are a relatively recent CSS feature with progressive browser support — feature-detect or treat the effect as progressive enhancement.
- Caveat reproduced from the source: `animation-timeline` must be declared after the `animation` shorthand or the shorthand will reset it.

## See Also

- [[scroll-driven-animations]]
- [[web-development]]
