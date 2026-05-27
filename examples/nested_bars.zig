const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Running Nested Bars Simulation ---\n", .{});

    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null);

    const outer_bar = mb.addBar(.{
        .label = "Total Batches",
        .total = 5,
        .style = loaders.BarStyle.yellow,
        .show_percent = true,
        .show_count = true,
    });

    const inner_bar = mb.addBar(.{
        .label = "Current Batch",
        .total = 20,
        .style = loaders.BarStyle.green,
        .show_percent = true,
        .show_count = true,
    });

    mb.render();

    for (0..5) |batch| {
        // Reset inner bar for new batch
        inner_bar.setCompleted(0);

        // Simulating work
        for (0..20) |item| {
            inner_bar.setCompleted(item + 1);
            mb.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
        }

        outer_bar.setCompleted(batch + 1);
        mb.render();
    }

    mb.done();
    std.debug.print("\nAll batches completed successfully!\n", .{});
}
