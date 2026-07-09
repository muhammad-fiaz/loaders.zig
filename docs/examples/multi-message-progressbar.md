---
description: Dynamic humor/status message cycling and progress loop using loaders.zig. Showcase of progress bar, spinner, and MultiSpinner with auto-cycling messages and callbacks.
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
//!   3. MultiSpinner with concurrent auto-cycling messages
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
        const humor_msgs = [_]loaders.Message{
            .{ .text = "Reticulating splines...", .icon = "⚙️" },
            .{ .text = "Locating the floppy drive...", .icon = "💾" },
            .{ .text = "Feeding the hamsters...", .icon = "🐹" },
            .{ .text = "Brewing coffee...", .icon = "☕" },
            .{ .text = "Calibrating flux capacitor...", .icon = "⚡" },
        };

        const cb_struct = struct {
            pub fn onProgress(bar: *loaders.Bar, completed: usize, total: usize) void {
                _ = bar;
                _ = completed;
                _ = total;
            }
            pub fn onComplete(bar: *loaders.Bar) void {
                _ = bar;
                std.debug.print(" -> Progress completed callback fired!\n", .{});
            }
        };

        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .label = "Processing",
            .icon_messages = &humor_msgs,
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
        const spinner_msgs = [_]loaders.Message{
            .{ .text = "Searching for wifi...", .icon = "📡" },
            .{ .text = "Loading more RAM...", .icon = "💾" },
            .{ .text = "Asking the rubber duck...", .icon = "🦆" },
            .{ .text = "Cleaning up compiler errors...", .icon = "🧹" },
        };
        const sp = try loaders.Spinner.start(io, .{
            .text = "Starting...",
            .style = loaders.SpinnerStyle.progress_pie, // Use new progress_pie style!
            .icon_messages = &spinner_msgs,
            .message_interval_ms = 500,
            .allocator = allocator,
        });
        errdefer sp.stop(io);

        try io.sleep(std.Io.Duration.fromMilliseconds(2500), .awake);
        sp.succeed(io, "Ready!");
        std.debug.print("\n", .{});
    }

    // 3. MultiSpinner cycling humorous messages
    {
        std.debug.print("3. Multi-Spinner with concurrent message cycling:\n", .{});
        const ms = try loaders.MultiSpinner.start(io, std.Io.File.stderr(), .{ .allocator = allocator });
        errdefer ms.stop();

        const task1 = ms.addItem("Worker 1", loaders.SpinnerStyle.bounce_dots); // Use new bounce_dots style!
        const t1_msgs = [_]loaders.Message{
            .{ .text = "Computing digit 120,490 of Pi...", .icon = "🧮" },
            .{ .text = "Generating excuses...", .icon = "😅" },
            .{ .text = "Resolving pointer confusion...", .icon = "👉" },
        };
        task1.icon_messages = &t1_msgs;
        task1.message_interval_ms = 600;

        const task2 = ms.addItem("Worker 2", loaders.SpinnerStyle.stars); // Use new stars style!
        const t2_msgs = [_]loaders.Message{
            .{ .text = "Analyzing galactic signal...", .icon = "📡" },
            .{ .text = "Warming up lasers...", .icon = "🔫" },
            .{ .text = "Decoding planetary signals...", .icon = "🌌" },
        };
        task2.icon_messages = &t2_msgs;
        task2.message_interval_ms = 800;

        try io.sleep(std.Io.Duration.fromMilliseconds(3000), .awake);
        ms.setSucceeded(task1, "Done computing!");
        ms.setSucceeded(task2, "Decoded successfully!");
        ms.stop();
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
