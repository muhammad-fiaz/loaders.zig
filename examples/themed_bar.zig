const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Visual Theme Gallery ---\n", .{});

    const themes = [_]struct { name: []const u8, style: loaders.BarStyle }{
        .{ .name = "Default Block", .style = loaders.BarStyle.block },
        .{ .name = "Shaded Unicode", .style = loaders.BarStyle.shaded },
        .{ .name = "Classic ASCII", .style = loaders.BarStyle.ascii },
        .{ .name = "Minimalist Tip", .style = loaders.BarStyle.minimal },
        .{ .name = "Sleek Cyan", .style = loaders.BarStyle.cyan },
        .{ .name = "Forest Green", .style = loaders.BarStyle.green },
        .{ .name = "Caution Yellow", .style = loaders.BarStyle.yellow },
        .{ .name = "Danger Red", .style = loaders.BarStyle.red },
        .{ .name = "Vibrant Gradient", .style = loaders.BarStyle.gradient },
    };

    inline for (themes) |theme| {
        std.debug.print("\nTheme: {s}\n", .{theme.name});
        var bar = loaders.Bar.init(io, .{
            .label = "Progress",
            .total = 100,
            .style = theme.style,
            .show_percent = true,
            .show_count = true,
        });
        defer bar.done();

        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(10), .awake);
        }
    }

    std.debug.print("\nTheme Gallery complete!\n", .{});
}
