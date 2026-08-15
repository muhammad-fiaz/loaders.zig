---
layout: home

title:  High-Performance Terminal Progress Bars & Spinners for Zig
description: High-performance progress bars, spinners, multi-progress, batch runner, and step sequences for Zig. Uses tint.zig for color support. Fully customizable, cross-platform.

head:
  - - meta
    - name: keywords
      content: zig, progress bar, spinner, terminal ui, cli, multi progress, batch runner, step sequence, zig library, zig package, loading animation, terminal progress, tint.zig, color
  - - meta
    - property: og:title
      content: High-Performance Terminal Progress Bars & Spinners for Zig
  - - meta
    - property: og:description
      content: High-performance progress bars, spinners, multi-progress, batch runner, and step sequences for Zig. Uses tint.zig for color support. Fully customizable, cross-platform.
  - - meta
    - property: og:image
      content: /loaders.zig/logo.png
  - - meta
    - name: twitter:title
      content:  Terminal Progress Bars & Spinners for Zig
  - - meta
    - name: twitter:description
      content: High-performance progress bars, spinners, multi-progress, batch runner, and step sequences for Zig. Uses tint.zig for color support. Fully customizable, cross-platform.
  - - meta
    - name: twitter:image
      content: /loaders.zig/logo.png
  - - meta
    - name: twitter:card
      content: summary_large_image

hero:
  name: "loaders.zig"
  text: "Terminal Progress Bars & Spinners for Zig"
  tagline: High-performance progress bars, spinners, multi-progress, batch runner, and step sequences for Zig CLI applications. Uses tint.zig for color support. Fully customizable, cross-platform.
  image:
    src: /loader-thumbnail.png
    alt: loaders.zig terminal progress bars and spinners preview
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
    details: Animated progress bars with percentage, count, ETA, elapsed time, and rate display. Fully customizable fill/empty/head/bracket characters.
  - icon: <span class="vp-code">⠋</span>
    title: Spinners
    details: Animated spinners with any frame sequence (Braille, emoji, ASCII). Background-threaded mode with non-blocking updates.
  - icon: <span class="vp-code">▓░▒</span>
    title: Multi-Progress
    details: Render multiple concurrent progress bars or spinners with sequential or parallel modes.
  - icon: <span class="vp-code">⚡</span>
    title: Batch Runner
    details: Process items with per-item and overall progress bars. Sequential or parallel execution with error tracking.
  - icon: <span class="vp-code">→</span>
    title: Step Sequences
    details: Ordered multi-step pipelines, each backed by a spinner or progress bar, with success/failure/skip states.
  - icon: <span class="vp-code">🎨</span>
    title: Color
    details: Uses tint.zig for color support — RGB, Hex, ANSI 256, HSL, HSV, CMYK, CSS named colors. Raw ANSI strings also work.
---

## Quick Install

**Stable release** (production):

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.4.tar.gz
```

**Nightly** (latest main):

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
```

## Quick Example

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{bar} {percent}%",
        .text = "Processing",
        .color = loaders.makeHex(0x22C55E).toFg(),
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 30);
    }
    bar.finish(.{ .newline = true });
}
```