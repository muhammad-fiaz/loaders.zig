const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    // Hide cursor during animation
    loaders.hideCursor(io);

    var bar = try loaders.BlockProgressBar.init(allocator, io, .{
        .total = 100,
        .width = 40,
        .template = "Block: {bar} {percent}%",
        .color = loaders.fg(.{ .ansi4 = .cyan }),
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });

    // Show cursor after animation
    loaders.showCursor(io);
}
