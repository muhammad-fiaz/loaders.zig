const std = @import("std");
const loaders = @import("loaders");

const messages = [_][]const u8{
    "Loading package index...",
    "Fetching metadata...",
    "Resolving dependencies...",
    "Caching artifacts...",
    "Optimizing layout...",
};

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var sp = try loaders.Spinner.init(allocator, io, .{
        .frames = &.{ "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
        .template = "{frame} {text}",
        .text = messages[0],
    });
    defer sp.deinit();

    try sp.start();
    var i: u32 = 0;
    while (i < 150) : (i += 1) {
        sp.setText(messages[@intCast((i / 30) % messages.len)]);
        loaders.sleepMs(io, 30);
        sp.tickFrame();
    }
    sp.stop(.{ .final_text = "Looped!", .newline = true });
    loaders.showCursor(io);
}
