const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    loaders.hideCursor(io);

    var sp = try loaders.Spinner.init(allocator, io, .{
        .frames = &.{ "⠈", "⠐", "⠠", "⢀", "⡀", "⠄", "⠂", "⠁" },
        .template = "{frame} {text}",
        .text = "Checking credentials",
        .color = loaders.fg(.{ .ansi4 = .yellow }),
    });
    defer sp.deinit();

    try sp.start();

    // Simulate authentication
    loaders.sleepMs(io, 2000);

    // Show success
    sp.stop(.{
        .final_text = "Authenticated!",
        .newline = true,
    });
    loaders.showCursor(io);
}
