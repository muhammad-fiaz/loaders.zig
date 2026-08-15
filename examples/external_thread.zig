const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "=", .empty = " " },
        .template = "{prefix} {bar} {percent}%",
        .prefix = "External",
    });
    defer bar.deinit();

    const thread = std.Thread.spawn(.{}, struct {
        fn run(b: *loaders.ProgressBar, io_ref: std.Io) void {
            var j: u64 = 0;
            while (j <= 100) : (j += 1) {
                b.setProgress(j);
                loaders.sleepMs(io_ref, 30);
            }
        }
    }.run, .{ &bar, io }) catch return;

    thread.join();
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}