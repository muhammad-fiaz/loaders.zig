const std = @import("std");
const loaders = @import("loaders");

/// Iterates through the items and updates the progress bar automatically after each step.
fn withProgress(comptime T: type, items: []const T, bar: *loaders.Bar, io: std.Io) void {
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
    bar: *loaders.Bar,
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

    std.debug.print("--- 1. Simple Iterator Integration ---\n", .{});
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Iterator",
            .total = items.len,
            .show_percent = true,
            .show_count = true,
        });
        defer bar.done();

        withProgress(u32, &items, &bar, io);
    }

    std.debug.print("\n--- 2. Callback Iterator Integration ---\n", .{});
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Callback",
            .total = items.len,
            .show_percent = true,
            .show_count = true,
            .style = loaders.BarStyle.cyan,
        });
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
        bar.done();

        std.debug.print("Sum of items processed: {d}\n", .{sum});
    }
}
