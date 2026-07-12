---
description: Progress bar wrapper patterns for iterators and callbacks in loaders.zig. Generic forEach with automatic progress tracking.
head:
  - - meta
    - name: keywords
      content: loaders.zig iterator wrapper, zig progress bar iterator, callback progress
  - - meta
    - property: og:title
      content: Iterator Wrap Example — loaders.zig
  - - meta
    - property: og:description
      content: Progress bar wrapper patterns for iterators and callbacks.
---

# Iterator Wrap

Generic wrappers that integrate progress bars with iterators and callbacks.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

/// Iterates through items and updates the progress bar after each step.
fn withProgress(comptime T: type, items: []const T, bar: *loaders.ProgressBar, io: std.Io) void {
    for (items) |item| {
        _ = item;
        bar.increment();
        bar.render();
        io.sleep(std.Io.Duration.fromMilliseconds(10), .awake) catch {};
    }
}

/// Generic wrapper that executes `cb` for each item and ticks the progress bar.
fn forEachWithProgress(
    comptime T: type,
    items: []const T,
    bar: *loaders.ProgressBar,
    io: std.Io,
    context: anytype,
    comptime cb: fn (context: @TypeOf(context), item: T) void,
) void {
    for (items) |item| {
        cb(context, item);
        bar.increment();
        bar.render();
        io.sleep(std.Io.Duration.fromMilliseconds(15), .awake) catch {};
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const items = [_]u32{ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };

    // 1. Simple iterator
    {
        var bar = loaders.ProgressBar.init(io, .{
            .label = "Iterator",
            .total = items.len,
            .show_percent = true,
            .show_count = true,
        });
        defer bar.done();
        withProgress(u32, &items, &bar, io);
    }

    // 2. Callback iterator
    {
        var bar = loaders.ProgressBar.init(io, .{
            .label = "Callback",
            .total = items.len,
            .show_percent = true,
            .show_count = true,
            .style = loaders.BarStyle.cyan,
        });
        defer bar.done();

        const Context = struct {
            total_sum: *u32,
        };
        var sum: u32 = 0;
        const ctx = Context{ .total_sum = &sum };

        const cb = struct {
            fn run(c: Context, item: u32) void {
                c.total_sum.* += item;
            }
        }.run;

        forEachWithProgress(u32, &items, &bar, io, ctx, cb);
        std.debug.print("Sum of items processed: {d}\n", .{sum});
    }
}
```

## Run

```bash
zig build run-iterator_wrap
```

## Output

```
--- 1. Simple Iterator Integration ---
Iterator [██████████████████████████████████████████████████] 100% 10/10

--- 2. Callback Iterator Integration ---
Callback [██████████████████████████████████████████████████] 100% 10/10
Sum of items processed: 550
```
