//! examples/advanced_options.zig — Advanced progress customization showcase.
//!
//! Demonstrates:
//!   1. Custom start/end line decorators (.custom_start, .custom_end)
//!   2. Local Date & Time prefixing (.show_date, .show_time, .timezone_offset_sec)
//!   3. Responsive auto-resizing (.width = 0)
//!   4. message, complete_message
//!   5. Two sequential asynchronous-like process/task progress bars.
//!
//! Run: zig build run-advanced_options

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Advanced Progress Customization Showcase ---\n\n", .{});
    std.debug.print("Try resizing your terminal window while this progress bar runs!\n\n", .{});

    const total_steps = 100;

    // 1. Task #1 (Processing System Core Engine)
    {
        var bar = loaders.ProgressBar.init(io, .{
            .total = total_steps,
            .label = "Processing System Core Engine",
            .show_percent = true,
            .show_count = true,
            .show_elapsed = true,
            .show_eta = true,
            .show_rate = true,
            .message = "fetching dependencies from CDN...",
            .complete_message = "Done! All steps complete.",

            .show_date = true,
            .show_time = true,
            .time_format_12h = true, // 12-hour AM/PM format
            .timezone_offset_sec = 19800, // UTC+5:30 offset

            // Explicit width constraints for safety
            .max_label_width = 15, // Truncates label to 15 cols with "…"
            .max_message_width = 20, // Truncates message to 20 cols with "…"
            .max_suffix_width = 10, // Truncates suffix to 10 cols with "…"
            .suffix = "Version 1.0.0 Alpha Build",

            .width = 0, // Responsive auto-resizing
            .style = loaders.BarStyle.gradient,
        });

        for (0..total_steps) |i| {
            bar.setCompleted(i + 1);
            if (i == 40) {
                bar.setMessage("unpacking compressed archives...");
            } else if (i == 80) {
                bar.setMessage("compiling target artifacts...");
            }
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
        bar.done();
        std.debug.print("\n", .{});
    }

    // 2. Task #2 (Processing System Security Engine)
    {
        var bar = loaders.ProgressBar.init(io, .{
            .total = total_steps,
            .label = "Processing System Security Engine",
            .show_percent = true,
            .show_count = true,
            .show_elapsed = true,
            .show_eta = true,
            .show_rate = true,
            .message = "scanning vulnerabilities...",
            .complete_message = "Done! Security audit passed.",

            .show_date = true,
            .show_time = true,
            .time_format_12h = true, // 12-hour AM/PM format
            .timezone_offset_sec = 19800, // UTC+5:30 offset

            // Explicit width constraints for safety
            .max_label_width = 15,
            .max_message_width = 20,
            .max_suffix_width = 10,
            .suffix = "Security Patch v1.2",

            .width = 0, // Responsive auto-resizing
            .style = loaders.BarStyle.gradient,
        });

        for (0..total_steps) |i| {
            bar.setCompleted(i + 1);
            if (i == 30) {
                bar.setMessage("analyzing firewall logs...");
            } else if (i == 70) {
                bar.setMessage("signing security tokens...");
            }
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
        bar.done();
        std.debug.print("\n", .{});
    }

    std.debug.print("All tasks finalized.\n", .{});
}
