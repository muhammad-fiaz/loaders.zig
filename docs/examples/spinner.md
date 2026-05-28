---
description: Three animated spinners (dots, line, moon) with mid-run text updates and finish states in loaders.zig.
head:
  - - meta
    - name: keywords
      content: loaders.zig spinner example, zig terminal spinner, dots spinner, background thread spinner
  - - meta
    - property: og:title
      content: Spinner Example — loaders.zig
  - - meta
    - property: og:description
      content: Three animated spinners with text updates and finish states.
---

# Spinner

Three spinners with different styles, mid-run text updates, and finish states (succeed, warn, info).

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 1. Dots spinner
    {
        const sp = try loaders.Spinner.start(io, .{
            .text = "Initializing system...",
            .style = loaders.SpinnerStyle.dots,
            .allocator = allocator,
        });
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.setText("Loading plugins...");
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.succeed(io, "System initialized successfully!");
    }

    // 2. Line spinner
    {
        const sp = try loaders.Spinner.start(io, .{
            .text = "Downloading assets...",
            .style = loaders.SpinnerStyle.line,
            .allocator = allocator,
        });
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.setText("Unpacking assets...");
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.warn(io, "Assets unpacked with warnings.");
    }

    // 3. Moon spinner
    {
        const sp = try loaders.Spinner.start(io, .{
            .text = "Synchronizing database...",
            .style = loaders.SpinnerStyle.moon,
            .allocator = allocator,
        });
        try io.sleep(std.Io.Duration.fromSeconds(2), .awake);
        sp.info(io, "Database synchronized.");
    }
}
```

## Run

```bash
zig build run-spinner
```

## Output

```
⠹ Loading plugins...
✓ System initialized successfully!
- Unpacking assets...
⚠ Assets unpacked with warnings.
🌕 Synchronizing database...
ℹ Database synchronized.
```

Each spinner runs on a background thread and animates independently.
