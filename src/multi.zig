//! multi.zig — Render multiple progress bars / spinners concurrently.
//!
//! `MultiBar` manages a list of `Bar` instances and renders them one per line,
//! moving the cursor up to redraw on each refresh without scrolling.
//!
//! `MultiSpinner` manages a list of `SpinnerItem` states and renders them on
//! separate lines via a single background thread.

const std = @import("std");
const bar_mod = @import("bar.zig");
const spinner_mod = @import("spinner.zig");
const color_mod = @import("color.zig");
const terminal = @import("terminal.zig");

pub const Bar = bar_mod.Bar;
pub const BarOptions = bar_mod.Options;
pub const SpinnerStyle = spinner_mod.SpinnerStyle;
pub const Colorizer = color_mod.Colorizer;

/// Maximum number of bars in a `MultiBar`.
pub const max_bars = 16;

/// Options for `MultiBar`.
pub const MultiBarOptions = struct {
    /// Hide the cursor during rendering (restored on `done()`).
    hide_cursor: bool = true,
    /// Message printed after all bars complete.
    complete_message: []const u8 = "",
};

/// Renders multiple progress bars, each on its own line, with cursor
/// repositioning to allow in-place animation without scrolling.
///
/// Usage:
///
///   var mb = MultiBar.init(io, .stderr(), null, .{});
///   const b1 = mb.addBar(.{ .label = "Task A", .total = 100 });
///   const b2 = mb.addBar(.{ .label = "Task B", .total = 200 });
///   while (not_done) {
///       b1.increment();
///       b2.incrementBy(2);
///       mb.render();
///       io.sleep(...);
///   }
///   mb.done();
pub const MultiBar = struct {
    io: std.Io,
    bars: [max_bars]Bar,
    count: usize,
    colorizer: Colorizer,
    term: terminal.TermInfo,
    first_render: bool,
    write_buf: [8192]u8,
    file: std.Io.File,
    mbopts: MultiBarOptions,

    /// Initialise the multi-bar renderer.
    pub fn init(io: std.Io, file: std.Io.File, term_info: ?terminal.TermInfo, mbopts: MultiBarOptions) MultiBar {
        terminal.setupTerminal();
        const ti = term_info orelse terminal.query(file, io);
        return .{
            .io = io,
            .bars = undefined,
            .count = 0,
            .colorizer = .{
                .enabled = ti.ansi_supported,
                .ansi_enabled = ti.ansi_supported,
            },
            .term = ti,
            .first_render = true,
            .write_buf = undefined,
            .file = file,
            .mbopts = mbopts,
        };
    }

    /// Add a bar with the given options. Returns a pointer to the bar.
    /// Panics if `max_bars` has been reached.
    pub fn addBar(mb: *MultiBar, opts: BarOptions) *Bar {
        const i = mb.count;
        std.debug.assert(i < max_bars);
        mb.bars[i] = Bar.init(mb.io, .{
            .label = opts.label,
            .label_color = opts.label_color,
            .total = opts.total,
            .width = opts.width,
            .style = opts.style,
            .show_percent = opts.show_percent,
            .percent_color = opts.percent_color,
            .bracket_color = opts.bracket_color,
            .show_count = opts.show_count,
            .show_elapsed = opts.show_elapsed,
            .show_eta = opts.show_eta,
            .show_rate = opts.show_rate,
            .unit_is_bytes = opts.unit_is_bytes,
            .message = opts.message,
            .complete_message = opts.complete_message,
            .suffix = opts.suffix,
            .file = mb.file,
            .term = mb.term,
            .color_enabled = mb.colorizer.enabled,
        });
        mb.count += 1;
        return &mb.bars[i];
    }

    /// Render all bars in-place. Call this from your main loop.
    pub fn render(mb: *MultiBar) void {
        mb.renderInner() catch {};
    }

    fn renderInner(mb: *MultiBar) !void {
        var fw: std.Io.File.Writer = .init(mb.file, mb.io, &mb.write_buf);
        const w = &fw.interface;

        if (!mb.first_render) {
            // Move cursor up by the number of bars so we overwrite previous output.
            try mb.colorizer.cursorUp(w, mb.count);
        } else if (mb.mbopts.hide_cursor) {
            try mb.colorizer.hideCursor(w);
        }
        mb.first_render = false;

        // Render each bar onto its own line using a single writer.
        for (mb.bars[0..mb.count]) |*b| {
            // Update terminal width if auto-sizing.
            if (b.opts.width == 0) {
                b.term = mb.term;
            }
            // Erase the line then render bar content inline.
            try mb.colorizer.clearLine(w);
            try b.renderContent(w);
            try w.writeByte('\n');
        }

        try fw.flush();
    }

    /// Mark all bars as done and print a final newline.
    pub fn done(mb: *MultiBar) void {
        for (mb.bars[0..mb.count]) |*b| {
            b.done_flag.store(true, .release);
            if (b.opts.complete_message.len > 0) {
                b.setMessage(b.opts.complete_message);
            }
        }
        mb.render();

        // Show cursor again.
        var fw: std.Io.File.Writer = .init(mb.file, mb.io, &mb.write_buf);
        if (mb.mbopts.hide_cursor) {
            mb.colorizer.showCursor(&fw.interface) catch {};
            fw.flush() catch {};
        }
        if (mb.mbopts.complete_message.len > 0) {
            var fw2: std.Io.File.Writer = .init(mb.file, mb.io, &mb.write_buf);
            fw2.interface.print("{s}\n", .{mb.mbopts.complete_message}) catch {};
            fw2.flush() catch {};
        }
    }
};

