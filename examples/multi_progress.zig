//! multi_progress.zig — Demonstrates BatchBar with multiple concurrent tasks.
//!
//! All task colors and settings are configured inline in the BatchBar.init call.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bb = loaders.BatchBar.init(io, .{
        .title = "▶  Concurrent Tasks",
        .hide_cursor = true,
        .show_percent = true,
        .show_count = false,
        .style = loaders.BarStyle.slim,
        .tasks = &.{
            .{ .name = "Download ", .total = 100, .color = .cyan },
            .{ .name = "Extract  ", .total = 80, .color = .green },
            .{ .name = "Install  ", .total = 60, .color = .yellow },
            .{ .name = "Verify   ", .total = 40, .color = .magenta },
        },
    });

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        bb.setTaskCompleted(0, i + 1);
        if (i < 80) bb.setTaskCompleted(1, i + 1);
        if (i < 60) bb.setTaskCompleted(2, i + 1);
        if (i < 40) bb.setTaskCompleted(3, i + 1);

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
    }

    bb.done();
    std.debug.print("\n", .{});
}
