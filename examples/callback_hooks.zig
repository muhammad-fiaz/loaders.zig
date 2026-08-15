const std = @import("std");
const loaders = @import("loaders");

var tick_count: u32 = 0;
var finish_count: u32 = 0;
var pause_count: u32 = 0;
var resume_count: u32 = 0;

fn onTick(ctx: ?*anyopaque) void {
    _ = ctx;
    tick_count += 1;
}

fn onFinish(ctx: ?*anyopaque) void {
    _ = ctx;
    finish_count += 1;
}

fn onPause(ctx: ?*anyopaque) void {
    _ = ctx;
    pause_count += 1;
}

fn onResume(ctx: ?*anyopaque) void {
    _ = ctx;
    resume_count += 1;
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
        .on_tick = onTick,
        .on_finish = onFinish,
        .on_pause = onPause,
        .on_resume = onResume,
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
    bar.continue_();
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 15);
    }
    bar.finish(.{ .newline = true });

    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "ticks={d} finishes={d} pauses={d} resumes={d}\n", .{
        tick_count, finish_count, pause_count, resume_count,
    }) catch return;
    const w = loaders.stdoutWriter(io);
    w.writeAll(msg) catch {};
    loaders.showCursor(io);
}