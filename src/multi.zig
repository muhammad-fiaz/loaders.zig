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
const utils = @import("utils.zig");

pub const Bar = bar_mod.Bar;
pub const BarOptions = bar_mod.Options;
pub const SpinnerStyle = spinner_mod.SpinnerStyle;
pub const Colorizer = color_mod.Colorizer;
pub const Message = bar_mod.Message;

/// Maximum number of bars in a `MultiBar`.
pub const max_bars = 32;

/// Options for `MultiBar`.
pub const MultiBarOptions = struct {
    /// Hide the cursor during rendering (restored on `done()`).
    hide_cursor: bool = true,
    /// Message printed after all bars complete.
    complete_message: []const u8 = "",
    /// Optional header line printed above all bars.
    header: []const u8 = "",
    /// Optional footer line printed below all bars.
    footer: []const u8 = "",
    /// Number of empty lines to print between individual bars.
    spacing_lines: usize = 0,
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
    done_flag: bool,
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
                .cr_enabled = ti.is_tty,
            },
            .term = ti,
            .first_render = true,
            .write_buf = undefined,
            .file = file,
            .mbopts = mbopts,
            .done_flag = false,
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
            .label_bg_color = opts.label_bg_color,
            .total = opts.total,
            .width = opts.width,
            .style = opts.style,
            .show_percent = opts.show_percent,
            .percent_color = opts.percent_color,
            .percent_bg_color = opts.percent_bg_color,
            .bracket_color = opts.bracket_color,
            .bracket_bg_color = opts.bracket_bg_color,
            .show_count = opts.show_count,
            .show_elapsed = opts.show_elapsed,
            .show_eta = opts.show_eta,
            .show_rate = opts.show_rate,
            .unit_is_bytes = opts.unit_is_bytes,
            .unit = opts.unit,
            .message = opts.message,
            .complete_message = opts.complete_message,
            .suffix = opts.suffix,
            .file = mb.file,
            .term = mb.term,
            .color_enabled = mb.colorizer.enabled,
            .smooth_rate = opts.smooth_rate,
            .smooth_alpha = opts.smooth_alpha,
            .template = opts.template,
            .fill_color = opts.fill_color,
            .fill_bg_color = opts.fill_bg_color,
            .empty_color = opts.empty_color,
            .empty_bg_color = opts.empty_bg_color,
            .color = opts.color,
            .bg_color = opts.bg_color,
            .icon = opts.icon,
            .success_icon = opts.success_icon,
            .failure_icon = opts.failure_icon,
            .warning_icon = opts.warning_icon,
            .info_icon = opts.info_icon,
            .disable_new_line = opts.disable_new_line,
            .messages = opts.messages,
            .icon_messages = opts.icon_messages,
            .message_interval_ms = opts.message_interval_ms,
            .on_progress = opts.on_progress,
            .on_complete = opts.on_complete,
            .on_success = opts.on_success,
            .on_failure = opts.on_failure,
            .on_warn = opts.on_warn,
            .on_info = opts.on_info,
            .time_format_12h = opts.time_format_12h,
            .max_label_width = opts.max_label_width,
            .max_message_width = opts.max_message_width,
            .max_suffix_width = opts.max_suffix_width,
            .padding_lines_above = opts.padding_lines_above,
            .padding_lines_below = opts.padding_lines_below,
            .initial_completed = opts.initial_completed,
            .fill_gradient = opts.fill_gradient,
            .empty_gradient = opts.empty_gradient,
            .complete_color = opts.complete_color,
            .custom_start = opts.custom_start,
            .custom_end = opts.custom_end,
            .show_date = opts.show_date,
            .show_time = opts.show_time,
            .timezone_offset_sec = opts.timezone_offset_sec,
            .icon_gap = opts.icon_gap,
            .label_gap = opts.label_gap,
            .datetime_gap = opts.datetime_gap,
            .min_interval_ms = opts.min_interval_ms,
            .start_time_offset_sec = opts.start_time_offset_sec,
            .is_multibar = true,
        });
        mb.count += 1;
        return &mb.bars[i];
    }

    /// Render all bars in-place. Call this from your main loop.
    pub fn render(mb: *MultiBar) void {
        mb.renderInner() catch {};
    }

    fn renderInner(mb: *MultiBar) !void {
        if (!mb.term.is_tty and !mb.done_flag) {
            return;
        }
        if (mb.term.is_tty) {
            mb.term = terminal.query(mb.file, mb.io);
        }
        var fw: std.Io.File.Writer = .init(mb.file, mb.io, &mb.write_buf);
        const w = &fw.interface;

        const header_lines: usize = if (mb.mbopts.header.len > 0) 1 else 0;
        const footer_lines: usize = if (mb.mbopts.footer.len > 0) 1 else 0;
        var total_lines = header_lines + footer_lines;
        for (mb.bars[0..mb.count]) |*b| {
            total_lines += b.opts.padding_lines_above + 1 + b.opts.padding_lines_below;
        }
        if (mb.count > 1) {
            total_lines += (mb.count - 1) * mb.mbopts.spacing_lines;
        }

        if (!mb.first_render) {
            try mb.colorizer.cursorUp(w, total_lines);
        } else if (mb.mbopts.hide_cursor) {
            try mb.colorizer.hideCursor(w);
        }
        mb.first_render = false;

        // Header
        if (mb.mbopts.header.len > 0) {
            try mb.colorizer.clearLine(w);
            try w.writeAll(mb.mbopts.header);
            try w.writeByte('\n');
        }

        // Render each bar onto its own line using a single writer.
        for (mb.bars[0..mb.count], 0..) |*b, idx| {
            if (b.opts.width == 0) {
                b.term = mb.term;
            }

            if (idx > 0) {
                var s: usize = 0;
                while (s < mb.mbopts.spacing_lines) : (s += 1) {
                    try mb.colorizer.clearLine(w);
                    try w.writeByte('\n');
                }
            }

            var i: usize = 0;
            while (i < b.opts.padding_lines_above) : (i += 1) {
                if (b.opts.bg_color != .default) {
                    try mb.colorizer.begin(w, .default, b.opts.bg_color, &.{});
                }
                try mb.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (b.opts.bg_color != .default) {
                    try mb.colorizer.reset(w);
                }
            }

            const line_color = if (b.opts.color != .default)
                b.opts.color
            else if (b.status_color != .default)
                b.status_color
            else
                .default;

            if (line_color != .default or b.opts.bg_color != .default) {
                try mb.colorizer.begin(w, line_color, b.opts.bg_color, &.{});
            }
            try mb.colorizer.clearLine(w);
            try b.renderContent(w);
            if (line_color != .default or b.opts.bg_color != .default) {
                try mb.colorizer.reset(w);
            }
            try w.writeByte('\n');

            i = 0;
            while (i < b.opts.padding_lines_below) : (i += 1) {
                if (b.opts.bg_color != .default) {
                    try mb.colorizer.begin(w, .default, b.opts.bg_color, &.{});
                }
                try mb.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (b.opts.bg_color != .default) {
                    try mb.colorizer.reset(w);
                }
            }
        }

        // Footer
        if (mb.mbopts.footer.len > 0) {
            try mb.colorizer.clearLine(w);
            try w.writeAll(mb.mbopts.footer);
            try w.writeByte('\n');
        }

        try fw.flush();
    }

    /// Mark all bars as done and print a final newline.
    pub fn done(mb: *MultiBar) void {
        mb.done_flag = true;
        for (mb.bars[0..mb.count]) |*b| {
            b.done_flag.store(true, .release);
            if (b.opts.complete_message.len > 0) {
                b.setMessage(b.opts.complete_message);
            }
        }
        mb.render();

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

/// Maximum number of spinner items in a `MultiSpinner`.
pub const max_spinners = 32;

/// State for a single spinner item in a `MultiSpinner`.
pub const SpinnerItem = struct {
    text: [256:0]u8 = @splat(0),
    style: SpinnerStyle = SpinnerStyle.dots,
    /// Set to finish this item. `succeeded` controls the result glyph.
    done: bool = false,
    /// null = running, true = success (✓), false = failure (✗).
    succeeded: ?bool = null,
    /// Color used for the entire spinner item line. `.default` = use sub-component colors.
    color: color_mod.Color = .default,
    /// Color override for the spinner text. `.default` = terminal default.
    text_color: color_mod.Color = .default,
    /// Color override for the spinner glyph. `.default` = use style color or global color.
    spinner_color: color_mod.Color = .default,
    /// Background color used for the entire spinner item line.
    bg_color: color_mod.Color = .default,
    /// Background color override for the spinner text.
    text_bg_color: color_mod.Color = .default,
    /// Background color override for the spinner glyph.
    spinner_bg_color: color_mod.Color = .default,
    /// Number of empty padding lines printed above this spinner line.
    padding_lines_above: usize = 0,
    /// Number of empty padding lines printed below this spinner line.
    padding_lines_below: usize = 0,
    /// Prefix string printed before the spinner glyph on each frame.
    prefix: []const u8 = "",
    /// Suffix string printed after the text on each frame.
    suffix: []const u8 = "",
    /// Optional running icon prefix.
    icon: ?[]const u8 = null,
    msg_icon: ?[]const u8 = null,
    success_icon: ?[]const u8 = null,
    /// Optional custom failure icon.
    failure_icon: ?[]const u8 = null,
    /// Optional custom warning icon.
    warning_icon: ?[]const u8 = null,
    /// Optional custom info icon.
    info_icon: ?[]const u8 = null,
    /// Completion status.
    status: enum { running, success, failure, warning, info } = .running,
    /// Array of messages to cycle through.
    messages: ?[]const []const u8 = null,
    /// Array of message-icon objects to cycle through.
    icon_messages: ?[]const Message = null,
    /// Interval in milliseconds to transition messages.
    message_interval_ms: u64 = 1500,
    /// Current message index.
    msg_index: usize = 0,
    /// Timestamp of last message transition.
    last_msg_change_time: i64 = 0,
    /// Maximum text width limit (0 = no limit). Truncates text if exceeded.
    max_text_width: usize = 0,
    /// Maximum suffix width limit (0 = no limit). Truncates suffix if exceeded.
    max_suffix_width: usize = 0,

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
    is_tty: bool,
    stop_flag: std.atomic.Value(bool),
    thread: std.Thread,
    write_buf: [8192]u8,
    allocator: std.mem.Allocator,
    icon_gap: []const u8 = " ",
    text_gap: []const u8 = " ",
    spacing_lines: usize = 0,

    /// Start the multi-spinner renderer. Returns a heap-allocated instance.
    pub fn start(io: std.Io, file: std.Io.File, color_enabled: ?bool, maybe_allocator: ?std.mem.Allocator) !*MultiSpinner {
        terminal.setupTerminal();
        const ti = terminal.query(file, io);
        const color_on = color_enabled orelse ti.ansi_supported;

        const allocator = maybe_allocator orelse std.heap.page_allocator;
        const ms = try allocator.create(MultiSpinner);
        errdefer allocator.destroy(ms);
        ms.* = .{
            .io = io,
            .items = undefined,
            .count = 0,
            .colorizer = .{
                .enabled = color_on,
                .ansi_enabled = ti.ansi_supported,
                .cr_enabled = ti.is_tty,
            },
            .file = file,
            .is_tty = ti.is_tty,
            .stop_flag = std.atomic.Value(bool).init(false),
            .thread = undefined,
            .write_buf = undefined,
            .allocator = allocator,
            .icon_gap = " ",
            .text_gap = " ",
            .spacing_lines = 0,
        };

        if (ti.is_tty) {
            ms.thread = try std.Thread.spawn(.{}, renderLoop, .{ms});
        } else {
            ms.thread = undefined;
        }
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
        item.status = .success;
        item.succeeded = true;
        item.done = true;
    }

    /// Mark `item` as failed and update its text.
    pub fn setFailed(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        item.status = .failure;
        item.succeeded = false;
        item.done = true;
    }

    /// Mark `item` as completed with a warning (amber ⚠ glyph).
    /// Shown as "warning" (neither succeeded nor failed).
    pub fn setWarning(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        item.status = .warning;
        item.succeeded = null;
        item.done = true;
    }

    /// Mark `item` as completed with info (cyan ℹ glyph).
    pub fn setInfo(ms: *MultiSpinner, item: *SpinnerItem, msg: []const u8) void {
        _ = ms;
        item.setText(msg);
        item.status = .info;
        item.succeeded = null;
        item.done = true;
    }

    /// Stop all spinners and free the instance.
    pub fn stop(ms: *MultiSpinner) void {
        ms.stop_flag.store(true, .release);
        if (ms.is_tty) {
            ms.thread.join();
        } else {
            ms.renderFrame(0, true) catch {};
        }
        const alloc = ms.allocator;
        alloc.destroy(ms);
    }

    fn renderLoop(ms: *MultiSpinner) void {
        var frame: usize = 0;
        var first = true;

        while (!ms.stop_flag.load(.acquire)) {
            const now = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(ms.io).nanoseconds, std.time.ns_per_ms)));
            for (ms.items[0..ms.count]) |*item| {
                if (!item.done) {
                    if (item.icon_messages) |imsgs| {
                        if (imsgs.len > 0) {
                            if (item.last_msg_change_time == 0) {
                                item.last_msg_change_time = now;
                                item.setText(imsgs[0].text);
                                item.msg_icon = imsgs[0].icon;
                            }
                            const elapsed = now - item.last_msg_change_time;
                            if (elapsed >= item.message_interval_ms) {
                                item.msg_index = (item.msg_index + 1) % imsgs.len;
                                const msg_item = imsgs[item.msg_index];
                                item.setText(msg_item.text);
                                item.msg_icon = msg_item.icon;
                                item.last_msg_change_time = now;
                            }
                        }
                    } else if (item.messages) |msgs| {
                        if (msgs.len > 0) {
                            if (item.last_msg_change_time == 0) {
                                item.last_msg_change_time = now;
                                item.setText(msgs[0]);
                            }
                            const elapsed = now - item.last_msg_change_time;
                            if (elapsed >= item.message_interval_ms) {
                                item.msg_index = (item.msg_index + 1) % msgs.len;
                                item.setText(msgs[item.msg_index]);
                                item.last_msg_change_time = now;
                            }
                        }
                    }
                }
            }

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

        var total_lines: usize = 0;
        for (ms.items[0..ms.count]) |*item| {
            total_lines += item.padding_lines_above + 1 + item.padding_lines_below;
        }
        if (ms.count > 1) {
            total_lines += (ms.count - 1) * ms.spacing_lines;
        }

        if (!first) {
            try ms.colorizer.cursorUp(w, total_lines);
        }

        for (ms.items[0..ms.count], 0..) |*item, idx| {
            if (idx > 0) {
                var s: usize = 0;
                while (s < ms.spacing_lines) : (s += 1) {
                    try ms.colorizer.clearLine(w);
                    try w.writeByte('\n');
                }
            }
            var i: usize = 0;
            while (i < item.padding_lines_above) : (i += 1) {
                if (item.bg_color != .default) {
                    try ms.colorizer.begin(w, .default, item.bg_color, &.{});
                }
                try ms.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (item.bg_color != .default) {
                    try ms.colorizer.reset(w);
                }
            }

            const status_col: color_mod.Color = if (item.done) switch (item.status) {
                .success => .green,
                .failure => .red,
                .warning => .yellow,
                .info => .cyan,
                .running => if (item.succeeded) |ok| (if (ok) .green else .red) else .yellow,
            } else .default;

            const line_color = if (item.color != .default)
                item.color
            else if (status_col != .default)
                status_col
            else
                .default;
            const line_bg_color = item.bg_color;

            if (line_color != .default or line_bg_color != .default) {
                try ms.colorizer.begin(w, line_color, line_bg_color, &.{});
            }
            try ms.colorizer.clearLine(w);

            if (item.prefix.len > 0) {
                try w.writeAll(item.prefix);
            }

            // Print Icons (without line background color to avoid emoji highlighting)
            if (item.icon) |icon| {
                if (icon.len > 0) {
                    if (line_color != .default or line_bg_color != .default) {
                        try ms.colorizer.reset(w);
                    }
                    try w.writeAll(icon);
                    try w.writeAll(ms.icon_gap);
                }
            }
            if (item.msg_icon) |icon| {
                if (icon.len > 0) {
                    if (line_color != .default or line_bg_color != .default) {
                        try ms.colorizer.reset(w);
                    }
                    try w.writeAll(icon);
                    try w.writeAll(ms.icon_gap);
                }
            }
            if (line_color != .default or line_bg_color != .default) {
                try ms.colorizer.begin(w, line_color, line_bg_color, &.{});
            }

            if (item.done) {
                switch (item.status) {
                    .success => {
                        const sym = item.success_icon orelse "✓";
                        const sym_color = if (item.style.complete_fg != .default) item.style.complete_fg else .green;
                        try color_mod.writeColored(w, ms.colorizer, sym, sym_color, item.spinner_bg_color, &.{.bold});
                    },
                    .failure => {
                        const sym = item.failure_icon orelse "✗";
                        const sym_color = if (item.style.complete_fg != .default) item.style.complete_fg else .red;
                        try color_mod.writeColored(w, ms.colorizer, sym, sym_color, item.spinner_bg_color, &.{.bold});
                    },
                    .warning => {
                        const sym = item.warning_icon orelse "⚠";
                        const sym_color = if (item.style.complete_fg != .default) item.style.complete_fg else .yellow;
                        try color_mod.writeColored(w, ms.colorizer, sym, sym_color, item.spinner_bg_color, &.{.bold});
                    },
                    .info => {
                        const sym = item.info_icon orelse "ℹ";
                        const sym_color = if (item.style.complete_fg != .default) item.style.complete_fg else .cyan;
                        try color_mod.writeColored(w, ms.colorizer, sym, sym_color, item.spinner_bg_color, &.{.bold});
                    },
                    .running => {
                        // Fallback logic for backward compatibility
                        if (item.succeeded) |ok| {
                            const sym = if (ok) (item.success_icon orelse "✓") else (item.failure_icon orelse "✗");
                            const col: color_mod.Color = if (ok) .green else .red;
                            try color_mod.writeColored(w, ms.colorizer, sym, col, item.spinner_bg_color, &.{.bold});
                        } else {
                            const sym = item.warning_icon orelse "⚠";
                            try color_mod.writeColored(w, ms.colorizer, sym, .yellow, item.spinner_bg_color, &.{.bold});
                        }
                    },
                }
                try w.writeAll(ms.text_gap);
                if (line_color != .default or line_bg_color != .default) {
                    try ms.colorizer.begin(w, line_color, line_bg_color, &.{});
                }
            } else {
                const frames = item.style.frames;
                const glyph = frames[frame % frames.len];
                const glyph_color = if (item.style.gradient) |grad|
                    grad.at(@as(f64, @floatFromInt(frame % 256)) / 255.0)
                else if (item.spinner_color != .default) item.spinner_color else (if (line_color != .default) line_color else item.style.color);
                try color_mod.writeColored(w, ms.colorizer, glyph, glyph_color, item.spinner_bg_color, item.style.attrs);
                try w.writeAll(ms.text_gap);
                if (line_color != .default or line_bg_color != .default) {
                    try ms.colorizer.begin(w, line_color, line_bg_color, &.{});
                }
            }

            const item_text = item.getTextSlice();
            var t_buf: [256]u8 = undefined;
            const text_str = if (item.max_text_width > 0)
                utils.truncateUtf8(&t_buf, item_text, item.max_text_width)
            else
                item_text;

            if (item.text_color != .default or item.text_bg_color != .default) {
                try ms.colorizer.begin(w, item.text_color, item.text_bg_color, &.{});
                try w.writeAll(text_str);
                try ms.colorizer.reset(w);
                if (line_color != .default or line_bg_color != .default) {
                    try ms.colorizer.begin(w, line_color, line_bg_color, &.{});
                }
            } else {
                try w.writeAll(text_str);
            }

            if (item.suffix.len > 0) {
                var s_buf: [256]u8 = undefined;
                const suffix_str = if (item.max_suffix_width > 0)
                    utils.truncateUtf8(&s_buf, item.suffix, item.max_suffix_width)
                else
                    item.suffix;
                try w.print(" {s}", .{suffix_str});
            }

            if (line_color != .default or line_bg_color != .default) {
                try ms.colorizer.reset(w);
            }

            try w.writeByte('\n');

            var j: usize = 0;
            while (j < item.padding_lines_below) : (j += 1) {
                if (item.bg_color != .default) {
                    try ms.colorizer.begin(w, .default, item.bg_color, &.{});
                }
                try ms.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (item.bg_color != .default) {
                    try ms.colorizer.reset(w);
                }
            }
        }

        try fw.flush();
    }
};

