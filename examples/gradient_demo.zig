//! gradient_demo.zig — Gradient-based multi-color progress bars and spinners.
//!
//! Run: zig build run-gradient_demo

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Gradient Multi-Color Demo ---\n\n", .{});

    // Rainbow gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Rainbow",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.rainbow,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Fire gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Fire   ",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.fire,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Ocean gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Ocean ",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.ocean,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Sunset gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Sunset",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.sunset,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Neon gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Neon  ",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.neon,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Forest gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Forest",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.forest,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Ice gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Ice   ",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.ice,
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n", .{});

    // Pastel gradient bar
    {
        var bar = loaders.Bar.init(io, .{
            .label = "Pastel",
            .total = 100,
            .show_percent = true,
            .show_elapsed = true,
            .style = .{
                .fill_gradient = loaders.Gradient.pastel,
                .fill = "▓",
                .empty = "░",
            },
        });
        defer bar.done();
        for (0..100) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
        }
    }

    std.debug.print("\n\n", .{});

    // Rainbow gradient spinner
    {
        var sp = loaders.Spinner.start(io, .{
            .text = "Rainbow spinner cycling colors...",
            .style = .{
                .frames = &.{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
                .gradient = loaders.Gradient.rainbow,
            },
            .show_elapsed = true,
        }) catch |err| {
            std.debug.print("Failed to start spinner: {}\n", .{err});
            return;
        };
        try io.sleep(std.Io.Duration.fromMilliseconds(2000), .awake);
        sp.succeed(io, "Rainbow spinner complete!");
    }

    // Fire gradient spinner
    {
        var sp = loaders.Spinner.start(io, .{
            .text = "Fire spinner blazing...",
            .style = .{
                .frames = &.{ "█", "▓", "▒", "░", "▒", "▓" },
                .gradient = loaders.Gradient.fire,
            },
            .show_elapsed = true,
        }) catch |err| {
            std.debug.print("Failed to start spinner: {}\n", .{err});
            return;
        };
        try io.sleep(std.Io.Duration.fromMilliseconds(2000), .awake);
        sp.succeed(io, "Fire spinner complete!");
    }

    // Neon gradient spinner
    {
        var sp = loaders.Spinner.start(io, .{
            .text = "Neon spinner glowing...",
            .style = .{
                .frames = &.{ "◆", "◇", "◈", "◉", "●", "◉", "◈", "◇" },
                .gradient = loaders.Gradient.neon,
            },
            .show_elapsed = true,
        }) catch |err| {
            std.debug.print("Failed to start spinner: {}\n", .{err});
            return;
        };
        try io.sleep(std.Io.Duration.fromMilliseconds(2000), .awake);
        sp.succeed(io, "Neon spinner complete!");
    }

    std.debug.print("\nAll gradient demos complete!\n", .{});
}
