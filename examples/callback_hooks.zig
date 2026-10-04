const std = @import("std");
const loaders = @import("loaders");

var tickCount: u32 = 0;
var finishCount: u32 = 0;
var pauseCount: u32 = 0;
var unpauseCount: u32 = 0;

fn onTick(ctx: ?*anyopaque) void {
    _ = ctx;
    tickCount += 1;
}

fn onFinish(ctx: ?*anyopaque) void {
    _ = ctx;
    finishCount += 1;
}

fn onPause(ctx: ?*anyopaque) void {
    _ = ctx;
    pauseCount += 1;
}

fn onUnpause(ctx: ?*anyopaque) void {
    _ = ctx;
    unpauseCount += 1;
}

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "Hooks",
        .onTick = onTick,
        .onFinish = onFinish,
        .onPause = onPause,
        .onUnpause = onUnpause,
    });
    defer bar.deinit();

    bar.start() catch {};

    var i: u64 = 0;
    while (i <= 30) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 15);
    }
    bar.pause();
    loaders.sleepMs(io, 300);
    bar.unpause();
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 15);
    }
    bar.finish(.{ .newline = true });

    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "ticks={d} finishes={d} pauses={d} resumes={d}\n", .{
        tickCount, finishCount, pauseCount, unpauseCount,
    }) catch return;
    const w = loaders.stdoutWriter(io);
    w.writeAll(msg) catch {};
    loaders.showCursor(io);
}
