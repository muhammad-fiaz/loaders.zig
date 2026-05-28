---
description: Outer and inner batch progress bars using loaders.zig MultiBar. Simulates 5 batches of 20 items each.
head:
  - - meta
    - name: keywords
      content: loaders.zig nested bars, zig multi progress, batch progress, zig outer inner bar
  - - meta
    - property: og:title
      content: Nested Bars Example — loaders.zig
  - - meta
    - property: og:description
      content: Outer and inner batch progress bars using MultiBar.
---

# Nested Bars

Outer bar tracks batches, inner bar tracks items within each batch.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null, .{});

    const outer_bar = mb.addBar(.{
        .label = "Total Batches",
        .total = 5,
        .style = loaders.BarStyle.yellow,
        .show_percent = true,
        .show_count = true,
    });

    const inner_bar = mb.addBar(.{
        .label = "Current Batch",
        .total = 20,
        .style = loaders.BarStyle.green,
        .show_percent = true,
        .show_count = true,
    });

    mb.render();

    for (0..5) |batch| {
        inner_bar.setCompleted(0);
        for (0..20) |item| {
            inner_bar.setCompleted(item + 1);
            mb.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
        }
        outer_bar.setCompleted(batch + 1);
        mb.render();
    }

    mb.done();
}
```

## Run

```bash
zig build run-nested_bars
```

## Output

```
Total Batches [██████████████████████████████████████████████████] 100% 5/5
Current Batch [██████████████████████████████████████████████████] 100% 20/20
```

The inner bar resets to 0 at the start of each batch while the outer bar advances.
