const std = @import("std");
const loaders = @import("loaders");

fn formatElapsed(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);
}

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{bar} {percent}% {elapsed}",
        .formatters = .{ .elapsed = formatElapsed },
    });
    defer bar.deinit();

    bar.start() catch {};

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 15);
        if (i == 50) {
            const s = bar.state();
            var buf: [256]u8 = undefined;
            const line = std.fmt.bufPrint(&buf,
                "\nmid-run state: progress={d} total={d} percent={d:.1} elapsed_ns={d} status={s}\n",
                .{ s.progress, s.total, s.percent, s.elapsed_ns, @tagName(s.status) },
            ) catch return;
            const w = loaders.stdoutWriter(io);
            w.writeAll(line) catch {};
        }
    }
    bar.finish(.{ .newline = true });
    loaders.showCursor(io);
}