---
description: Standard and unicode-styled progress bars with loaders.zig. Two 100-step bars with elapsed time display.
head:
  - - meta
    - name: keywords
      content: loaders.zig bar styles, zig shaded progress bar, zig unicode bar
  - - meta
    - property: og:title
      content: Basic Bar (100) Example — loaders.zig
  - - meta
    - property: og:description
      content: Standard and unicode-styled progress bars with loaders.zig.
---

# Basic Bar (100)

Two 100-step bars: default style and shaded unicode style with elapsed time.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // First bar: standard default style
    {
        std.debug.print("--- Standard Progress Bar ---\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .label = "Loading",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
        });
        defer bar.done();

        for (0..100) |_| {
            bar.increment();
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(25), .awake);
        }
    }

    // Second bar: unicode themed style
    {
        std.debug.print("\n--- Unicode Styled Progress Bar ---\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .label = "Unicode",
            .total = 100,
            .style = loaders.BarStyle.shaded,
            .show_percent = true,
            .show_elapsed = true,
        });
        defer bar.done();

        for (0..100) |_| {
            bar.increment();
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(25), .awake);
        }
    }
}
```

## Run

```bash
zig build run-basic_bar
```

## Output

```
--- Standard Progress Bar ---
Loading [██████████████████████████████████████████████████████] 100% 00:02

--- Unicode Styled Progress Bar ---
Unicode [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒] 100% 00:02
```
