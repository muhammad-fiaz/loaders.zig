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
    const idxSp = try mb.addSpinner(.{
        .frames = &.{ "|", "/", "-", "\\" },
        .template = "{frame} Task C running",
    });

    try mb.run();

    const barA = mb.getBar(idxA);
    const barB = mb.getBar(idxB);
    const sp = mb.getSpinner(idxSp);

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        barA.setProgress(i);
        barB.setProgress(i);
        loaders.sleepMs(io, 20);
        sp.tickFrame();
    }
    mb.finishAll(.{ .newline = true });
    loaders.showCursor(io);
}
