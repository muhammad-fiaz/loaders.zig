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
        .prefix = "Phase A",
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 50) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 20);
    }
    bar.setStyle(.{ .filled = "=", .empty = " ", .head = ">" });
    bar.setPrefix("Phase B");
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 20);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}