const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    loaders.hideCursor(io);

    var bar = try loaders.Indeterminate.init(allocator, io, .{
        .width = 40,
        .style = .{
            .filled = ".",
            .head = "<==>",
            .left_bracket = "[",
            .right_bracket = "]",
        },
        .template = "{prefix} {bar}",
        .prefix = "Checking for Updates",
        .color = loaders.fg(.{ .ansi4 = .yellow }),
        .interval_ms = 100,
    });
    defer bar.deinit();

    try bar.start();

    // Simulate a 5-second timeout
    const timeout_ms: u32 = 5000;
    var elapsed: u32 = 0;
    while (elapsed < timeout_ms) : (elapsed += 100) {
        loaders.sleepMs(io, 100);
        bar.tickFrame();
    }

    bar.stop(.{ .final_text = "System is up to date!", .newline = true });
    loaders.showCursor(io);
}
