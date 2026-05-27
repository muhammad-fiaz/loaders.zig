const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Dynamic ETA and Rate Simulation ---\n", .{});

    var bar = loaders.Bar.init(io, .{
        .label = "Processing",
        .total = 1000,
        .show_percent = true,
        .show_count = true,
        .show_rate = true,
        .show_eta = true,
        .show_elapsed = true,
        .style = loaders.BarStyle.green,
    });
    defer bar.done();

    for (0..1000) |i| {
        bar.setCompleted(i + 1);
        bar.render();

        // Fast steps for first 500 (5ms), slow for next 500 (50ms)
        const delay: u64 = if (i < 500) 5 else 50;
        try io.sleep(std.Io.Duration.fromMilliseconds(@intCast(delay)), .awake);
    }
}
