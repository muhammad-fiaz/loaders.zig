const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Custom Styled Progress Bar (200 steps) ---\n", .{});

    // We build a custom visual style using our BarStyle struct:
    // - Custom progress chars: fill = "=", tip = ">", empty = "-"
    // - Color: green foreground for the filled portion, bright_black for the empty portion
    // - Bold attribute applied to the entire bar
    const custom_bar_style = loaders.BarStyle{
        .left_bracket = "[",
        .right_bracket = "]",
        .fill = "=",
        .tip = ">",
        .empty = "-",
        .fill_fg = .green,
        .empty_fg = .bright_black,
        .attrs = &.{.bold},
    };

    var bar = loaders.ProgressBar.init(io, .{
        .label = "Customizing",
        .total = 200,
        .style = custom_bar_style,
        .show_percent = true,
        .show_elapsed = true,
        .show_count = true,
    });
    defer bar.done();

    for (0..200) |_| {
        bar.increment();
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(15), .awake);
    }
}
