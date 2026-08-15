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

    const idx_a = try mb.addBar(.{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "Task A: {bar} {percent}%",
    });
    const idx_b = try mb.addBar(.{
        .total = 100,
        .style = .{ .filled = "=", .empty = " " },
        .template = "Task B: {bar} {percent}%",
    });

    try mb.run();

    const bar_a = mb.getBar(idx_a);
    const bar_b = mb.getBar(idx_b);

    var i: u64 = 0;
    while (i < 100) : (i += 1) {
        loaders.sleepMs(io, 20);
        bar_a.setProgress(i);
        if (i >= 50) bar_b.setProgress(i - 50);
    }
    bar_a.finish(.{ .clear = true });
    bar_b.finish(.{ .clear = true });
    mb.finishAll(.{ .newline = true });
    loaders.showCursor(io);
}