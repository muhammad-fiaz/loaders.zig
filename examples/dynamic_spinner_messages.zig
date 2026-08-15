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
        .text = "starting",
    });
    defer sp.deinit();

    const messages = [_][]const u8{
        "reading config", "connecting", "downloading", "installing", "verifying",
    };

    try sp.start();
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        sp.setText(messages[@intCast((i / 20) % messages.len)]);
        loaders.sleepMs(io, 40);
        sp.tickFrame();
    }
    sp.stop(.{ .final_text = "Messages cycled!", .newline = true });
    loaders.showCursor(io);
}
