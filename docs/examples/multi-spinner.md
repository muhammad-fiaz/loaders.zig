---
description: Five concurrent spinners with per-item colors, different styles, and staggered finish states using BatchBar.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi spinner, zig concurrent spinners, batch bar spinner example
  - - meta
    - property: og:title
      content: Multi Spinner Example — loaders.zig
  - - meta
    - property: og:description
      content: Five concurrent spinners with per-item colors and staggered finish states.
---

# Multi Spinner

5 concurrent spinners with per-item colors and staggered finish states (succeed, fail, warn).

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bb = loaders.BatchBar.init(io, .{
        .tasks = &.{
            .{ .name = "Fetching data from API", .total = 1, .color = .cyan },
            .{ .name = "Parsing JSON response", .total = 1, .color = .bright_yellow },
            .{ .name = "Compiling assets", .total = 1, .color = .{ .rgb = .{ .r = 160, .g = 100, .b = 255 } } },
            .{ .name = "Uploading to CDN", .total = 1, .color = .bright_blue },
            .{ .name = "Running health checks", .total = 1, .color = .green },
        },
    });

    io.sleep(std.Io.Duration.fromMilliseconds(800), .awake) catch {};
    bb.succeed(0, "Data fetched (128 records)");

    io.sleep(std.Io.Duration.fromMilliseconds(600), .awake) catch {};
    bb.succeed(1, "JSON parsed successfully");

    io.sleep(std.Io.Duration.fromMilliseconds(1200), .awake) catch {};
    bb.fail(2, "Compilation failed: missing symbol");

    io.sleep(std.Io.Duration.fromMilliseconds(400), .awake) catch {};
    bb.warn(3, "Upload skipped (CDN unreachable)");

    io.sleep(std.Io.Duration.fromMilliseconds(700), .awake) catch {};
    bb.succeed(4, "All health checks passed");

    io.sleep(std.Io.Duration.fromMilliseconds(200), .awake) catch {};
    bb.done();
}
```

## Run

```bash
zig build run-multi_spinner
```

## Output

```
⠹ Fetching data from API (50 KB/s)
◝ Parsing JSON response
▰▰▰▰▰▰▱▱ Compiling assets
◉ Uploading to CDN
▁▃▅▇▅ Running health checks
✓ Data fetched (128 records)
◝ JSON parsed successfully
✗ Compilation failed: missing symbol
⚠ Upload skipped (CDN unreachable)
✓ All health checks passed
```

Items complete at different times. Each gets a colored status glyph when done.
