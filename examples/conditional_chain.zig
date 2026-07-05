//! examples/conditional_chain.zig — Showcase conditional chaining & dependency callbacks.
//!
//! Demonstrates:
//!   - Progress Bar A triggering Progress Bar B on completion.
//!   - Progress Bar B triggering Spinner C on completion.
//!   - On-complete callbacks.
//!
//! Run: zig build run-conditional_chain

const std = @import("std");
const loaders = @import("loaders");

// We use thread-safe flags to synchronize our main execution with the callbacks.
var bar2_started = std.atomic.Value(bool).init(false);
var spinner_done = std.atomic.Value(bool).init(false);

// Globals/static instances to be triggered inside callbacks
var bar1: *loaders.Bar = undefined;
var bar2: *loaders.Bar = undefined;
var spinner: *loaders.Spinner = undefined;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Conditional Chaining & Dependency Callbacks Showcase ---\n\n", .{});
    std.debug.print("Initializing dependent pipeline...\n\n", .{});

    // Initialize Bar 1 (A)
    var b1 = loaders.Bar.init(io, .{
        .total = 100,
        .label = "Task A: Download Resources",
        .label_color = .bright_blue,
        .color = .bright_blue,
        .show_percent = true,
        .show_elapsed = true,
        .on_complete = onBar1Complete,
        .complete_message = "Download completed successfully!",
        .icon = "📥",
        .success_icon = "✓",
        .icon_gap = "  ",
        .label_gap = "  ",
        .padding_lines_above = 1,
        .padding_lines_below = 1,
    });
    bar1 = &b1;

    // Initialize Bar 2 (B) - but we won't start rendering/incrementing it until Bar A is done
    var b2 = loaders.Bar.init(io, .{
        .total = 100,
        .label = "Task B: Build & Compile Assets",
        .label_color = .bright_magenta,
        .color = .bright_magenta,
        .show_percent = true,
        .show_elapsed = true,
        .on_complete = onBar2Complete,
        .complete_message = "Compilation finished!",
        .icon = "🏗️",
        .success_icon = "✓",
        .icon_gap = "  ",
        .label_gap = "  ",
        .padding_lines_above = 1,
        .padding_lines_below = 1,
    });
    bar2 = &b2;

    // Run Bar 1 loop in a thread or inline
    var step: usize = 0;
    while (step <= 100) : (step += 10) {
        bar1.setCompleted(step);
        bar1.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(100), .awake);
    }
    // Finalize Bar 1 to trigger its on_complete
    bar1.done();

    // Wait until Bar 2 has been triggered to start running its loop
    while (!bar2_started.load(.acquire)) {
        try io.sleep(std.Io.Duration.fromMilliseconds(10), .awake);
    }

    // Now run Bar 2 loop
    step = 0;
    while (step <= 100) : (step += 10) {
        bar2.setCompleted(step);
        bar2.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(100), .awake);
    }
    // Finalize Bar 2 to trigger its on_complete
    bar2.done();

    // Wait until Spinner C has been triggered and finished
    while (!spinner_done.load(.acquire)) {
        try io.sleep(std.Io.Duration.fromMilliseconds(10), .awake);
    }

    std.debug.print("\nPipeline execution complete!\n", .{});
}

fn onBar1Complete(bar: *loaders.Bar) void {
    _ = bar;
    // Callback: Start the second progress bar
    std.debug.print("\n[Callback A] Task A finished. Starting Task B...\n", .{});
    bar2_started.store(true, .release);
}

fn onBar2Complete(bar: *loaders.Bar) void {
    // Callback: Start Spinner C
    std.debug.print("\n[Callback B] Task B finished. Starting Task C...\n", .{});

    // Initialize Spinner C (C)
    // Note: Spinner.start spawns a background rendering thread, so we start it right away!
    const io = bar.io;
    const sp = loaders.Spinner.start(io, .{
        .style = loaders.SpinnerStyle.moon,
        .text_color = .bright_yellow,
        .spinner_color = .bright_yellow,
        .prefix = "Task C: Optimizing bundle",
        .show_elapsed = true,
        .on_complete = onSpinnerComplete,
        .icon = "⚙️",
        .success_icon = "✓",
        .icon_gap = "  ",
        .text_gap = "  ",
        .padding_lines_above = 1,
        .padding_lines_below = 1,
    }) catch |err| {
        std.debug.print("Failed to start spinner: {}\n", .{err});
        spinner_done.store(true, .release);
        return;
    };
    spinner = sp;

    // Simulate work on another thread or let main thread wait
    const t = std.Thread.spawn(.{}, struct {
        fn run(io_sec: std.Io) void {
            io_sec.sleep(std.Io.Duration.fromMilliseconds(1500), .awake) catch {};
            spinner.succeed(io_sec, "Optimization complete!");
        }
    }.run, .{io}) catch |err| {
        std.debug.print("Failed to spawn worker thread: {}\n", .{err});
        spinner.stop(io);
        spinner_done.store(true, .release);
        return;
    };
    t.detach();
}

fn onSpinnerComplete(sp: *loaders.Spinner) void {
    _ = sp;
    std.debug.print("[Callback C] Spinner completed. Releasing pipeline control.\n", .{});
    spinner_done.store(true, .release);
}
