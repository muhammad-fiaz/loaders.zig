const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    // Hide cursor during animation
    loaders.hideCursor(io);

    var bar = try loaders.Indeterminate.init(allocator, io, .{
        .width = 40,
        .style = .{
            .filled = ".",
            .head = ">",
            .left_bracket = "[",
            .right_bracket = "]",
        },
        .template = "{prefix} {bar}",
        .prefix = "Working",
        .color = loaders.fg(.{ .ansi4 = .magenta }),
        .interval_ms = 40,
    });
    defer bar.deinit();

    try bar.start();
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        loaders.sleepMs(io, 40);
        bar.tickFrame();
    }
    bar.stop(.{ .final_text = "Complete!", .newline = true });

    // Show cursor after animation
    loaders.showCursor(io);
}
