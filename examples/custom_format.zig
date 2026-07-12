//! examples/custom_format.zig — Custom format template showcase.
//!
//! Demonstrates:
//!   1. Custom format template with {label}, {bar}, {percent}, {elapsed}, {eta}, {rate}
//!   2. Time-stamped prefix via {time} and {date}
//!   3. Dynamic {message} token
//!   4. Spinner-in-bar via {spinner} token
//!
//! Run: zig build run-custom_format

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Custom Format Template Demo ---\n\n", .{});

    std.debug.print("1. Classic rate + ETA layout:\n", .{});
    var bar1 = loaders.ProgressBar.init(io, .{
        .total = 80 * 1024 * 8,
        .label = "Upload",
        .unit_is_bytes = true,
        .show_rate = true,
        .show_eta = true,
        .template = "{label} [{bar}] {percent}  {elapsed} ETA {eta}  {rate}",
        .style = loaders.BarStyle.ocean,
        .fill_color = .{ .rgb = .{ .r = 0, .g = 160, .b = 220 } },
        .width = 30,
    });
    for (0..80) |i| {
        bar1.setCompleted(i * 1024 * 8);
        bar1.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(40), .awake);
    }
    bar1.setCompleted(80 * 1024 * 8);
    bar1.render();
    bar1.done();

    std.debug.print("\n2. Message + spinner prefix:\n", .{});
    const messages = [_][]const u8{
        "reading config...",
        "validating inputs...",
        "computing checksums...",
        "writing output...",
        "finalizing...",
    };
    var bar2 = loaders.ProgressBar.init(io, .{
        .total = 100,
        .template = "{spinner} [{bar}] {count}  {message}",
        .style = loaders.BarStyle.neon,
        .width = 25,
    });
    for (0..100) |i| {
        bar2.setCompleted(i + 1);
        bar2.setMessage(messages[(i / 20) % messages.len]);
        bar2.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
    }
    bar2.done();

    std.debug.print("\n3. Date/time prefix:\n", .{});
    var bar3 = loaders.ProgressBar.init(io, .{
        .total = 50,
        .label = "Indexing",
        .template = "[{date} {time}] {label} [{bar}] {percent}  ETA {eta}",
        .style = loaders.BarStyle.green,
        .width = 20,
    });
    for (0..50) |i| {
        bar3.setCompleted(i + 1);
        bar3.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(60), .awake);
    }
    bar3.done();

    std.debug.print("\nAll templates complete.\n", .{});
}
