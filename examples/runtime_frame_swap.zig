const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var sp = try loaders.Spinner.init(allocator, io, .{
        .frames = &.{ "|", "/", "-", "\\" },
        .template = "{frame} {text}",
        .text = "Working",
    });
    defer sp.deinit();

    try sp.start();
    var i: u32 = 0;
    while (i < 60) : (i += 1) {
        loaders.sleepMs(io, 30);
        if (i == 20) sp.setFrames(&.{ "🔄", "⏳" });
        if (i == 40) sp.setFrames(&.{ "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" });
        sp.tickFrame();
    }
    sp.stop(.{ .final_text = "Frames swapped!", .newline = true });
    loaders.showCursor(io);
}