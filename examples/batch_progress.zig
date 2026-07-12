//! examples/batch_progress.zig — BatchBar multi-task progress showcase.
//!
//! Demonstrates:
//!   1. Creating a BatchBar with tasks configured inline
//!   2. Staggered task completion with different states
//!   3. Using countByState / allFinished
//!
//! Run: zig build run-batch_progress

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Batch Progress Demo ---\n\n", .{});

    var bb = loaders.BatchBar.init(io, .{
        .title = "▶  Build Pipeline",
        .title_color = .bright_magenta,
        .show_percent = true,
        .show_count = false,
        .style = loaders.BarStyle.slim,
        .tasks = &.{
            .{ .name = "Compile", .total = 80, .color = .cyan },
            .{ .name = "Lint   ", .total = 40 },
            .{ .name = "Tests  ", .total = 60, .fill_color = .green, .empty_color = .bright_black },
            .{ .name = "Link   ", .total = 20, .color = .bright_magenta },
        },
    });

    var i: usize = 0;
    while (!bb.allFinished()) {
        if (i < 80) bb.setTaskCompleted(0, i + 1);
        if (i < 40) bb.setTaskCompleted(1, i + 1);
        if (i < 60 and i >= 10) bb.setTaskCompleted(2, i - 9);
        if (i >= 60 and i < 80) bb.setTaskCompleted(3, i - 59);

        if (i == 39) bb.setTaskDone(1);
        if (i == 59) bb.setTaskDone(2);
        if (i == 79) {
            bb.setTaskDone(0);
            bb.setTaskFailed(3);
        }

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(60), .awake);
        i += 1;
    }

    bb.done();

    std.debug.print(
        "\nPipeline complete: {d} succeeded, {d} failed\n",
        .{ bb.countByState(.done), bb.countByState(.failed) },
    );
}
