//! spinner.zig — Animated spinner with a background render thread.
//!
//! Usage:
//!
//!   var sp = try Spinner.start(io, .{ .text = "Loading..." });
//!   defer sp.stop(io);
//!   // ... do work ...
//!   try sp.succeed(io, "Done!");

const std = @import("std");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");
const utils = @import("utils.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const SpinnerStyle = style_mod.SpinnerStyle;

// Options

/// Configuration passed to `Spinner.start`.
pub const Options = struct {
    /// Text displayed to the right of the spinner glyph.
    text: []const u8 = "",
    /// Visual style (frames + color).
    style: SpinnerStyle = SpinnerStyle.dots,
    /// File to render to (default: stderr).
    file: ?std.Io.File = null,
    /// Terminal info override. If null, auto-detected.
    term: ?terminal.TermInfo = null,
    /// Enable color. If null, auto-detected.
    color_enabled: ?bool = null,
    /// Prefix character(s) shown before the glyph (e.g. empty string or "  ").
    prefix: []const u8 = "",

    // New customizations
    /// Printed at the absolute start of the spinner line.
    custom_start: []const u8 = "",
    /// Printed at the absolute end of the spinner line.
    custom_end: []const u8 = "",
    /// Whether to show current date [YYYY-MM-DD].
    show_date: bool = false,
    /// Whether to show current time [HH:MM:SS].
    show_time: bool = false,
    /// Offset in seconds to adjust timezone from UTC for date/time (e.g. 19800 for UTC+5:30).
    timezone_offset_sec: i32 = 0,
    /// Optional custom allocator (falls back to std.heap.page_allocator if null).
    allocator: ?std.mem.Allocator = null,
};

// Spinner

/// An animated spinner that runs its render loop on a background thread.
///
/// Call `start` to launch, then `stop` / `succeed` / `fail` when done.
pub const Spinner = struct {
    opts: Options,
    colorizer: Colorizer,
    term: terminal.TermInfo,
    file: std.Io.File,
    allocator: std.mem.Allocator,

    // Shared state between caller and render thread
    stop_flag: std.atomic.Value(bool),
    text: std.atomic.Value([*:0]const u8), // pointer to null-terminated text

    // The background render thread
    thread: std.Thread,

    // Static text storage (updated atomically)
    text_buf: [256:0]u8,

    // Lifecycle

    /// Start the spinner. Spawns a background render thread.
    /// Must call `stop`, `succeed`, or `fail` to clean up.
    pub fn start(io: std.Io, opts: Options) !*Spinner {
        terminal.setupTerminal();

        // We heap-allocate the Spinner so the pointer is stable for the thread.
        const gpa = opts.allocator orelse std.heap.page_allocator;
        const sp = try gpa.create(Spinner);
        errdefer gpa.destroy(sp);

        const file = opts.file orelse std.Io.File.stderr();
        const term_info = opts.term orelse terminal.query(file, io);
        const color_on = opts.color_enabled orelse term_info.ansi_supported;

        var resolved_opts = opts;
        resolved_opts.file = file;

        sp.* = Spinner{
            .opts = resolved_opts,
            .colorizer = Colorizer{
                .enabled = color_on,
                .ansi_enabled = term_info.ansi_supported,
            },
            .term = term_info,
            .file = file,
            .allocator = gpa,
            .stop_flag = std.atomic.Value(bool).init(false),
            .text = undefined,
            .thread = undefined,
            .text_buf = [_:0]u8{0} ** 256,
        };

        // Copy initial text into buf
        sp.updateText(opts.text);

        // Store initial text pointer
        sp.text = std.atomic.Value([*:0]const u8).init(sp.text_buf[0..].ptr);

        // Spawn render thread
        sp.thread = try std.Thread.spawn(.{}, renderLoop, .{ sp, io });

        return sp;
    }

    /// Update the spinner text (thread-safe).
    pub fn setText(sp: *Spinner, text: []const u8) void {
        sp.updateText(text);
    }

    /// Stop the spinner and erase it from the terminal.
    pub fn stop(sp: *Spinner, io: std.Io) void {
        sp.stop_flag.store(true, .release);
        sp.thread.join();
        sp.eraseLine(io);
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a success line (✓ green tick).
    pub fn succeed(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        sp.thread.join();
        sp.printFinal(io, text, "✓", .green);
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a failure line (✗ red cross).
    pub fn fail(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        sp.thread.join();
        sp.printFinal(io, text, "✗", .red);
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a warning line (⚠ yellow warning).
    pub fn warn(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        sp.thread.join();
        sp.printFinal(io, text, "⚠", .yellow);
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print an info line (ℹ cyan info).
    pub fn info(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        sp.thread.join();
        sp.printFinal(io, text, "ℹ", .cyan);
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    // Internal

    fn updateText(sp: *Spinner, text: []const u8) void {
        const len = @min(text.len, 255);
        @memcpy(sp.text_buf[0..len], text[0..len]);
        sp.text_buf[len] = 0;
    }

    fn eraseLine(sp: *Spinner, io: std.Io) void {
        var buf: [64]u8 = undefined;
        var fw: std.Io.File.Writer = .init(sp.file, io, &buf);
        const w = &fw.interface;
        sp.colorizer.clearLine(w) catch {};
        fw.flush() catch {};
    }

    fn printFinal(sp: *Spinner, io: std.Io, text: []const u8, symbol: []const u8, sym_color: Color) void {
        var buf: [512]u8 = undefined;
        var fw: std.Io.File.Writer = .init(sp.file, io, &buf);
        const w = &fw.interface;

        sp.colorizer.clearLine(w) catch {};

        // Render custom_start
        if (sp.opts.custom_start.len > 0) {
            w.writeAll(sp.opts.custom_start) catch {};
        }

        // Render date & time prefix
        const ts_ns = std.Io.Clock.real.now(io).nanoseconds;
        const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + sp.opts.timezone_offset_sec;
        if (sp.opts.show_date and sp.opts.show_time) {
            var dbuf: [16]u8 = undefined;
            var tbuf: [16]u8 = undefined;
            w.print("[{s} {s}] ", .{ utils.formatDate(&dbuf, ts), utils.formatTime(&tbuf, ts) }) catch {};
        } else if (sp.opts.show_date) {
            var dbuf: [16]u8 = undefined;
            w.print("[{s}] ", .{utils.formatDate(&dbuf, ts)}) catch {};
        } else if (sp.opts.show_time) {
            var tbuf: [16]u8 = undefined;
            w.print("[{s}] ", .{utils.formatTime(&tbuf, ts)}) catch {};
        }

        color_mod.writeColored(w, sp.colorizer, symbol, sym_color, .default, &.{.bold}) catch {};
        w.print(" {s}", .{text}) catch {};

        // Render custom_end
        if (sp.opts.custom_end.len > 0) {
            w.writeAll(sp.opts.custom_end) catch {};
        }

        w.writeByte('\n') catch {};
        fw.flush() catch {};
    }

    fn renderLoop(sp: *Spinner, io: std.Io) void {
        var frame: usize = 0;
        var buf: [512]u8 = undefined;

        while (!sp.stop_flag.load(.acquire)) {
            // Render one frame
            var fw: std.Io.File.Writer = .init(sp.file, io, &buf);
            const w = &fw.interface;

            sp.colorizer.clearLine(w) catch {};

            // Render custom_start
            if (sp.opts.custom_start.len > 0) {
                w.writeAll(sp.opts.custom_start) catch {};
            }

            // Render date & time prefix
            const ts_ns = std.Io.Clock.real.now(io).nanoseconds;
            const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + sp.opts.timezone_offset_sec;
            if (sp.opts.show_date and sp.opts.show_time) {
                var dbuf: [16]u8 = undefined;
                var tbuf: [16]u8 = undefined;
                w.print("[{s} {s}] ", .{ utils.formatDate(&dbuf, ts), utils.formatTime(&tbuf, ts) }) catch {};
            } else if (sp.opts.show_date) {
                var dbuf: [16]u8 = undefined;
                w.print("[{s}] ", .{utils.formatDate(&dbuf, ts)}) catch {};
            } else if (sp.opts.show_time) {
                var tbuf: [16]u8 = undefined;
                w.print("[{s}] ", .{utils.formatTime(&tbuf, ts)}) catch {};
            }

            if (sp.opts.prefix.len > 0) {
                w.writeAll(sp.opts.prefix) catch {};
            }

            const frames = sp.opts.style.frames;
            const glyph = frames[frame % frames.len];
            color_mod.writeColored(w, sp.colorizer, glyph, sp.opts.style.color, .default, sp.opts.style.attrs) catch {};

            // Read current text
            const text_ptr: [*:0]const u8 = sp.text.load(.acquire);
            const text = std.mem.span(text_ptr);
            if (text.len > 0) {
                w.print(" {s}", .{text}) catch {};
            }

            // Render custom_end
            if (sp.opts.custom_end.len > 0) {
                w.writeAll(sp.opts.custom_end) catch {};
            }

            fw.flush() catch {};

            frame += 1;

            // Sleep for one frame interval
            const interval_ms = sp.opts.style.interval_ms;
            io.sleep(
                std.Io.Duration.fromMilliseconds(@intCast(interval_ms)),
                .awake,
            ) catch break;
        }
    }
};

// Tests

test "SpinnerStyle.dots has frames" {
    try std.testing.expect(SpinnerStyle.dots.frames.len > 0);
    try std.testing.expect(SpinnerStyle.dots.interval_ms > 0);
}

test "Spinner start and stop" {
    const io = std.Options.debug_threaded_io.?.io();
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const sp = try Spinner.start(io, .{
        .text = "Testing...",
        .style = SpinnerStyle.line,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
    });
    // Sleep briefly
    io.sleep(std.Io.Duration.fromMilliseconds(50), .awake) catch {};
    sp.stop(io);
}
