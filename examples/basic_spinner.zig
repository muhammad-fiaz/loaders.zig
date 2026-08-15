const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    // Hide cursor during animation
    loaders.hideCursor(io);

    var sp = try loaders.Spinner.init(allocator, io, .{
        .frames = &.{ "|", "/", "-", "\\" },
        .template = "{frame} {text}",
        .text = "Loading",
        .color = loaders.fg(.{ .ansi4 = .blue }),
    });
    defer sp.deinit();

    try sp.start();
    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        loaders.sleepMs(io, 40);
        sp.tickFrame();
    }
    sp.stop(.{ .final_text = "Done!", .newline = true });

    // Show cursor after animation
    loaders.showCursor(io);
}