const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    // Start at 60% instead of 0
    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .current = 60,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "Resume",
    });
    defer bar.deinit();

    bar.start() catch {};

    var i: u64 = 60;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
