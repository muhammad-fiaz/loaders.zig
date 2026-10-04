const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var mb = try loaders.MultiBar.init(allocator, io, .{
        .mode = .sequential,
    });
    defer mb.deinit();

    const idxA = try mb.addBar(.{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "Task A: {bar} {percent}%",
    });
    const idxB = try mb.addBar(.{
        .total = 100,
        .style = .{ .filled = "=", .empty = " " },
        .template = "Task B: {bar} {percent}%",
    });

    try mb.run();

    const barA = mb.getBar(idxA);
    const barB = mb.getBar(idxB);

    var i: u64 = 0;
    while (i < 100) : (i += 1) {
        loaders.sleepMs(io, 20);
        barA.setProgress(i);
        if (i >= 50) barB.setProgress(i - 50);
    }
    barA.finish(.{ .clear = true });
    barB.finish(.{ .clear = true });
    mb.finishAll(.{ .newline = true });
    loaders.showCursor(io);
}
