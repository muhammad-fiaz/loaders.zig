//! 02_styled_bar.zig — Progress bars with custom styles.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const total: usize = 40;

    // Style presets to demo
    const styles = [_]struct { name: []const u8, style: loaders.BarStyle }{
        .{ .name = "block   ", .style = .{} },
        .{ .name = "ascii   ", .style = .ascii },
        .{ .name = "shaded  ", .style = .shaded },
        .{ .name = "green   ", .style = .green },
        .{ .name = "cyan    ", .style = .cyan },
        .{ .name = "gradient", .style = .gradient },
        .{ .name = "minimal ", .style = .minimal },
    };

    for (styles) |s| {
        var bar = loaders.ProgressBar.init(io, .{
            .label = s.name,
            .total = total,
            .style = s.style,
            .show_percent = true,
            .width = 30,
        });
        defer bar.done();

        for (0..total) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
    }
}
