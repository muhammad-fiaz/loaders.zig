const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Running Nested Bars Simulation ---\n", .{});

    var bb = loaders.BatchBar.init(io, .{
        .title = "▶  Batch Progress",
        .show_percent = true,
        .show_count = true,
        .tasks = &.{
            .{ .name = "Total Batches", .total = 5, .color = .yellow },
            .{ .name = "Current Batch", .total = 20, .color = .green },
        },
    });

    for (0..5) |batch| {
        bb.setTaskCompleted(1, 0);

        for (0..20) |item| {
            bb.setTaskCompleted(1, item + 1);
            bb.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
        }

        bb.setTaskCompleted(0, batch + 1);
        bb.render();
    }

    bb.done();
    std.debug.print("\nAll batches completed successfully!\n", .{});
}
