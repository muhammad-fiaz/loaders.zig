---
description: Gradient demo for loaders.zig v0.0.3 — multi-color gradient progress bars and spinners with rainbow, fire, ocean, and more.
head:
  - - meta
    - name: keywords
      content: loaders.zig gradient example, rainbow progress bar, multi-color loading
  - - meta
    - property: og:title
      content: Gradient Demo — loaders.zig
  - - meta
    - property: og:description
      content: Multi-color gradient progress bars and spinners demo.
---

# Gradient Demo

This example demonstrates gradient-based multi-color rendering for progress bars and spinners.

## Source Code

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Rainbow gradient bar
    var bar = loaders.ProgressBar.init(io, .{
        .label = "Rainbow",
        .total = 100,
        .show_percent = true,
        .style = .{
            .fill_gradient = loaders.Gradient.rainbow,
        },
    });
    defer bar.done();
    for (0..100) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
```

## Available Gradients

The example showcases all built-in gradient presets:

- **Rainbow** — Full spectrum cycle (red → yellow → green → cyan → blue → magenta)
- **Fire** — Warm fire effect (dark red → orange → yellow → white)
- **Ocean** — Cool ocean tones (deep blue → teal → cyan → light blue)
- **Sunset** — Warm sunset colors (purple → magenta → orange → yellow)
- **Neon** — Bright neon glow (magenta → cyan → green → yellow)
- **Forest** — Natural forest tones (dark green → green → lime → yellow-green)
- **Ice** — Icy cool gradient (white → light blue → blue → deep blue)
- **Pastel** — Soft pastel colors (pink → peach → yellow → mint → sky → lavender)

## Spinner Gradients

Spinners cycle through gradient colors on each animation frame:

```zig
var sp = try loaders.Spinner.start(io, .{
    .text = "Rainbow spinner cycling colors...",
    .style = .{
        .frames = &.{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        .gradient = loaders.Gradient.rainbow,
    },
});
```

## Run

```bash
zig build run-gradient_demo
```
