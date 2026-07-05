//! examples/color_demo.zig — Full color system showcase.
//!
//! Demonstrates all color constructors:
//!   1. Standard 16-color ANSI named colors (.red, .cyan, etc.)
//!   2. 256-color palette via Color.fromAnsi256(n)
//!   3. True-color RGB via Color.fromRgb(r, g, b)
//!   4. Hex string parsing via Color.fromHex("#RRGGBB")
//!
//! Run: zig build run-color_demo

const std = @import("std");
const loaders = @import("loaders");

const Color = loaders.Color;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Color System Showcase ---\n\n", .{});

    std.debug.print("1. Standard 16-color ANSI named colors:\n", .{});
    const named_colors = [_]struct { name: []const u8, c: Color }{
        .{ .name = "red         ", .c = .red },
        .{ .name = "green       ", .c = .green },
        .{ .name = "cyan        ", .c = .cyan },
        .{ .name = "yellow      ", .c = .yellow },
        .{ .name = "magenta     ", .c = .magenta },
        .{ .name = "bright_blue ", .c = .bright_blue },
        .{ .name = "bright_white", .c = .bright_white },
    };

    for (named_colors) |nc| {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = nc.name,
            .show_percent = false,
            .fill_color = nc.c,
            .empty_color = .bright_black,
        });
        bar.setCompleted(65);
        bar.render();
        std.debug.print("\n", .{});
    }

    std.debug.print("\n2. 256-color palette (every 32nd color):\n", .{});
    var palette_idx: u8 = 0;
    while (true) {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = "ansi256",
            .show_percent = false,
            .fill_color = Color.fromAnsi256(palette_idx),
            .empty_color = .bright_black,
        });
        bar.setCompleted(70);
        bar.render();
        std.debug.print("\n", .{});

        if (palette_idx >= 224) break;
        palette_idx +|= 32;
    }

    std.debug.print("\n3. True-color RGB bars:\n", .{});
    const rgb_colors = [_]struct { name: []const u8, r: u8, g: u8, b: u8 }{
        .{ .name = "tomato red  ", .r = 255, .g = 99, .b = 71 },
        .{ .name = "lime green  ", .r = 50, .g = 205, .b = 50 },
        .{ .name = "deep sky    ", .r = 0, .g = 191, .b = 255 },
        .{ .name = "gold        ", .r = 255, .g = 215, .b = 0 },
        .{ .name = "violet      ", .r = 148, .g = 0, .b = 211 },
        .{ .name = "hot pink    ", .r = 255, .g = 105, .b = 180 },
        .{ .name = "teal        ", .r = 0, .g = 200, .b = 180 },
    };

    for (rgb_colors) |rc| {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = rc.name,
            .show_percent = false,
            .fill_color = Color.fromRgb(rc.r, rc.g, rc.b),
            .empty_color = .bright_black,
        });
        bar.setCompleted(80);
        bar.render();
        std.debug.print("\n", .{});
    }

    std.debug.print("\n4. Hex string parsing (Color.fromHex):\n", .{});
    const hex_colors = [_]struct { name: []const u8, hex: []const u8 }{
        .{ .name = "#FF8800 (orange)    ", .hex = "#FF8800" },
        .{ .name = "#00FFAA (sea green) ", .hex = "#00FFAA" },
        .{ .name = "#FF00FF (fuchsia)   ", .hex = "#FF00FF" },
        .{ .name = "#1E90FF (dodger)    ", .hex = "#1E90FF" },
        .{ .name = "F0E (shorthand)     ", .hex = "F0E" },
    };

    for (hex_colors) |hc| {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = hc.name,
            .show_percent = false,
            .fill_color = Color.fromHex(hc.hex),
            .empty_color = .bright_black,
        });
        bar.setCompleted(75);
        bar.render();
        std.debug.print("\n", .{});
    }

    std.debug.print("\n5. All BarStyle presets at 60%% fill:\n", .{});
    const styles = [_]struct { name: []const u8, s: loaders.BarStyle }{
        .{ .name = "ascii       ", .s = loaders.BarStyle.ascii },
        .{ .name = "block       ", .s = loaders.BarStyle.block },
        .{ .name = "gradient    ", .s = loaders.BarStyle.gradient },
        .{ .name = "fire        ", .s = loaders.BarStyle.fire },
        .{ .name = "ice         ", .s = loaders.BarStyle.ice },
        .{ .name = "ocean       ", .s = loaders.BarStyle.ocean },
        .{ .name = "neon        ", .s = loaders.BarStyle.neon },
        .{ .name = "minimal     ", .s = loaders.BarStyle.minimal },
        .{ .name = "arrow       ", .s = loaders.BarStyle.arrow },
        .{ .name = "dots        ", .s = loaders.BarStyle.dots },
        .{ .name = "slim        ", .s = loaders.BarStyle.slim },
        .{ .name = "pipe        ", .s = loaders.BarStyle.pipe },
        .{ .name = "half_block  ", .s = loaders.BarStyle.half_block },
        .{ .name = "matrix      ", .s = loaders.BarStyle.matrix },
        .{ .name = "retro       ", .s = loaders.BarStyle.retro },
        .{ .name = "classic_pipe", .s = loaders.BarStyle.classic_pipes },
        .{ .name = "rainbow     ", .s = loaders.BarStyle.rainbow },
        .{ .name = "teal        ", .s = loaders.BarStyle.teal },
    };

    for (styles) |st| {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = st.name,
            .show_percent = true,
            .style = st.s,
        });
        bar.setCompleted(60);
        bar.render();
        std.debug.print("\n", .{});
    }

    std.debug.print("\n6. Whole progress bar line coloring (new .color option):\n", .{});
    const whole_line_colors = [_]struct { name: []const u8, c: Color }{
        .{ .name = "whole yellow line", .c = .yellow },
        .{ .name = "whole cyan line  ", .c = .cyan },
        .{ .name = "whole magenta line", .c = .magenta },
    };

    for (whole_line_colors) |wlc| {
        var bar = loaders.Bar.init(io, .{
            .total = 100,
            .width = 25,
            .label = wlc.name,
            .show_percent = true,
            .color = wlc.c,
        });
        bar.setCompleted(45);
        bar.render();
        std.debug.print("\n", .{});
    }

    std.debug.print("\nColor demo complete.\n", .{});
}
