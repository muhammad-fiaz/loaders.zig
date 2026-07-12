---
description: Outer and inner batch progress bars using BatchBar. Simulates 5 batches of 20 items each.
head:
  - - meta
    - name: keywords
      content: loaders.zig nested bars, zig multi progress, batch progress, zig outer inner bar
  - - meta
    - property: og:title
      content: Nested Bars Example — loaders.zig
  - - meta
    - property: og:description
      content: Outer and inner batch progress bars using BatchBar.
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

    var bb = loaders.BatchBar.init(io, .{
        .tasks = &.{
            .{ .name = "Total Batches", .total = 5, .color = .yellow },
            .{ .name = "Current Batch", .total = 20, .color = .green },
        },
    });

    bb.render();

    for (0..5) |batch| {
        bb.setCompleted(1, 0);
        for (0..20) |item| {
            bb.setCompleted(1, item + 1);
            bb.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
        }
        bb.setCompleted(0, batch + 1);
        bb.render();
    }

    bb.done();
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
