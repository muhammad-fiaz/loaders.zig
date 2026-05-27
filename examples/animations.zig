//! animations.zig — Showcase every built-in SpinnerStyle and BarStyle preset.

const std = @import("std");
const loaders = @import("loaders");

const spinner_demos = [_]struct {
    name: []const u8,
    style: loaders.SpinnerStyle,
}{
    .{ .name = "dots         ", .style = loaders.SpinnerStyle.dots },
    .{ .name = "dots2        ", .style = loaders.SpinnerStyle.dots2 },
    .{ .name = "line         ", .style = loaders.SpinnerStyle.line },
    .{ .name = "arc          ", .style = loaders.SpinnerStyle.arc },
    .{ .name = "pulse        ", .style = loaders.SpinnerStyle.pulse },
    .{ .name = "bounce       ", .style = loaders.SpinnerStyle.bounce },
    .{ .name = "bars         ", .style = loaders.SpinnerStyle.bars },
    .{ .name = "braille      ", .style = loaders.SpinnerStyle.braille },
    .{ .name = "pong         ", .style = loaders.SpinnerStyle.pong },
    .{ .name = "arrow        ", .style = loaders.SpinnerStyle.arrow },
    .{ .name = "wifi         ", .style = loaders.SpinnerStyle.wifi },
    .{ .name = "aesthetic    ", .style = loaders.SpinnerStyle.aesthetic },
    .{ .name = "snake        ", .style = loaders.SpinnerStyle.snake },
    .{ .name = "triangle     ", .style = loaders.SpinnerStyle.triangle },
    .{ .name = "circle_pulse ", .style = loaders.SpinnerStyle.circle_pulse },
    .{ .name = "hamburger    ", .style = loaders.SpinnerStyle.hamburger },
    .{ .name = "box_bounce   ", .style = loaders.SpinnerStyle.box_bounce },
    .{ .name = "flip         ", .style = loaders.SpinnerStyle.flip },
    .{ .name = "globe        ", .style = loaders.SpinnerStyle.globe },
    .{ .name = "moon         ", .style = loaders.SpinnerStyle.moon },
    .{ .name = "clock        ", .style = loaders.SpinnerStyle.clock },
    .{ .name = "weather      ", .style = loaders.SpinnerStyle.weather },
    .{ .name = "hearts       ", .style = loaders.SpinnerStyle.hearts },
    .{ .name = "sand         ", .style = loaders.SpinnerStyle.sand },
    .{ .name = "charging     ", .style = loaders.SpinnerStyle.charging },
    .{ .name = "runner       ", .style = loaders.SpinnerStyle.runner },
    .{ .name = "monkey       ", .style = loaders.SpinnerStyle.monkey },
    .{ .name = "shark        ", .style = loaders.SpinnerStyle.shark },
    .{ .name = "christmas    ", .style = loaders.SpinnerStyle.christmas },
    .{ .name = "christmas_tree", .style = loaders.SpinnerStyle.christmas_tree },
    .{ .name = "finger_dance ", .style = loaders.SpinnerStyle.finger_dance },
    .{ .name = "mind_blown   ", .style = loaders.SpinnerStyle.mind_blown },
    .{ .name = "speaker      ", .style = loaders.SpinnerStyle.speaker },
};

const bar_demos = [_]struct {
    name: []const u8,
    style: loaders.BarStyle,
}{
    .{ .name = "block   ", .style = loaders.BarStyle.block },
    .{ .name = "ascii   ", .style = loaders.BarStyle.ascii },
    .{ .name = "shaded  ", .style = loaders.BarStyle.shaded },
    .{ .name = "green   ", .style = loaders.BarStyle.green },
    .{ .name = "cyan    ", .style = loaders.BarStyle.cyan },
    .{ .name = "yellow  ", .style = loaders.BarStyle.yellow },
    .{ .name = "red     ", .style = loaders.BarStyle.red },
    .{ .name = "blue    ", .style = loaders.BarStyle.blue },
    .{ .name = "magenta ", .style = loaders.BarStyle.magenta },
    .{ .name = "gradient", .style = loaders.BarStyle.gradient },
    .{ .name = "fire    ", .style = loaders.BarStyle.fire },
    .{ .name = "ice     ", .style = loaders.BarStyle.ice },
    .{ .name = "ocean   ", .style = loaders.BarStyle.ocean },
    .{ .name = "neon    ", .style = loaders.BarStyle.neon },
    .{ .name = "minimal ", .style = loaders.BarStyle.minimal },
    .{ .name = "arrow   ", .style = loaders.BarStyle.arrow },
    .{ .name = "dots    ", .style = loaders.BarStyle.dots },
    .{ .name = "slim    ", .style = loaders.BarStyle.slim },
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const io = init.io;

    std.debug.print("\n=== Spinner Styles ===\n\n", .{});

    // Show each spinner style for ~800ms
    for (spinner_demos) |demo| {
        const sp = try loaders.Spinner.start(io, .{
            .text = demo.name,
            .style = demo.style,
        });
        io.sleep(std.Io.Duration.fromMilliseconds(800), .awake) catch {};
        sp.succeed(io, demo.name);
    }

    std.debug.print("\n=== Bar Styles ===\n\n", .{});

    // Show each bar style filling from 0 to 100
    for (bar_demos) |demo| {
        var b = loaders.Bar.init(io, .{
            .label = demo.name,
            .total = 40,
            .style = demo.style,
            .show_percent = true,
            .width = 50,
        });
        var j: usize = 0;
        while (j <= 40) : (j += 1) {
            b.setCompleted(j);
            b.render();
            io.sleep(std.Io.Duration.fromMilliseconds(20), .awake) catch {};
        }
        b.done();
    }

    std.debug.print("\nAnimation showcase complete.\n", .{});
}
