//! 01_basic_bar.zig — Minimal progress bar example.
//!
//! Run: zig build run-basic_bar

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const total: usize = 50;

    var bar = loaders.Bar.init(io, .{
        .label = "Processing",
        .total = total,
        .show_percent = true,
    });
    defer bar.done();

    for (0..total) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(40), .awake);
    }
}
