const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var mb = try loaders.MultiBar.init(allocator, io, .{
        .mode = .parallel,
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
    const idx_sp = try mb.addSpinner(.{
        .frames = &.{ "|", "/", "-", "\\" },
        .template = "{frame} Task C running",
    });

    try mb.run();

    const bar_a = mb.getBar(idx_a);
    const bar_b = mb.getBar(idx_b);
    const sp = mb.getSpinner(idx_sp);

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar_a.setProgress(i);
        bar_b.setProgress(i);
        loaders.sleepMs(io, 20);
        sp.tickFrame();
    }
    mb.finishAll(.{ .newline = true });
    loaders.showCursor(io);
}
