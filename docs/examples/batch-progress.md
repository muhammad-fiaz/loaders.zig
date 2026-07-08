---
description: BatchBar example for loaders.zig v0.0.3 — grouped multi-task progress bars with state indicators and pipeline-style rendering.
---

# Batch Progress Example

Demonstrates `BatchBar` for tracking multiple named tasks with per-task bars.

**Source:** [`examples/batch_progress.zig`](https://github.com/muhammad-fiaz/loaders.zig/blob/main/examples/batch_progress.zig)

**Run:**
```bash
zig build run-batch_progress
```

## Code

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bb = loaders.BatchBar.init(io, .{
        .title        = "▶  Build Pipeline",
        .title_color  = .bright_magenta,
        .show_percent = true,
        .style        = loaders.BarStyle.slim,
    });

    const compile = bb.addTask("Compile", 80);
    const lint    = bb.addTask("Lint   ", 40);
    const tests   = bb.addTask("Tests  ", 60);
    const link    = bb.addTask("Link   ", 20);

    var i: usize = 0;
    while (!bb.allFinished()) {
        if (i < 80) bb.setTaskCompleted(compile, i + 1);
        if (i < 40) bb.setTaskCompleted(lint, i + 1);
        if (i < 60 and i >= 10) bb.setTaskCompleted(tests, i - 9);
        if (i >= 60 and i < 80) bb.setTaskCompleted(link, i - 59);

        if (i == 39) bb.setTaskDone(lint);
        if (i == 59) bb.setTaskDone(tests);
        if (i == 79) { bb.setTaskDone(compile); bb.setTaskFailed(link); }

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(60), .awake);
        i += 1;
    }

    bb.done();
    std.debug.print(
        "\nPipeline: {d} succeeded, {d} failed\n",
        .{ bb.countByState(.done), bb.countByState(.failed) },
    );
}
```

## What It Shows

| Feature | Detail |
|---------|--------|
| `BatchBar.init` | Title + per-task bar style |
| `addTask` | Named task with total steps |
| `setTaskCompleted` | Atomic progress update |
| `setTaskDone` / `setTaskFailed` | State transitions with ✓/✗ glyphs |
| `allFinished` / `countByState` | Pipeline status query |
