---
description: Side-by-side comparison of 7 built-in bar styles in loaders.zig. Block, ascii, shaded, green, cyan, gradient, and minimal.
head:
  - - meta
    - name: keywords
      content: loaders.zig bar styles comparison, zig bar presets, progress bar styles
  - - meta
    - property: og:title
      content: Styled Bar Example — loaders.zig
  - - meta
    - property: og:description
      content: Side-by-side comparison of 7 built-in bar styles.
---

# Styled Bar

7 bar styles rendered side by side at 30 columns wide.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const total: usize = 40;

    const styles = [_]struct { name: []const u8, style: loaders.BarStyle }{
        .{ .name = "block   ", .style = .{} },
        .{ .name = "ascii   ", .style = .ascii },
        .{ .name = "shaded  ", .style = .shaded },
        .{ .name = "green   ", .style = .green },
        .{ .name = "cyan    ", .style = .cyan },
        .{ .name = "gradient", .style = .gradient },
        .{ .name = "minimal ", .style = .minimal },
    };

    for (styles) |s| {
        var bar = loaders.Bar.init(io, .{
            .label = s.name,
            .total = total,
            .style = s.style,
            .show_percent = true,
            .width = 30,
        });
        defer bar.done();

        for (0..total) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
    }
}
```

## Run

```bash
zig build run-02_styled_bar
```

## Output

```
block    [██████████████████████████████] 100%
ascii    [##############################] 100%
shaded   [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒] 100%
green    [██████████████████████████████] 100%
cyan     [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒] 100%
gradient [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒] 100%
minimal  ──────────────────────────────▶─ 100%
```

Each style renders at a fixed 30-column width for easy visual comparison.
