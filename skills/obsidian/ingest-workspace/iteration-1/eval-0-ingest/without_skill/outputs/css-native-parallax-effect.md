---
title: "CSS-native parallax effect"
type: source
created: 2026-06-15
updated: 2026-06-15
ingested: 2026-06-15
source_file: "[[raw/Clippings/processed/CSS-native parallax effect.md]]"
author: Dan (dan-webnotes.com)
date: 2023-07-21
tags:
  - web-development
  - css
  - frontend
---

# CSS-native parallax effect

## Key Takeaways

- A parallax effect can now be built **entirely in CSS** using [[scroll-driven-animations]], with no JavaScript scroll listeners and no per-frame position recalculation.
- The mechanism is a **view progress timeline** (`view-timeline-name`) bound to an element's travel through the scrollport, with the child's `animation-timeline` swapped from time to that timeline.
- Running off the main thread should improve performance, and the whole effect collapses into a small block of declarative styles applied via a single `.parallax` utility class.
- A single custom property `--parallax-offset` drives **both** the translate distance and the compensating `scale`, so increasing the effect strength automatically grows the cover and never reintroduces empty edges.
- `animation-timeline` is a longhand, **not** part of the `animation` shorthand, and must be declared *after* the shorthand (which resets non-included longhands).
- Respect `prefers-reduced-motion: reduce` by turning off the animation and resetting `scale: 1`.

## Summary

The article shows the historical recipe for parallax — a JavaScript scroll event listener recalculating positions every frame — and replaces it with CSS scroll-driven animation timelines.

**The timeline.** `view-timeline-name: --parallax-tl` on the `.parallax` container creates a view progress timeline measured by how far the element has travelled through the scrollport: 0% as it begins to enter the viewport, 100% once it has fully left. `view-timeline-axis: block` tracks the block (vertical, in normal writing mode) axis. On the child, `animation-timeline: --parallax-tl` swaps the animation's clock from elapsed time to that timeline. The rest of the `animation` line uses `auto` duration (the timeline supplies it), `linear` so scroll maps straight onto movement, and `both` to hold the start/end frames outside the active range. The keyframes translate the child from `0 -20%` to `0 20%` of its own height; because it moves at a different rate than its surroundings, you get the depth illusion.

**Scaling to avoid empty spots.** Because the child translates by up to the offset percentage of its own height in each direction, a same-size child would expose empty strips. The child is scaled up by `calc(1 + var(--parallax-offset, 20) * 2 / 100)` — twice the offset overall — so at the default offset of 20 it renders at 140%, the surplus is clipped by `overflow: hidden` on the container, and there is always enough content to cover the box. Both translate and scale read the same `--parallax-offset`, so tuning a single value keeps coverage correct: `<div class="parallax" style="--parallax-offset: 30;">`.

**Layer promotion.** `will-change: translate` hints the browser to promote the element to its own layer ahead of time.

**Motion preferences.** Under `@media (prefers-reduced-motion: reduce)`, the child's `animation` is set to `none` and `scale` to `1`.

## Entities Mentioned

None notable.

## Concepts

- [[scroll-driven-animations]] — this source is the worked example that motivates the concept page (view/scroll progress timelines, `animation-timeline`).

## Notes

The source's CSS code fences are labelled `md` rather than `css`, likely a clipping artifact. Publication date (2023-07-21) predates broad browser support for scroll-driven animations; the clipping was created 2026-06-02, by which point support is more mainstream. Worth pairing with a `prefers-reduced-motion` accessibility note in any future web-dev guidance.

## See Also
- [[scroll-driven-animations]]
- [[web-development]]
