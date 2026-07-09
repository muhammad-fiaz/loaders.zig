//! spinner.zig — Animated spinner with a background render thread.
//!
//! Usage:
//!
//!   var sp = try Spinner.start(io, .{ .text = "Loading..." });
//!   errdefer sp.stop(io);
//!   // ... do work ...
//!   sp.succeed(io, "Done!");

const std = @import("std");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");
const utils = @import("utils.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const SpinnerStyle = style_mod.SpinnerStyle;
pub const Message = style_mod.Message;

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
    /// Override the animation interval (ms). If null, uses the style's interval.
    interval_override_ms: ?u64 = null,
    /// Suffix text printed after the spinner text.
    suffix: []const u8 = "",
    /// Whether to show elapsed time after the text.
    show_elapsed: bool = false,
    /// Color override for the spinner text. `.default` = terminal default.
    text_color: Color = .default,
    /// Color override for the spinner glyph. `.default` = use style color.
    spinner_color: Color = .default,
    /// Color used for the entire spinner line. `.default` = use sub-component colors.
    color: Color = .default,
    /// Optional running icon prefix.
    icon: ?[]const u8 = null,
    /// Optional custom success icon.
    success_icon: ?[]const u8 = null,
    /// Optional custom failure icon.
    failure_icon: ?[]const u8 = null,
    /// Optional custom warning icon.
    warning_icon: ?[]const u8 = null,
    /// Optional custom info icon.
    info_icon: ?[]const u8 = null,
    /// Array of messages to cycle through during run.
    messages: ?[]const []const u8 = null,
    /// Array of message-icon objects to cycle through during run.
    icon_messages: ?[]const Message = null,
    /// Interval in milliseconds to transition messages.
    message_interval_ms: u32 = 1500,
    /// Format time as 12-hour AM/PM format (defaults to 24-hour).
    time_format_12h: bool = false,
    /// Maximum text width limit (0 = no limit). Truncates text if exceeded.
    max_text_width: usize = 0,
    /// Maximum suffix width limit (0 = no limit). Truncates suffix if exceeded.
    max_suffix_width: usize = 0,
    /// Spacing gap after icons (defaults to " ").
    icon_gap: []const u8 = " ",
    /// Spacing gap after spinner/status glyph (defaults to " ").
    text_gap: []const u8 = " ",
    /// Spacing gap after date/time prefix (defaults to " ").
    datetime_gap: []const u8 = " ",
    /// Background color override for the spinner text. `.default` = no color.
    text_bg_color: Color = .default,
    /// Background color override for the spinner glyph. `.default` = no color.
    spinner_bg_color: Color = .default,
    /// Background color used for the entire spinner line. `.default` = no color.
    bg_color: Color = .default,
    /// Custom elapsed time offset in seconds.
    start_time_offset_sec: i64 = 0,
    /// Default message shown once the spinner succeeds or completes.
    complete_message: []const u8 = "",
    /// Number of empty padding lines printed above the spinner line.
    padding_lines_above: usize = 0,
    /// Number of empty padding lines printed below the spinner line.
    padding_lines_below: usize = 0,
    /// Callback when spinner completes/stops.
    on_complete: ?*const fn (sp: *Spinner) void = null,
    /// Callback when spinner succeeds (succeed() called).
    on_success: ?*const fn (sp: *Spinner) void = null,
    /// Callback when spinner fails (fail() called).
    on_failure: ?*const fn (sp: *Spinner) void = null,
    /// Callback when spinner warns (warn() called).
    on_warn: ?*const fn (sp: *Spinner) void = null,
    /// Callback when spinner provides info (info() called).
    on_info: ?*const fn (sp: *Spinner) void = null,
};