// ── MultiSpinner ───────────────────────────────────────────────────────────────

/// Maximum number of spinner items in a `MultiSpinner`.
pub const max_spinners = 16;

/// State for a single spinner item in a `MultiSpinner`.
pub const SpinnerItem = struct {
    text: [256:0]u8 = [_:0]u8{0} ** 256,
    style: SpinnerStyle = SpinnerStyle.dots,
    /// Set to finish this item. `succeeded` controls the result glyph.
    done: bool = false,
    /// null = running, true = success (✓), false = failure (✗).
    succeeded: ?bool = null,
    /// Custom color override for this item's glyph. `.default` = use style color.
    color: color_mod.Color = .default,
    /// Prefix string printed before the spinner glyph on each frame.
    prefix: []const u8 = "",
    /// Suffix string printed after the text on each frame.
    suffix: []const u8 = "",

    pub fn setText(item: *SpinnerItem, s: []const u8) void {
        const len = @min(s.len, 255);
        @memcpy(item.text[0..len], s[0..len]);
        item.text[len] = 0;
    }

    pub fn getTextSlice(item: *const SpinnerItem) []const u8 {
        return std.mem.sliceTo(&item.text, 0);
    }
};

/// Renders multiple spinner items on separate lines via a single background thread.
///
/// Usage:
///
///   var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
///   defer arena.deinit();
///   const ms = try MultiSpinner.start(io, .stderr(), null, arena.allocator());
///   const item1 = ms.addItem("Fetching data", .dots);
///   const item2 = ms.addItem("Processing",   .arc);
///   // ... do work ...
///   ms.setSucceeded(item1, "Data ready");
///   ms.setFailed(item2,    "Processing failed");
///   ms.stop();
pub const MultiSpinner = struct {
    io: std.Io,
    items: [max_spinners]SpinnerItem,
    count: usize,
    colorizer: Colorizer,
    file: std.Io.File,
    stop_flag: std.atomic.Value(bool),
    thread: std.Thread,
    write_buf: [8192]u8,
    allocator: std.mem.Allocator,

    /// Start the multi-spinner renderer. Returns a heap-allocated instance.
    pub fn start(io: std.Io, file: std.Io.File, color_enabled: ?bool, maybe_allocator: ?std.mem.Allocator) !*MultiSpinner {
        terminal.setupTerminal();
        const ti = terminal.query(file, io);
        const color_on = color_enabled orelse ti.ansi_supported;

        const allocator = maybe_allocator orelse std.heap.page_allocator;
        const ms = try allocator.create(MultiSpinner);
        ms.* = .{
            .io = io,
            .items = undefined,
            .count = 0,
            .colorizer = .{
                .enabled = color_on,
                .ansi_enabled = ti.ansi_supported,
            },
            .file = file,
            .stop_flag = std.atomic.Value(bool).init(false),
            .thread = undefined,
            .write_buf = undefined,
            .allocator = allocator,
        };

        ms.thread = try std.Thread.spawn(.{}, renderLoop, .{ms});
        return ms;
    }

    /// Add a spinner item with optional per-item color override.
    /// Returns a pointer to the item for later updates.
    pub fn addItem(ms: *MultiSpinner, text: []const u8, style: SpinnerStyle) *SpinnerItem {
        const i = ms.count;
        std.debug.assert(i < max_spinners);
        ms.items[i] = SpinnerItem{ .style = style };
        ms.items[i].setText(text);
        ms.count += 1;
        return &ms.items[i];
    }

    /// Mark `item` as succeeded and update its text.
    pub fn setSucceeded(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        item.succeeded = true;
        item.done = true;
    }

    /// Mark `item` as failed and update its text.
    pub fn setFailed(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        item.succeeded = false;
        item.done = true;
    }

    /// Mark `item` as completed with a warning (amber ⚠ glyph).
    /// Shown as "warning" (neither succeeded nor failed).
    pub fn setWarning(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        // We repurpose: done=true but succeeded=null means "warning".
        item.succeeded = null;
        item.done = true;
    }

    /// Stop all spinners and free the instance.
    pub fn stop(ms: *MultiSpinner) void {
        ms.stop_flag.store(true, .release);
        ms.thread.join();
        const alloc = ms.allocator;
        alloc.destroy(ms);
    }

    fn renderLoop(ms: *MultiSpinner) void {
        var frame: usize = 0;
        var first = true;

        while (!ms.stop_flag.load(.acquire)) {
            ms.renderFrame(frame, first) catch {};
            first = false;
            frame += 1;

            var min_interval: u64 = 80;
            for (ms.items[0..ms.count]) |*item| {
                min_interval = @min(min_interval, item.style.interval_ms);
            }

            ms.io.sleep(
                std.Io.Duration.fromMilliseconds(@intCast(min_interval)),
                .awake,
            ) catch break;
        }

        // Final render showing the terminal state after stop.
        ms.renderFrame(frame, first) catch {};
    }

    fn renderFrame(ms: *MultiSpinner, frame: usize, first: bool) !void {
        var fw: std.Io.File.Writer = .init(ms.file, ms.io, &ms.write_buf);
        const w = &fw.interface;

        if (!first) {
            try ms.colorizer.cursorUp(w, ms.count);
        }

        for (ms.items[0..ms.count]) |*item| {
            try ms.colorizer.clearLine(w);

            // Prefix
            if (item.prefix.len > 0) {
                try w.writeAll(item.prefix);
            }

            const frames = item.style.frames;
            const glyph = frames[frame % frames.len];

            if (item.done) {
                // Finished item: show result glyph.
                if (item.succeeded) |ok| {
                    const sym: []const u8 = if (ok) "✓" else "✗";
                    const sym_color: color_mod.Color = if (ok) .green else .red;
                    try color_mod.writeColored(w, ms.colorizer, sym, sym_color, .default, &.{.bold});
                } else {
                    // Warning state (done=true, succeeded=null).
                    try color_mod.writeColored(w, ms.colorizer, "⚠", .yellow, .default, &.{.bold});
                }
            } else {
                // Determine effective color for this item.
                const glyph_color = if (item.color != .default) item.color else item.style.color;
                try color_mod.writeColored(w, ms.colorizer, glyph, glyph_color, .default, item.style.attrs);
            }

            try w.print(" {s}", .{item.getTextSlice()});

            if (item.suffix.len > 0) {
                try w.print(" {s}", .{item.suffix});
            }

            try w.writeByte('\n');
        }

        try fw.flush();
    }
};

// ── Tests ──────────────────────────────────────────────────────────────────────

test "MultiBar init" {
    const io = std.Options.debug_threaded_io.?.io();
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var mb = MultiBar.init(io, invalid_file, terminal.TermInfo.dumb, .{});
    const b = mb.addBar(.{ .total = 100, .label = "Test" });
    b.setCompleted(50);
    try std.testing.expectEqual(@as(usize, 50), b.completed.load(.acquire));
    try std.testing.expectEqual(@as(usize, 1), mb.count);
}

test "SpinnerItem setText" {
    var item = SpinnerItem{};
    item.setText("Hello, world!");
    try std.testing.expectEqualSlices(u8, "Hello, world!", item.getTextSlice());
}

test "SpinnerItem prefix and suffix" {
    var item = SpinnerItem{
        .prefix = "  ",
        .suffix = "...",
    };
    item.setText("working");
    try std.testing.expectEqualSlices(u8, "working", item.getTextSlice());
    try std.testing.expectEqualSlices(u8, "  ", item.prefix);
    try std.testing.expectEqualSlices(u8, "...", item.suffix);
}
