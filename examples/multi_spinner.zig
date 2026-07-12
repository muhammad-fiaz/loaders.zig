//! multi_spinner.zig — Demonstrates BatchBar with staggered task completion.
//!
//! Five concurrent tasks with different styles and staggered finish states.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Multi-Task Spinner Demo ---\n", .{});

    var bb = loaders.BatchBar.init(io, .{
        .title = "▶  Processing Items",
        .show_percent = true,
        .show_count = true,
        .style = loaders.BarStyle.dots,
        .tasks = &.{
            .{ .name = "Fetching data from API    ", .total = 100, .color = .cyan },
            .{ .name = "Parsing JSON response     ", .total = 100, .color = .bright_yellow },
            .{ .name = "Compiling assets          ", .total = 100, .color = .{ .rgb = .{ .r = 160, .g = 100, .b = 255 } } },
            .{ .name = "Uploading to CDN          ", .total = 100, .color = .bright_blue },
            .{ .name = "Running health checks     ", .total = 100, .color = .green },
        },
    });

    for (0..100) |i| {
        bb.setTaskCompleted(0, i + 1);
        if (i < 80) bb.setTaskCompleted(1, i + 1);
        if (i < 60) bb.setTaskCompleted(2, i + 1);
        if (i < 40) bb.setTaskCompleted(3, i + 1);
        if (i < 90) bb.setTaskCompleted(4, i + 1);

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }

    bb.setTaskDone(0);
    bb.setTaskDone(1);
    bb.setTaskFailed(2);
    bb.setTaskWarning(3);
    bb.setTaskDone(4);

    bb.done();
    std.debug.print("\nFinished.\n", .{});
}
