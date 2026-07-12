---
description: Dynamic humor/status message cycling and progress loop using loaders.zig. Showcase of progress bar, spinner, and BatchBar with auto-cycling messages and callbacks.
head:
  - - meta
    - name: keywords
      content: loaders.zig dynamic messages, zig loading messages, dynamic message cycling, terminal progress loop, callbacks
  - - meta
    - property: og:title
      content: Multi-Message Progressbar Example — loaders.zig
  - - meta
    - property: og:description
      content: Dynamic humor/status message cycling and progress loop using loaders.zig.
---

# Multi-Message Progressbar

Dynamic humor/status message cycling and progress loop using loaders.zig.

---

## Source

```zig
//! multi_message_progressbar.zig — Dynamic humor/status message cycling.
//!
//! Demonstrates:
//!   1. Progress bar with auto-cycling humorous messages and callbacks
//!   2. Spinner with auto-cycling humorous messages
//!   3. BatchBar with concurrent tasks
//!
//! Run: zig build run-multi_message_progressbar

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== Dynamic Humor & Multi-Message Loader Demo ===\n\n", .{});

    // 1. Single progress bar cycling humor messages and callbacks
    {
        std.debug.print("1. Progress Bar cycling humorous tasks:\n", .{});
        const humor_msgs = [_][]const u8{
            "Reticulating splines...",
            "Locating the floppy drive...",
            "Feeding the hamsters...",
            "Brewing coffee...",
            "Calibrating flux capacitor...",
        };

        const cb_struct = struct {
            pub fn onProgress(bar: *loaders.ProgressBar, completed: usize, total: usize) void {
                _ = bar;
                _ = completed;
                _ = total;
            }
            pub fn onComplete(bar: *loaders.ProgressBar) void {
                _ = bar;
                std.debug.print(" -> Progress completed callback fired!\n", .{});
            }
        };

        var bar = loaders.ProgressBar.init(io, .{
            .total = 100,
            .label = "Processing",
            .messages = &humor_msgs,
            .message_interval_ms = 400,
            .width = 30,
            .on_progress = cb_struct.onProgress,
            .on_complete = cb_struct.onComplete,
        });
        defer bar.done();

        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
        bar.succeed("All tasks finalized (successfully!).");
        std.debug.print("\n", .{});
    }

    // 2. Single Spinner cycling humor messages
    {
        std.debug.print("2. Spinner cycling humorous messages:\n", .{});
        const spinner_msgs = [_][]const u8{
            "Searching for wifi...",
            "Loading more RAM...",
            "Asking the rubber duck...",
            "Cleaning up compiler errors...",
        };
        const sp = try loaders.Spinner.start(io, .{
            .text = "Starting...",
            .style = loaders.SpinnerStyle.progress_pie, // Use new progress_pie style!
            .messages = &spinner_msgs,
            .message_interval_ms = 500,
            .allocator = allocator,
        });
        errdefer sp.stop(io);

        try io.sleep(std.Io.Duration.fromMilliseconds(2500), .awake);
        sp.succeed(io, "Ready!");
        std.debug.print("\n", .{});
    }

    // 3. BatchBar concurrent tasks with messages
    {
        std.debug.print("3. BatchBar with concurrent message cycling:\n", .{});
        var bb = loaders.BatchBar.init(io, .{
            .tasks = &.{
                .{ .name = "Worker 1", .total = 1 },
                .{ .name = "Worker 2", .total = 1 },
            },
        });

        try io.sleep(std.Io.Duration.fromMilliseconds(3000), .awake);
        bb.succeed(0, "Done computing!");
        bb.succeed(1, "Decoded successfully!");
        bb.done();
        std.debug.print("\n", .{});
    }
}
```

## Run

```bash
zig build run-multi_message_progressbar
```

## Output

```
=== Dynamic Humor & Multi-Message Loader Demo ===

1. Progress Bar cycling humorous tasks:
 -> Progress completed callback fired!
✓ Processing [██████████████████████████████] 100% All tasks finalized (successfully!).

2. Spinner cycling humorous messages:
 Starting...
✓ Ready!

3. Multi-Spinner with concurrent message cycling:
✓ Done computing!
✓ Decoded successfully!
```
