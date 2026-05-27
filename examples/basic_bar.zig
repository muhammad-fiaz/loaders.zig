const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // First bar: standard default style
    {
        std.debug.print("--- Standard Progress Bar ---\n", .{});
        var bar = loaders.Bar.init(io, .{
            .label = "Loading",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
        });
        defer bar.done();

        for (0..100) |_| {
            bar.increment();
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(25), .awake);
        }
    }

    // Second bar: unicode themed style
    {
        std.debug.print("\n--- Unicode Styled Progress Bar ---\n", .{});
        var bar = loaders.Bar.init(io, .{
            .label = "Unicode",
            .total = 100,
            .style = loaders.BarStyle.shaded,
            .show_percent = true,
            .show_elapsed = true,
        });
        defer bar.done();

        for (0..100) |_| {
            bar.increment();
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(25), .awake);
        }
    }
}
