---
description: Dynamic ETA, rate, count, and elapsed time display in loaders.zig. Shows fast and slow progress phases.
head:
  - - meta
    - name: keywords
      content: loaders.zig ETA, loaders.zig rate, progress bar time estimate, zig loading rate
  - - meta
    - property: og:title
      content: ETA and Rate Example — loaders.zig
  - - meta
    - property: og:description
      content: Dynamic ETA, rate, count, and elapsed time display.
---

# ETA and Rate

1000-step bar with ETA, rate, count, and elapsed time. Speed changes at the midpoint.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bar = loaders.Bar.init(io, .{
        .label = "Processing",
        .total = 1000,
        .show_percent = true,
        .show_count = true,
        .show_rate = true,
        .show_eta = true,
        .show_elapsed = true,
        .style = loaders.BarStyle.green,
    });
    defer bar.done();

    for (0..1000) |i| {
        bar.setCompleted(i + 1);
        bar.render();

        // Fast steps for first 500 (5ms), slow for next 500 (50ms)
        const delay: u64 = if (i < 500) 5 else 50;
        try io.sleep(std.Io.Duration.fromMilliseconds(@intCast(delay)), .awake);
    }
}
```

## Run

```bash
zig build run-eta_and_rate
```

## Output

```
Processing [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░]  90% 900/1000 00:14 ETA 00:01 28.3/s
```

The rate and ETA update dynamically as the delay changes from 5ms (fast) to 50ms (slow) at the 50% mark.
