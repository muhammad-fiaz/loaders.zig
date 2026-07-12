---
description: Four concurrent progress bars with different styles, dynamic messages, and staggered completion using BatchBar.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi progress, zig concurrent progress bars, batch bar example
  - - meta
    - property: og:title
      content: Multi Progress Example — loaders.zig
  - - meta
    - property: og:description
      content: Four concurrent progress bars with different styles and dynamic messages.
---

# Multi Progress

4 concurrent progress bars with different styles, dynamic messages, and staggered completion.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bb = loaders.BatchBar.init(io, .{
        .title = "All tasks complete!",
        .tasks = &.{
            .{ .name = "Download", .total = 100, .color = .cyan },
            .{ .name = "Extract ", .total = 80, .color = .green },
            .{ .name = "Install  ", .total = 60, .color = .yellow },
            .{ .name = "Verify   ", .total = 40, .color = .magenta },
        },
    });

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        bb.setCompleted(0, i + 1);
        if (i < 80) bb.setCompleted(1, i + 1);
        if (i < 60) bb.setCompleted(2, i + 1);
        if (i < 40) bb.setCompleted(3, i + 1);

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
    }

    bb.done();
}
```

## Run

```bash
zig build run-multi_progress
```

## Output

```
Download [██████████████████████████████████████████████████] 100% 1.0MiB/s Downloaded
Extract  [████████████████████████████████████████████████░░] 100% 00:08 Extracted
Install  [██████████████████████████████████████████████████] 100% ETA 00:00 Installed
Verify   [██████████████████████████████████████████████████] 100% 40/40 Verified
All tasks complete!
```

Bars complete at different rates (100, 80, 60, 40 steps). Dynamic message switches at 50%.
