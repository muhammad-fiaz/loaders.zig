//! multi_progress.zig — Demonstrates MultiBar in-place rendering.
//!
//! Multiple progress bars render on separate lines and update in-place
//! without scrolling, with support for custom colors and messages.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null, .{
        .hide_cursor = true,
        .complete_message = "All tasks complete!",
    });

    const b1 = mb.addBar(.{
        .label = "Download",
        .total = 100,
        .show_percent = true,
        .show_rate = true,
        .unit_is_bytes = true,
        .style = loaders.BarStyle.cyan,
        .label_color = .cyan,
        .complete_message = "Downloaded",
    });
    const b2 = mb.addBar(.{
        .label = "Extract ",
        .total = 80,
        .show_percent = true,
        .show_elapsed = true,
        .style = loaders.BarStyle.green,
        .label_color = .green,
        .complete_message = "Extracted",
    });
    const b3 = mb.addBar(.{
        .label = "Install  ",
        .total = 60,
        .show_percent = true,
        .show_eta = true,
        .style = loaders.BarStyle.gradient,
        .label_color = .yellow,
        .percent_color = .yellow,
        .complete_message = "Installed",
    });
    const b4 = mb.addBar(.{
        .label = "Verify   ",
        .total = 40,
        .show_percent = true,
        .show_count = true,
        .style = loaders.BarStyle.neon,
        .bracket_color = .magenta,
        .complete_message = "Verified",
    });

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        b1.setCompleted(i + 1);
        if (i < 80) b2.setCompleted(i + 1);
        if (i < 60) b3.setCompleted(i + 1);
        if (i < 40) b4.setCompleted(i + 1);

        if (i < 50) {
            b1.setMessage("downloading...");
        } else {
            b1.setMessage("almost done");
        }

        mb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
    }

    mb.done();
    std.debug.print("\n", .{});
}
