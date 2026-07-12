//! examples/rate_smoothing.zig — Smooth rate and ETA display showcase.
//!
//! Demonstrates:
//!   1. `smooth_rate = true` with adjustable `smooth_alpha`
//!   2. `unit_is_bytes = true` for byte throughput display
//!   3. Custom `unit` label for non-byte workloads
//!   4. `reset()` to restart timing mid-progress
//!   5. Side-by-side comparison of raw vs. smoothed rates
//!
//! Run: zig build run-rate_smoothing

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Rate Smoothing Demo ---\n\n", .{});

    std.debug.print("1. Byte throughput (smooth_rate = true):\n", .{});
    var bar1 = loaders.ProgressBar.init(io, .{
        .total = 100 * 1024 * 1024,
        .label = "Download",
        .unit_is_bytes = true,
        .show_percent = true,
        .show_elapsed = true,
        .show_eta = true,
        .show_rate = true,
        .smooth_rate = true,
        .smooth_alpha = 0.15,
        .style = loaders.BarStyle.ocean,
        .width = 30,
    });
    defer bar1.done();

    // Simulate variable-speed download
    var downloaded: usize = 0;
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    while (downloaded < 100 * 1024 * 1024) {
        const chunk = rng.intRangeLessThan(usize, 512 * 1024, 3 * 1024 * 1024);
        downloaded = @min(downloaded + chunk, 100 * 1024 * 1024);
        bar1.setCompleted(downloaded);
        bar1.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(80), .awake);
    }

    std.debug.print("\n\n2. Custom unit 'items/s' with reset():\n", .{});
    var bar2 = loaders.ProgressBar.init(io, .{
        .total = 200,
        .label = "Items   ",
        .unit = "items",
        .show_count = true,
        .show_rate = true,
        .show_elapsed = true,
        .smooth_rate = true,
        .smooth_alpha = 0.25,
        .style = loaders.BarStyle.gradient,
        .width = 28,
    });
    defer bar2.done();

    for (0..200) |i| {
        bar2.setCompleted(i + 1);
        bar2.render();
        if (i == 99) {
            // Simulate pause / reset at midpoint
            try io.sleep(std.Io.Duration.fromMilliseconds(300), .awake);
            bar2.reset();
            bar2.setCompleted(0);
        }
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }

    std.debug.print("\n\n3. incrementBy() batch updates:\n", .{});
    var bar3 = loaders.ProgressBar.init(io, .{
        .total = 1000,
        .label = "Records ",
        .unit = "records",
        .show_count = true,
        .show_rate = true,
        .show_eta = true,
        .smooth_rate = true,
        .style = loaders.BarStyle.teal,
        .width = 28,
    });
    defer bar3.done();

    for (0..100) |_| {
        bar3.incrementBy(10);
        bar3.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(40), .awake);
    }

    std.debug.print("\n\nRate smoothing demo complete.\n", .{});
}
