//! examples/advanced_options.zig — Advanced progress customization showcase.
//!
//! Demonstrates:
//!   1. Custom start/end line decorators (.custom_start, .custom_end)
//!   2. Local Date & Time prefixing (.show_date, .show_time, .timezone_offset_sec)
//!   3. Responsive auto-resizing (.width = 0)
//!   4. label_color, percent_color, bracket_color, message, complete_message
//!
//! Run: zig build run-advanced_options

const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    const io = std.io.getStdErr().getIo();

    std.debug.print("--- Advanced Progress Customization Showcase ---\n\n", .{});
    std.debug.print("Try resizing your terminal window while this progress bar runs!\n\n", .{});

    const total_steps = 100;

    var bar = loaders.Bar.init(io, .{
        .total = total_steps,
        .label = "Processing",
        .label_color = .bright_cyan,
        .show_percent = true,
        .percent_color = .bright_green,
        .bracket_color = .bright_black,
        .show_count = true,
        .show_elapsed = true,
        .show_eta = true,
        .show_rate = true,
        .message = "initializing...",
        .complete_message = "Done! All steps complete.",

        .custom_start = "🚀 ",
        .custom_end = " [Task #1]",

        .show_date = false,
        .show_time = true,
        .timezone_offset_sec = 19800,

        .width = 0,
        .style = loaders.BarStyle.gradient,
    });
    defer bar.done();

    for (0..total_steps) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(80), .awake);
    }

    std.debug.print("\nAll tasks finalized.\n", .{});
}
