---
description: Gallery of 9 built-in bar themes including block, shaded, ascii, minimal, cyan, green, yellow, red, and gradient.
head:
  - - meta
    - name: keywords
      content: loaders.zig themes, zig bar presets gallery, built-in bar styles
  - - meta
    - property: og:title
      content: Themed Bar Example — loaders.zig
  - - meta
    - property: og:description
      content: Gallery of 9 built-in bar themes with full 0-100% animation.
---

# Themed Bar

9 built-in bar themes rendered from 0% to 100%.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const themes = [_]struct { name: []const u8, style: loaders.BarStyle }{
        .{ .name = "Default Block", .style = loaders.BarStyle.block },
        .{ .name = "Shaded Unicode", .style = loaders.BarStyle.shaded },
        .{ .name = "Classic ASCII", .style = loaders.BarStyle.ascii },
        .{ .name = "Minimalist Tip", .style = loaders.BarStyle.minimal },
        .{ .name = "Sleek Cyan", .style = loaders.BarStyle.cyan },
        .{ .name = "Forest Green", .style = loaders.BarStyle.green },
        .{ .name = "Caution Yellow", .style = loaders.BarStyle.yellow },
        .{ .name = "Danger Red", .style = loaders.BarStyle.red },
        .{ .name = "Vibrant Gradient", .style = loaders.BarStyle.gradient },
    };

    inline for (themes) |theme| {
        std.debug.print("\nTheme: {s}\n", .{theme.name});
        var bar = loaders.ProgressBar.init(io, .{
            .label = "Progress",
            .total = 100,
            .style = theme.style,
            .show_percent = true,
            .show_count = true,
        });
        defer bar.done();

        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(10), .awake);
        }
    }
}
```

## Run

```bash
zig build run-themed_bar
```

## Output

```
Theme: Default Block
Progress [██████████████████████████████████████████████████████] 100% 100/100

Theme: Shaded Unicode
Progress [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒] 100% 100/100

Theme: Classic ASCII
Progress [##################################################] 100% 100/100

Theme: Minimalist Tip
──────────────────────────────────────────────────────▶── 100% 100/100

Theme: Sleek Cyan
Progress [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒] 100% 100/100

Theme: Forest Green
Progress [██████████████████████████████████████████████████████] 100% 100/100

Theme: Caution Yellow
Progress [██████████████████████████████████████████████████████] 100% 100/100

Theme: Danger Red
Progress [██████████████████████████████████████████████████████] 100% 100/100

Theme: Vibrant Gradient
Progress [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒] 100% 100/100
```
