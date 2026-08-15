const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    const green = loaders.makeHex(0x22C55E);

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "█", .empty = "░" },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "HEX green",
        .color = green.toFg(),
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
