const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{prefix} {bar} {percent}% | {text}",
        .prefix = "Stage",
        .text = "cold start",
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        if (i < 30) {
            bar.setText("initializing");
            bar.setColor(loaders.fg(.{ .ansi4 = .blue }));
        } else if (i < 60) {
            bar.setText("warming up");
            bar.setColor(loaders.fg(.{ .ansi4 = .yellow }));
        } else if (i < 90) {
            bar.setText("steady state");
            bar.setColor(loaders.fg(.{ .ansi4 = .green }));
        } else {
            bar.setText("finalizing");
            bar.setColor(loaders.fg(.{ .ansi4 = .red }));
        }
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}