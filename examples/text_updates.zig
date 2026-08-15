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
        .template = "{prefix} {bar} {percent}% {suffix}",
        .prefix = "Update",
    });
    defer bar.deinit();

    const phases = [_][]const u8{ "reading", "parsing", "compiling", "linking" };

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setText(phases[@intCast((i / 25) % phases.len)]);
        bar.setSuffix(phases[@intCast((i / 25) % phases.len)]);
        bar.setProgress(i);
        loaders.sleepMs(io, 25);
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}