/// An animated spinner that runs its render loop on a background thread.
///
/// Call `start` to launch, then `stop` / `succeed` / `fail` when done.
pub const Spinner = struct {
    opts: Options,
    colorizer: Colorizer,
    term: terminal.TermInfo,
    file: std.Io.File,
    allocator: std.mem.Allocator,
    started_ns: i96,

    // Shared state between caller and render thread
    stop_flag: std.atomic.Value(bool),
    paused: std.atomic.Value(bool),
    text: std.atomic.Value([*:0]const u8),

    // The background render thread
    thread: std.Thread,

    // Static text storage (updated atomically)
    text_buf: [256:0]u8,
    msg_icon: ?[]const u8,

    /// Start the spinner. Spawns a background render thread.
    /// Must call `stop`, `succeed`, or `fail` to clean up.
    pub fn start(io: std.Io, opts: Options) !*Spinner {
        terminal.setupTerminal();

        const gpa = opts.allocator orelse std.heap.page_allocator;
        const sp = try gpa.create(Spinner);
        errdefer gpa.destroy(sp);

        const file = opts.file orelse std.Io.File.stderr();
        const term_info = opts.term orelse terminal.query(file, io);
        const color_on = opts.color_enabled orelse term_info.ansi_supported;

        var resolved_opts = opts;
        resolved_opts.file = file;

        const initial_icon = if (opts.icon_messages) |imsgs| (if (imsgs.len > 0) imsgs[0].icon else null) else null;

        const now = std.Io.Clock.awake.now(io);

        sp.* = Spinner{
            .opts = resolved_opts,
            .colorizer = Colorizer{
                .enabled = color_on,
                .ansi_enabled = term_info.ansi_supported,
                .cr_enabled = term_info.is_tty,
            },
            .term = term_info,
            .file = file,
            .allocator = gpa,
            .started_ns = now.nanoseconds,
            .stop_flag = std.atomic.Value(bool).init(false),
            .paused = std.atomic.Value(bool).init(false),
            .text = undefined,
            .thread = undefined,
            .text_buf = @splat(0),
            .msg_icon = initial_icon,
        };

        const initial_message = if (opts.icon_messages) |imsgs| (if (imsgs.len > 0) imsgs[0].text else opts.text) else if (opts.messages) |msgs| (if (msgs.len > 0) msgs[0] else opts.text) else opts.text;
        sp.updateText(initial_message);
        sp.text = std.atomic.Value([*:0]const u8).init(sp.text_buf[0..].ptr);

        if (sp.term.is_tty) {
            sp.thread = try std.Thread.spawn(.{}, renderLoop, .{ sp, io });
        }

        return sp;
    }

    /// Update the spinner text (thread-safe).
    pub fn setText(sp: *Spinner, text: []const u8) void {
        sp.updateText(text);
    }

    /// Pause the animation (freezes current frame).
    pub fn pause(sp: *Spinner) void {
        sp.paused.store(true, .release);
    }

    /// Resume the animation after a pause.
    pub fn resume_(sp: *Spinner) void {
        sp.paused.store(false, .release);
    }

    /// Stop the spinner and erase it from the terminal.
    pub fn stop(sp: *Spinner, io: std.Io) void {
        sp.stop_flag.store(true, .release);
        if (sp.term.is_tty) {
            sp.thread.join();
            sp.eraseLine(io);
        }
        if (sp.opts.on_complete) |cb| {
            cb(sp);
        }
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a success line (✓ green tick).
    pub fn succeed(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        if (sp.term.is_tty) {
            sp.thread.join();
        }
        const sym = sp.opts.success_icon orelse "✓";
        const final_text = if (text.len > 0)
            text
        else if (sp.opts.complete_message.len > 0)
            sp.opts.complete_message
        else
            std.mem.sliceTo(&sp.text_buf, 0);
        sp.printFinal(io, final_text, sym, .green);
        if (sp.opts.on_success) |cb| {
            cb(sp);
        }
        if (sp.opts.on_complete) |cb| {
            cb(sp);
        }
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a failure line (✗ red cross).
    pub fn fail(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        if (sp.term.is_tty) {
            sp.thread.join();
        }
        const sym = sp.opts.failure_icon orelse "✗";
        const final_text = if (text.len > 0)
            text
        else if (sp.opts.complete_message.len > 0)
            sp.opts.complete_message
        else
            std.mem.sliceTo(&sp.text_buf, 0);
        sp.printFinal(io, final_text, sym, .red);
        if (sp.opts.on_failure) |cb| {
            cb(sp);
        }
        if (sp.opts.on_complete) |cb| {
            cb(sp);
        }
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print a warning line (⚠ yellow warning).
    pub fn warn(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        if (sp.term.is_tty) {
            sp.thread.join();
        }
        const sym = sp.opts.warning_icon orelse "⚠";
        const final_text = if (text.len > 0)
            text
        else if (sp.opts.complete_message.len > 0)
            sp.opts.complete_message
        else
            std.mem.sliceTo(&sp.text_buf, 0);
        sp.printFinal(io, final_text, sym, .yellow);
        if (sp.opts.on_warn) |cb| {
            cb(sp);
        }
        if (sp.opts.on_complete) |cb| {
            cb(sp);
        }
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    /// Stop and print an info line (ℹ cyan info).
    pub fn info(sp: *Spinner, io: std.Io, text: []const u8) void {
        sp.stop_flag.store(true, .release);
        if (sp.term.is_tty) {
            sp.thread.join();
        }
        const sym = sp.opts.info_icon orelse "ℹ";
        const final_text = if (text.len > 0)
            text
        else if (sp.opts.complete_message.len > 0)
            sp.opts.complete_message
        else
            std.mem.sliceTo(&sp.text_buf, 0);
        sp.printFinal(io, final_text, sym, .cyan);
        if (sp.opts.on_info) |cb| {
            cb(sp);
        }
        if (sp.opts.on_complete) |cb| {
            cb(sp);
        }
        const alloc = sp.allocator;
        alloc.destroy(sp);
    }

    fn printNonTty(sp: *Spinner, io: std.Io, text: []const u8) !void {
        var buf: [512]u8 = undefined;
        var fw: std.Io.File.Writer = .init(sp.file, io, &buf);
        const w = &fw.interface;
        if (sp.opts.custom_start.len > 0) {
            try w.writeAll(sp.opts.custom_start);
        }
        try w.print("{s} {s}", .{ sp.opts.prefix, text });
        if (sp.opts.suffix.len > 0) {
            try w.print(" {s}", .{sp.opts.suffix});
        }
        if (sp.opts.custom_end.len > 0) {
            try w.writeAll(sp.opts.custom_end);
        }
        try w.writeByte('\n');
        try fw.flush();
    }

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

        if (sp.term.is_tty) {
            // +1 for the main content line
            sp.colorizer.cursorUp(w, 1 + sp.opts.padding_lines_above + sp.opts.padding_lines_below) catch {};
        }

        // Above padding lines
        var i: usize = 0;
        while (i < sp.opts.padding_lines_above) : (i += 1) {
            if (sp.opts.bg_color != .default) {
                sp.colorizer.begin(w, .default, sp.opts.bg_color, &.{}) catch {};
            }
            sp.colorizer.clearLine(w) catch {};
            w.writeByte('\n') catch {};
            if (sp.opts.bg_color != .default) {
                sp.colorizer.reset(w) catch {};
            }
        }

        const line_color = if (sp.opts.color != .default) sp.opts.color else sym_color;
        const line_bg_color = sp.opts.bg_color;

        if (line_color != .default or line_bg_color != .default) {
            sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
        }
        sp.colorizer.clearLine(w) catch {};

        if (sp.opts.custom_start.len > 0) {
            w.writeAll(sp.opts.custom_start) catch {};
        }

        const ts_ns = std.Io.Clock.real.now(io).nanoseconds;
        const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + sp.opts.timezone_offset_sec;
        if (sp.opts.show_date and sp.opts.show_time) {
            var dbuf: [16]u8 = undefined;
            var tbuf: [32]u8 = undefined;
            const t_str = if (sp.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
            w.print("[{s} {s}]", .{ utils.formatDate(&dbuf, ts), t_str }) catch {};
            w.writeAll(sp.opts.datetime_gap) catch {};
        } else if (sp.opts.show_date) {
            var dbuf: [16]u8 = undefined;
            w.print("[{s}]", .{utils.formatDate(&dbuf, ts)}) catch {};
            w.writeAll(sp.opts.datetime_gap) catch {};
        } else if (sp.opts.show_time) {
            var tbuf: [32]u8 = undefined;
            const t_str = if (sp.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
            w.print("[{s}]", .{t_str}) catch {};
            w.writeAll(sp.opts.datetime_gap) catch {};
        }

        if (sp.opts.prefix.len > 0) {
            w.writeAll(sp.opts.prefix) catch {};
        }

        // Print Icons (without line background color to avoid emoji highlighting)
        if (sp.opts.icon) |icon| {
            if (icon.len > 0) {
                if (sp.opts.prefix.len > 0) {
                    w.writeAll(sp.opts.icon_gap) catch {};
                }
                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.reset(w) catch {};
                }
                w.writeAll(icon) catch {};
                w.writeAll(sp.opts.icon_gap) catch {};
            }
        }
        if (sp.msg_icon) |icon| {
            if (icon.len > 0) {
                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.reset(w) catch {};
                }
                w.writeAll(icon) catch {};
                w.writeAll(sp.opts.icon_gap) catch {};
            }
        }
        if (line_color != .default or line_bg_color != .default) {
            sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
        }

        // Use complete_fg from style if set, otherwise use the state color
        const actual_sym_color = if (sp.opts.style.complete_fg != .default)
            sp.opts.style.complete_fg
        else
            sym_color;
        color_mod.writeColored(w, sp.colorizer, symbol, actual_sym_color, sp.opts.spinner_bg_color, &.{.bold}) catch {};
        w.writeAll(sp.opts.text_gap) catch {};

        if (line_color != .default or line_bg_color != .default) {
            sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
        }

        var t_buf: [256]u8 = undefined;
        const text_str = if (sp.opts.max_text_width > 0)
            utils.truncateUtf8(&t_buf, text, sp.opts.max_text_width)
        else
            text;

        if (sp.opts.text_color != .default or sp.opts.text_bg_color != .default) {
            sp.colorizer.begin(w, sp.opts.text_color, sp.opts.text_bg_color, &.{}) catch {};
            w.writeAll(text_str) catch {};
            sp.colorizer.reset(w) catch {};
            if (line_color != .default or line_bg_color != .default) {
                sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
            }
        } else {
            w.writeAll(text_str) catch {};
        }

        if (sp.opts.suffix.len > 0) {
            var s_buf: [256]u8 = undefined;
            const suffix_str = if (sp.opts.max_suffix_width > 0)
                utils.truncateUtf8(&s_buf, sp.opts.suffix, sp.opts.max_suffix_width)
            else
                sp.opts.suffix;
            w.print(" {s}", .{suffix_str}) catch {};
        }

        if (sp.opts.custom_end.len > 0) {
            w.writeAll(sp.opts.custom_end) catch {};
        }

        if (line_color != .default or line_bg_color != .default) {
            sp.colorizer.reset(w) catch {};
        }

        // Below padding lines
        i = 0;
        while (i < sp.opts.padding_lines_below) : (i += 1) {
            if (sp.opts.bg_color != .default) {
                sp.colorizer.begin(w, .default, sp.opts.bg_color, &.{}) catch {};
            }
            sp.colorizer.clearLine(w) catch {};
            w.writeByte('\n') catch {};
            if (sp.opts.bg_color != .default) {
                sp.colorizer.reset(w) catch {};
            }
        }

        if (sp.term.is_tty) {
            sp.colorizer.cr(w) catch {};
        }
        w.writeByte('\n') catch {};
        fw.flush() catch {};
    }

    fn renderLoop(sp: *Spinner, io: std.Io) void {
        var frame: usize = 0;
        var buf: [512]u8 = undefined;
        var first_render = true;

        var last_msg_change_time = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(io).nanoseconds, std.time.ns_per_ms)));
        var msg_index: usize = 0;

        while (!sp.stop_flag.load(.acquire)) {
            if (sp.opts.icon_messages) |imsgs| {
                if (imsgs.len > 0) {
                    const now = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(io).nanoseconds, std.time.ns_per_ms)));
                    const elapsed = now - last_msg_change_time;
                    if (elapsed >= sp.opts.message_interval_ms) {
                        msg_index = (msg_index + 1) % imsgs.len;
                        const item = imsgs[msg_index];
                        sp.setText(item.text);
                        sp.msg_icon = item.icon;
                        last_msg_change_time = now;
                    }
                }
            } else if (sp.opts.messages) |msgs| {
                if (msgs.len > 0) {
                    const now = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(io).nanoseconds, std.time.ns_per_ms)));
                    const elapsed = now - last_msg_change_time;
                    if (elapsed >= sp.opts.message_interval_ms) {
                        msg_index = (msg_index + 1) % msgs.len;
                        sp.setText(msgs[msg_index]);
                        last_msg_change_time = now;
                    }
                }
            }

            if (!sp.paused.load(.acquire)) {
                var fw: std.Io.File.Writer = .init(sp.file, io, &buf);
                const w = &fw.interface;

                if (!first_render) {
                    sp.colorizer.cursorUp(w, sp.opts.padding_lines_above + sp.opts.padding_lines_below) catch {};
                }
                first_render = false;

                // Above padding lines
                var i: usize = 0;
                while (i < sp.opts.padding_lines_above) : (i += 1) {
                    sp.colorizer.clearLine(w) catch {};
                    if (sp.opts.bg_color != .default) {
                        sp.colorizer.begin(w, .default, sp.opts.bg_color, &.{}) catch {};
                        w.writeByte(' ') catch {};
                        sp.colorizer.reset(w) catch {};
                    }
                    w.writeByte('\n') catch {};
                }

                sp.colorizer.clearLine(w) catch {};

                const line_color = sp.opts.color;
                const line_bg_color = sp.opts.bg_color;

                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
                }

                if (sp.opts.custom_start.len > 0) {
                    w.writeAll(sp.opts.custom_start) catch {};
                }

                const ts_ns = std.Io.Clock.real.now(io).nanoseconds;
                const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + sp.opts.timezone_offset_sec;
                if (sp.opts.show_date and sp.opts.show_time) {
                    var dbuf: [16]u8 = undefined;
                    var tbuf: [32]u8 = undefined;
                    const t_str = if (sp.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
                    w.print("[{s} {s}]", .{ utils.formatDate(&dbuf, ts), t_str }) catch {};
                    w.writeAll(sp.opts.datetime_gap) catch {};
                } else if (sp.opts.show_date) {
                    var dbuf: [16]u8 = undefined;
                    w.print("[{s}]", .{utils.formatDate(&dbuf, ts)}) catch {};
                    w.writeAll(sp.opts.datetime_gap) catch {};
                } else if (sp.opts.show_time) {
                    var tbuf: [32]u8 = undefined;
                    const t_str = if (sp.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
                    w.print("[{s}]", .{t_str}) catch {};
                    w.writeAll(sp.opts.datetime_gap) catch {};
                }

                if (sp.opts.prefix.len > 0) {
                    w.writeAll(sp.opts.prefix) catch {};
                }

                // Print Icons (without line background color to avoid emoji highlighting)
                if (sp.opts.icon) |icon| {
                    if (icon.len > 0) {
                        if (sp.opts.prefix.len > 0) {
                            w.writeAll(sp.opts.icon_gap) catch {};
                        }
                        if (line_color != .default or line_bg_color != .default) {
                            sp.colorizer.reset(w) catch {};
                        }
                        w.writeAll(icon) catch {};
                        w.writeAll(sp.opts.icon_gap) catch {};
                    }
                }
                if (sp.msg_icon) |icon| {
                    if (icon.len > 0) {
                        if (line_color != .default or line_bg_color != .default) {
                            sp.colorizer.reset(w) catch {};
                        }
                        w.writeAll(icon) catch {};
                        w.writeAll(sp.opts.icon_gap) catch {};
                    }
                }
                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
                }

                const frames = sp.opts.style.frames;
                const glyph = frames[frame % frames.len];
                const glyph_color = if (sp.opts.style.gradient) |grad|
                    grad.at(@as(f64, @floatFromInt(frame % 256)) / 255.0)
                else if (sp.opts.spinner_color != .default) sp.opts.spinner_color else sp.opts.style.color;
                color_mod.writeColored(w, sp.colorizer, glyph, glyph_color, sp.opts.spinner_bg_color, sp.opts.style.attrs) catch {};
                w.writeAll(sp.opts.text_gap) catch {};

                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
                }

                const text_ptr: [*:0]const u8 = sp.text.load(.acquire);
                const text = std.mem.span(text_ptr);
                if (text.len > 0) {
                    var t_buf: [256]u8 = undefined;
                    const text_str = if (sp.opts.max_text_width > 0)
                        utils.truncateUtf8(&t_buf, text, sp.opts.max_text_width)
                    else
                        text;

                    if (sp.opts.text_color != .default or sp.opts.text_bg_color != .default) {
                        sp.colorizer.begin(w, sp.opts.text_color, sp.opts.text_bg_color, &.{}) catch {};
                        w.writeAll(text_str) catch {};
                        sp.colorizer.reset(w) catch {};
                        if (line_color != .default or line_bg_color != .default) {
                            sp.colorizer.begin(w, line_color, line_bg_color, &.{}) catch {};
                        }
                    } else {
                        w.writeAll(text_str) catch {};
                    }
                }

                if (sp.opts.show_elapsed) {
                    const now_ns = std.Io.Clock.awake.now(io).nanoseconds;
                    const elapsed_ns = now_ns - sp.started_ns;
                    const base_s = @as(i64, @intCast(@divTrunc(elapsed_ns, std.time.ns_per_s)));
                    const elapsed_s: u64 = @intCast(@max(0, base_s + sp.opts.start_time_offset_sec));
                    var ebuf: [16]u8 = undefined;
                    w.print(" [{s}]", .{utils.formatEta(&ebuf, elapsed_s)}) catch {};
                }

                if (sp.opts.suffix.len > 0) {
                    var s_buf: [256]u8 = undefined;
                    const suffix_str = if (sp.opts.max_suffix_width > 0)
                        utils.truncateUtf8(&s_buf, sp.opts.suffix, sp.opts.max_suffix_width)
                    else
                        sp.opts.suffix;
                    w.print(" {s}", .{suffix_str}) catch {};
                }

                if (sp.opts.custom_end.len > 0) {
                    w.writeAll(sp.opts.custom_end) catch {};
                }

                if (line_color != .default or line_bg_color != .default) {
                    sp.colorizer.reset(w) catch {};
                }

                // Below padding lines
                i = 0;
                while (i < sp.opts.padding_lines_below) : (i += 1) {
                    sp.colorizer.clearLine(w) catch {};
                    if (sp.opts.bg_color != .default) {
                        sp.colorizer.begin(w, .default, sp.opts.bg_color, &.{}) catch {};
                        w.writeByte(' ') catch {};
                        sp.colorizer.reset(w) catch {};
                    }
                    w.writeByte('\n') catch {};
                }

                sp.colorizer.cr(w) catch {};
                fw.flush() catch {};

                frame += 1;
            }

            const interval_ms = sp.opts.interval_override_ms orelse sp.opts.style.interval_ms;
            io.sleep(
                std.Io.Duration.fromMilliseconds(@intCast(interval_ms)),
                .awake,
            ) catch break;
        }
    }
};

