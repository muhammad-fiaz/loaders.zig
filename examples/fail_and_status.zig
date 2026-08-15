const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "Upload",
    });
    defer bar.deinit();

    bar.start() catch {};

    var i: u64 = 0;
    while (i <= 60) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 20);
    }
    bar.fail("connection lost");

    const status = bar.getStatus();
    var buf: [64]u8 = undefined;
    const name = std.fmt.bufPrint(&buf, "Status after fail: {s}\n", .{@tagName(status)}) catch return;
    const w = loaders.stdoutWriter(io);
    w.writeAll(name) catch {};
    loaders.showCursor(io);
}