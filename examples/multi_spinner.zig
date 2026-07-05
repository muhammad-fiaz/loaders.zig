//! multi_spinner.zig — Demonstrates MultiSpinner with per-item colors and states.

const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const io = init.io;

    std.debug.print("--- Multi-Spinner Demo ---\n", .{});

    const ms = try loaders.MultiSpinner.start(io, std.Io.File.stderr(), null, allocator);
    errdefer ms.stop();
    ms.icon_gap = "  ";
    ms.text_gap = "  ";
    ms.spacing_lines = 1;

    const fetch = ms.addItem("Fetching data from API", loaders.SpinnerStyle.dots);
    const parse = ms.addItem("Parsing JSON response", loaders.SpinnerStyle.arc);
    const build = ms.addItem("Compiling assets", loaders.SpinnerStyle.aesthetic);
    const upload = ms.addItem("Uploading to CDN", loaders.SpinnerStyle.pulse);
    const check = ms.addItem("Running health checks", loaders.SpinnerStyle.wifi);

    fetch.icon = "📥";
    parse.icon = "⚙️";
    build.icon = "🏗️";
    upload.icon = "📤";
    check.icon = "🩺";

    // Give each item a distinct coloring strategy
    fetch.color = .cyan; // Whole line colored cyan
    parse.color = .bright_yellow; // Whole line colored bright yellow

    // Custom overrides for build spinner
    build.color = .{ .rgb = .{ .r = 160, .g = 100, .b = 255 } }; // Global purple
    build.text_color = .bright_white; // Specific text color override (white text)
    build.spinner_color = .bright_red; // Specific glyph color override (red glyph)

    upload.color = .bright_blue;
    check.color = .green;

    // Suffixes
    fetch.suffix = "(50 KB/s)";

    // Simulate staggered completions
    io.sleep(std.Io.Duration.fromMilliseconds(800), .awake) catch {};
    ms.setSucceeded(fetch, "Data fetched (128 records)");

    io.sleep(std.Io.Duration.fromMilliseconds(600), .awake) catch {};
    ms.setSucceeded(parse, "JSON parsed successfully");

    io.sleep(std.Io.Duration.fromMilliseconds(1200), .awake) catch {};
    ms.setFailed(build, "Compilation failed: missing symbol");

    io.sleep(std.Io.Duration.fromMilliseconds(400), .awake) catch {};
    ms.setWarning(upload, "Upload skipped (CDN unreachable)");

    io.sleep(std.Io.Duration.fromMilliseconds(700), .awake) catch {};
    ms.setSucceeded(check, "All health checks passed");

    io.sleep(std.Io.Duration.fromMilliseconds(200), .awake) catch {};
    ms.stop();

    std.debug.print("\nFinished.\n", .{});
}