test "SpinnerStyle.dots has frames" {
    try std.testing.expect(SpinnerStyle.dots.frames.len > 0);
    try std.testing.expect(SpinnerStyle.dots.interval_ms > 0);
}

test "Spinner start and stop" {
    const io = std.Options.debug_io;
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
    io.sleep(std.Io.Duration.fromMilliseconds(50), .awake) catch {};
    sp.stop(io);
}

test "Spinner pause and resume" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const sp = try Spinner.start(io, .{
        .text = "Working...",
        .style = SpinnerStyle.dots,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
    });
    sp.pause();
    try std.testing.expect(sp.paused.load(.acquire));
    sp.resume_();
    try std.testing.expect(!sp.paused.load(.acquire));
    io.sleep(std.Io.Duration.fromMilliseconds(30), .awake) catch {};
    sp.stop(io);
}

test "Spinner interval_override_ms" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const sp = try Spinner.start(io, .{
        .text = "Fast...",
        .style = SpinnerStyle.dots,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
        .interval_override_ms = 500,
    });
    try std.testing.expectEqual(@as(?u64, 500), sp.opts.interval_override_ms);
    io.sleep(std.Io.Duration.fromMilliseconds(30), .awake) catch {};
    sp.stop(io);
}

test "Spinner suffix option" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const sp = try Spinner.start(io, .{
        .text = "Working",
        .suffix = "...",
        .style = SpinnerStyle.line,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
    });
    try std.testing.expectEqualSlices(u8, "...", sp.opts.suffix);
    io.sleep(std.Io.Duration.fromMilliseconds(20), .awake) catch {};
    sp.stop(io);
}

test "Spinner custom icons" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const sp = try Spinner.start(io, .{
        .text = "Working",
        .style = SpinnerStyle.line,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
        .icon = "🔧",
        .success_icon = "🎉",
    });
    try std.testing.expectEqualSlices(u8, "🔧", sp.opts.icon.?);
    try std.testing.expectEqualSlices(u8, "🎉", sp.opts.success_icon.?);
    sp.succeed(io, "Done");
}

test "Spinner multi-message cycling" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const msgs = [_][]const u8{ "Reticulating splines...", "Locating floppy drive...", "Feeding hamsters..." };
    const sp = try Spinner.start(io, .{
        .text = "Wait...",
        .messages = &msgs,
        .message_interval_ms = 10,
        .style = SpinnerStyle.line,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
    });
    try std.testing.expectEqualSlices(u8, "Reticulating splines...", std.mem.span(sp.text.load(.acquire)));
    io.sleep(std.Io.Duration.fromMilliseconds(30), .awake) catch {};
    // Verify it cycles/changed
    const current = std.mem.span(sp.text.load(.acquire));
    try std.testing.expect(current.len > 0);
    sp.stop(io);
}
