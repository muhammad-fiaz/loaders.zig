---
layout: home

title: loaders.zig — High-Performance Terminal Loading Indicators for Zig
description: High-performance, thread-safe progress bars, spinners, and multi-progress UIs for Zig. Zero dependencies, cross-platform, 18+ bar styles, 33 spinner presets.

head:
  - - meta
    - name: keywords
      content: zig, progress bar, spinner, loading indicator, terminal ui, cli, multi progress, zig library, zig package, zig loading animation
  - - meta
    - property: og:title
      content: loaders.zig — High-Performance Terminal Loading Indicators for Zig
  - - meta
    - property: og:description
      content: High-performance, thread-safe progress bars, spinners, and multi-progress UIs for Zig. Zero dependencies, cross-platform.
  - - meta
    - property: og:image
      content: /loaders.zig/loader-thumbnail.png
  - - meta
    - name: twitter:title
      content: loaders.zig — Terminal Loading Indicators for Zig
  - - meta
    - name: twitter:description
      content: High-performance, thread-safe progress bars, spinners, and multi-progress UIs for Zig. Zero dependencies, cross-platform.
  - - meta
    - name: twitter:image
      content: /loaders.zig/loader-thumbnail.png
  - - meta
    - name: twitter:card
      content: summary_large_image

hero:
  name: "loaders.zig"
  text: "Terminal Loading Indicators for Zig"
  tagline: High-performance, thread-safe progress bars, spinners, and multi-progress UIs for Zig CLI applications. Zero external dependencies. Cross-platform.
  image:
    src: /loader-thumbnail.png
    alt: loaders.zig terminal loading indicators preview
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/muhammad-fiaz/loaders.zig

features:
  - icon: <span class="vp-code">█░</span>
    title: Progress Bars
    details: Animated single-bar progress with percentage, ETA, elapsed time, and rate display. Auto-sizes to terminal width. Determinate and indeterminate modes.
  - icon: <span class="vp-code">⠋</span>
    title: Spinners
    details: Background-threaded animated spinners with non-blocking text updates and finish states (succeed, fail, warn, info).
  - icon: <span class="vp-code">▓░▒</span>
    title: Multi-Progress
    details: Render multiple concurrent progress bars or spinners with coordinated cursor-based rendering. Up to 16 bars or spinners simultaneously.
  - icon: <span class="vp-code">█</span>
    title: 18+ Bar Styles
    details: Built-in presets including block, shaded, ascii, minimal, gradient, fire, ice, ocean, neon, arrow, dots, slim, and more.
  - icon: <span class="vp-code">◑</span>
    title: 33 Spinner Presets
    details: dots, moon, clock, braille, pong, weather, snake, hamburger, christmas tree, aesthetic, and many more animations.
  - icon: <span class="vp-code">🎨</span>
    title: ANSI Color Support
    details: Full 16-color, 256-color, and 24-bit RGB true color with automatic suppression for CI, piped output, and NO_COLOR.
---

## Quick Install

**Stable release** (production):

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.1.tar.gz
```

**Nightly** (latest main):

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
```

## Quick Example

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bar = loaders.Bar.init(io, .{
        .label = "Processing",
        .total = 100,
        .show_percent = true,
        .show_elapsed = true,
    });
    defer bar.done();

    for (0..100) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
```
