//! examples/batch_progress.zig — BatchBar multi-task progress showcase.
//!
//! Demonstrates:
//!   1. Creating a BatchBar with a title
//!   2. Adding multiple named tasks
//!   3. Incrementing task progress from different "workers"
//!   4. Marking tasks as done or failed
//!   5. Using countByState / allFinished
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
        .icon = "⚙️",
        .icon_gap = "  ",
        .state_gap = "  ",
    });

    const compile = bb.addTask("Compile", 80);
    const lint = bb.addTask("Lint   ", 40);
    const tests = bb.addTask("Tests  ", 60);
    const link = bb.addTask("Link   ", 20);

    // Configure custom task coloring
    bb.tasks[compile].color = .cyan;
    bb.tasks[lint].label_color = .bright_yellow;
    bb.tasks[tests].fill_color = .green;
    bb.tasks[tests].empty_color = .bright_black;
    bb.tasks[link].color = .bright_magenta;

    var i: usize = 0;
    while (!bb.allFinished()) {
        if (i < 80) {
            bb.setTaskCompleted(compile, i + 1);
        }
        if (i < 40) {
            bb.setTaskCompleted(lint, i + 1);
        }
        if (i < 60 and i >= 10) {
            bb.setTaskCompleted(tests, i - 9);
        }
        if (i >= 60 and i < 80) {
            bb.setTaskCompleted(link, i - 59);
        }

        if (i == 39) bb.setTaskDone(lint);
        if (i == 59) bb.setTaskDone(tests);
        if (i == 79) {
            bb.setTaskDone(compile);
            bb.setTaskFailed(link);
        }

        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(60), .awake);
        i += 1;
    }

    bb.done();

    const done_count = bb.countByState(.done);
    const failed_count = bb.countByState(.failed);

    std.debug.print(
        "\nPipeline complete: {d} succeeded, {d} failed\n",
        .{ done_count, failed_count },
    );
}
