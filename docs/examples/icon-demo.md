---
description: Custom running and completion icons, dynamic statuses, template formatting, and non-TTY configurations in loaders.zig.
head:
  - - meta
    - name: keywords
      content: loaders.zig custom icons, progress bar icons, spinner custom icons, non-TTY newline configuration
  - - meta
    - property: og:title
      content: Custom Icons Example — loaders.zig
  - - meta
    - property: og:description
      content: Demonstrates custom running and completion icons, dynamic statuses, template formatting, and non-TTY configurations.
---

# Custom Icons and Statuses

This example demonstrates how to use custom running and completion icons for both progress bars and spinners, dynamic status methods (`succeed`/`fail`/`warn`/`info` on `Bar`), formatting templates with the `{icon}` token, and controlling intermediate output in non-TTY environments.

---

## Source

```zig
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
        var bar = loaders.Bar.init(io, .{
            .total = 50,
            .icon = "🚀",
            .success_icon = "✨",
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
        var bar = loaders.Bar.init(io, .{
            .total = 50,
            .icon = "📦",
            .failure_icon = "💥",
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
        var bar = loaders.Bar.init(io, .{
            .total = 50,
            .icon = "⚙️",
            .success_icon = "✅",
            .label = "Build",
            .template = "{icon} {label} {bar} {percent} - {message}",
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
            .icon = "🔧",
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
        var bar = loaders.Bar.init(io, .{
            .total = 10,
            .label = "Silent log",
            .term = loaders.TermInfo.dumb, // non-TTY
            .disable_new_line = true,
            .icon = "💾",
            .success_icon = "💾 ✓",
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

    // 6. MultiSpinner with custom icons and statuses
    {
        std.debug.print("6. MultiSpinner with custom running/status icons:\n", .{});
        const ms = try loaders.MultiSpinner.start(io, std.Io.File.stderr(), .{ .allocator = allocator });
        errdefer ms.stop();

        const task1 = ms.addItem("Download module A", .dots);
        task1.icon = "📥";
        task1.success_icon = "🎁";
        task1.failure_icon = "❌";

        const task2 = ms.addItem("Download module B", .dots);
        task2.icon = "📥";
        task2.success_icon = "🎁";

        try io.sleep(std.Io.Duration.fromMilliseconds(500), .awake);
        ms.setSucceeded(task1, "Module A retrieved successfully!");
        
        try io.sleep(std.Io.Duration.fromMilliseconds(400), .awake);
        ms.setWarning(task2, "Module B retrieved with cache warnings.");
        
        try io.sleep(std.Io.Duration.fromMilliseconds(200), .awake);
        ms.stop();
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
        });

        const step1 = bb.addTask("Verify auth  ", 10);
        const step2 = bb.addTask("Build bundle ", 20);
        const step3 = bb.addTask("Deploy server", 30);

        bb.tasks[step2].icon = "🏗️"; // Task-specific override

        // Simulating runs
        bb.setTaskCompleted(step1, 10);
        bb.setTaskDone(step1);
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(300), .awake);

        bb.setTaskCompleted(step2, 20);
        bb.setTaskWarning(step2); // warning state
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(300), .awake);

        bb.setTaskCompleted(step3, 15);
        bb.setTaskInfo(step3); // info state
        bb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(200), .awake);
        
        bb.done();
        std.debug.print("\n", .{});
    }
}
```

## Run

```bash
zig build run-icon_demo
```
