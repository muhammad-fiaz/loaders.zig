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
        .prefix = "Gradient",
    });
    defer bar.deinit();

    const colors = [_]loaders.Color{
        loaders.makeRgb(255, 0, 0), // red
        loaders.makeRgb(255, 128, 0), // orange
        loaders.makeRgb(255, 255, 0), // yellow
        loaders.makeRgb(0, 255, 0), // green
        loaders.makeRgb(0, 0, 255), // blue
        loaders.makeRgb(128, 0, 255), // purple
    };

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setColor(colors[@intCast((i / 17) % colors.len)].toFg());
        bar.setProgress(i);
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