test "MultiBar init" {
    const io = std.Options.debug_io;
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

test "MultiBar max_bars is 32" {
    try std.testing.expectEqual(@as(usize, 32), max_bars);
}

test "MultiBar header and footer options" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const mb = MultiBar.init(io, invalid_file, terminal.TermInfo.dumb, .{
        .header = "=== Build Pipeline ===",
        .footer = "=== Complete ===",
    });
    try std.testing.expectEqualSlices(u8, "=== Build Pipeline ===", mb.mbopts.header);
    try std.testing.expectEqualSlices(u8, "=== Complete ===", mb.mbopts.footer);
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

test "max_spinners is 32" {
    try std.testing.expectEqual(@as(usize, 32), max_spinners);
}

test "MultiSpinner custom icons and statuses" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const ms = try MultiSpinner.start(io, invalid_file, false, std.testing.allocator);
    errdefer ms.stop();

    const item = ms.addItem("Task A", .dots);
    item.icon = "🔧";
    item.success_icon = "🎉";
    item.failure_icon = "💥";
    item.warning_icon = "⚠️";
    item.info_icon = "📢";

    try std.testing.expectEqualSlices(u8, "🔧", item.icon.?);
    try std.testing.expectEqualSlices(u8, "🎉", item.success_icon.?);

    ms.setSucceeded(item, "Success!");
    try std.testing.expect(item.done);
    try std.testing.expectEqual(item.status, .success);

    ms.setFailed(item, "Failed!");
    try std.testing.expectEqual(item.status, .failure);

    ms.setWarning(item, "Warn!");
    try std.testing.expectEqual(item.status, .warning);

    ms.setInfo(item, "Info!");
    try std.testing.expectEqual(item.status, .info);

    ms.stop();
}
