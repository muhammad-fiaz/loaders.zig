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
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 200,
        .style = .{ .filled = "=", .empty = " ", .head = ">" },
        .template = "{bar} {percent}% | Elapsed: {elapsed} ETA: {eta} | {speed}",
        .width = 30,
        .formatters = .{
            .elapsed = formatElapsed,
            .eta = formatEta,
            .speed = formatSpeed,
        },
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 200) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 40);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
