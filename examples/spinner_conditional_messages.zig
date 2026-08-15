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
        .text = "running",
    });
    defer sp.deinit();

    try sp.start();
    var i: u32 = 0;
    while (i < 120) : (i += 1) {
        if (i < 30) {
            sp.setText("cold start");
            sp.setColor(loaders.fg(.{ .ansi4 = .blue }));
        } else if (i < 60) {
            sp.setText("retrying...");
            sp.setColor(loaders.fg(.{ .ansi4 = .yellow }));
        } else if (i < 90) {
            sp.setText("almost there");
            sp.setColor(loaders.fg(.{ .ansi4 = .green }));
        } else {
            sp.setText("finalizing");
            sp.setColor(loaders.fg(.{ .ansi4 = .cyan }));
        }
        loaders.sleepMs(io, 35);
        sp.tickFrame();
    }
    sp.stop(.{ .final_text = "Conditional done!", .newline = true });
    loaders.showCursor(io);
}