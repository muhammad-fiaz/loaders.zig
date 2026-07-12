const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Dynamic Custom Labels Simulation ---\n", .{});

    const total_steps = 100;

    // Custom visual style
    const custom_bar_style = loaders.BarStyle{
        .left_bracket = "▶ [",
        .right_bracket = "]",
        .fill = "=",
        .tip = ">",
        .empty = " ",
        .fill_fg = .cyan,
    };

    var bar = loaders.ProgressBar.init(io, .{
        .total = total_steps,
        .style = custom_bar_style,
        .show_percent = true,
        .show_count = true,
    });
    defer bar.done();

    // 5 Phases: "Planning", "Analyzing", "Downloading", "Installing", "Verifying"
    const phases = [_][]const u8{
        "Planning",
        "Analyzing",
        "Downloading",
        "Installing",
        "Verifying",
    };

    for (0..total_steps) |i| {
        bar.setCompleted(i + 1);

        // Track a phase counter that changes based on pos / (len / 5)
        const phase_idx = @min(i / (total_steps / 5), 4);
        const phase_name = phases[phase_idx];

        // Update the label dynamically!
        bar.opts.label = phase_name;

        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
