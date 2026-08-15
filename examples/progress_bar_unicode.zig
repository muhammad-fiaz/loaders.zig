const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    loaders.hideCursor(io);

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .width = 40,
        .style = .{
            .filled = "█",
            .empty = "░",
            .head = "█",
            .left_bracket = "[",
            .right_bracket = "]",
        },
        .template = "{bar} {percent}%",
        .color = loaders.fg(.{ .ansi4 = .cyan }),
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 30);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
