const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var sp = try loaders.Spinner.init(allocator, io, .{
        .frames = &.{ "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
        .template = "{frame} {text}",
        .text = "waiting forever (stopping after 5s for the example)",
        .interval_ms = 100,
    });
    defer sp.deinit();

    try sp.start();
    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        loaders.sleepMs(io, 100);
    }
    sp.stop(.{ .final_text = "Stopped.", .newline = true });
    loaders.showCursor(io);
}
