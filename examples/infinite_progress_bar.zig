const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    // An "infinite" bar: threadMode .auto redraws elapsed time with no
    // defined end. The example stops it after 5 seconds.
    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = std.math.maxInt(u64),
        .style = .{ .filled = "█", .empty = "░", .head = "▶" },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "Infinite",
        .threadMode = .auto,
        .intervalMs = 16,
    });
    defer bar.deinit();

    bar.start() catch {};

    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        loaders.sleepMs(io, 50);
    }
    bar.fail("time limit reached");
    loaders.showCursor(io);
}
