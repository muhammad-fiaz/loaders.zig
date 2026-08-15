const std = @import("std");
const loaders = @import("loaders");

fn formatElapsed(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);
}

fn formatEta(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);
}

fn formatSpeed(per_sec: f64, buf: []u8) []const u8 {
    return loaders.formatRate(buf, per_sec);
}

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    loaders.hideCursor(io);

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .width = 40,
        .style = .{
            .filled = "=",
            .empty = " ",
            .head = ">",
            .left_bracket = "[",
            .right_bracket = "]",
        },
        .template = "{bar} {percent}% | Elapsed: {elapsed} ETA: {eta} | {speed}",
        .color = loaders.fg(.{ .ansi4 = .green }),
        .formatters = .{
            .elapsed = formatElapsed,
            .eta = formatEta,
            .speed = formatSpeed,
        },
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 50);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
