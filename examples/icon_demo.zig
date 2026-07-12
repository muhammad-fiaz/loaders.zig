//! examples/icon_demo.zig — Custom icons, completion statuses, templates, and non-TTY demo.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== Icon and Status Demo ===\n\n", .{});

    // 1. Progress Bar with Running Icon and succeed() completion
    {
        std.debug.print("1. Progress Bar with custom running icon and succeed() completion:\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 50,
            .label = "Deploying app",
            .width = 30,
        });
        errdefer bar.done();

        for (0..50) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.succeed("App deployed successfully!");
        std.debug.print("\n", .{});
    }

    // 2. Progress Bar with fail() completion
    {
        std.debug.print("2. Progress Bar with custom failure icon and fail() completion:\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 50,
            .label = "Testing code",
            .width = 30,
        });
        errdefer bar.done();

        for (0..30) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.fail("Tests failed: 3 assertions unmet.");
        std.debug.print("\n", .{});
    }

    // 3. Progress Bar with template formatting using {icon} token
    {
        std.debug.print("3. Progress Bar using template formatting with '{{icon}}' token:\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 50,
            .label = "Build",
            .template = "{icon}{label} {bar} {percent} - {message}",
            .message = "compiling...",
            .width = 20,
        });
        errdefer bar.done();

        for (0..50) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.succeed("Compilation complete!");
        std.debug.print("\n", .{});
    }

    // 4. Spinner with custom prefix icon and custom succeed/fail icons
    {
        std.debug.print("4. Spinner with running icon prefix and custom status icons:\n", .{});
        const sp = try loaders.Spinner.start(io, .{
            .text = "Initializing modules...",
            .success_icon = "🎉",
            .allocator = allocator,
        });
        errdefer sp.stop(io);

        try io.sleep(std.Io.Duration.fromMilliseconds(800), .awake);
        sp.succeed(io, "System ready!");
    }

    // 5. Non-TTY newline configuration demo
    {
        std.debug.print("\n5. Non-TTY newline configuration demo (disable_new_line = true):\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 10,
            .label = "Silent log",
            .term = loaders.TermInfo.dumb, // non-TTY
            .disable_new_line = true,
            .width = 20,
        });
        errdefer bar.done();

        for (0..10) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.succeed("Log processing finished.");
        std.debug.print("\n", .{});
    }

    // 6. BatchBar with custom icons and staggered states
    {
        std.debug.print("6. BatchBar with custom running/status icons:\n", .{});
        var bb = loaders.BatchBar.init(io, .{
            .title = "▶  Module Downloads",
            .show_percent = true,
            .style = loaders.BarStyle.slim,
            .icon = "📥",
            .tasks = &.{
                .{ .name = "Download module A", .total = 100, .success_icon = "🎁", .failure_icon = "❌" },
                .{ .name = "Download module B", .total = 100, .success_icon = "🎁" },
            },
        });

        for (0..100) |i| {
            bb.setTaskCompleted(0, i + 1);
            if (i < 90) bb.setTaskCompleted(1, i + 1);
            bb.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(10), .awake);
        }
        bb.setTaskDone(0);
        bb.setTaskWarning(1);

        try io.sleep(std.Io.Duration.fromMilliseconds(200), .awake);
        bb.done();
        std.debug.print("\n", .{});
    }

    // 7. BatchBar with custom icons and new states
    {
        std.debug.print("7. BatchBar with custom icons and warning/info states:\n", .{});
        var bb = loaders.BatchBar.init(io, .{
            .title = "▶  Deployment Steps",
            .style = loaders.BarStyle.slim,
            .icon = "🛠️",
            .success_icon = "🎉",
            .failure_icon = "💥",
            .warning_icon = "⚠️",
            .info_icon = "📢",
            .tasks = &.{
                .{ .name = "Verify auth  ", .total = 10 },
                .{ .name = "Build bundle ", .total = 20, .icon = "🏗️" },
                .{ .name = "Deploy server", .total = 30 },
            },
        });

        bb.setTaskCompleted(0, 10);
        bb.setTaskDone(0);
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(300), .awake);

        bb.setTaskCompleted(1, 20);
        bb.setTaskWarning(1);
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(300), .awake);

        bb.setTaskCompleted(2, 15);
        bb.setTaskInfo(2);
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(200), .awake);

        bb.done();
        std.debug.print("\n", .{});
    }

    // 8. Spinner with hide_after_done — disappears after completion
    {
        std.debug.print("8. Spinner with hide_after_done (line erased after completion):\n", .{});
        const sp = try loaders.Spinner.start(io, .{
            .text = "Secret background task...",
            .hide_after_done = true,
            .allocator = allocator,
        });
        errdefer sp.stop(io);

        try io.sleep(std.Io.Duration.fromMilliseconds(800), .awake);
        sp.succeed(io, ""); // spinner line is erased — nothing printed
        std.debug.print("  (spinner line was erased)\n", .{});
    }

    // 9. Progress Bar with hide_after_done — disappears after completion
    {
        std.debug.print("9. Progress Bar with hide_after_done (line erased after completion):\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 30,
            .hide_after_done = true,
            .width = 25,
        });
        errdefer bar.done();

        for (0..30) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.succeed(""); // progress bar line is erased
        std.debug.print("  (progress bar line was erased)\n", .{});
    }

    // 10. Progress Bar with background colors
    {
        std.debug.print("10. Progress Bar with background colors:\n", .{});
        var bar = loaders.ProgressBar.init(io, .{
            .total = 40,
            .label = "BG Demo",
            .width = 25,
            .bg_color = .blue,
        });
        errdefer bar.done();

        for (0..40) |i| {
            bar.setCompleted(i + 1);
            bar.render();
            try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
        }
        bar.done();
        std.debug.print("\n", .{});
    }
}
