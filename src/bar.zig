//! bar.zig — Animated progress bar.
//!
//! Usage (5 lines):
//!
//!   var bar = Bar.init(io, .{});
//!   defer bar.done();
//!   bar.setTotal(100);
//!   for (0..100) |i| {
//!       bar.setCompleted(i + 1);
//!       bar.render();
//!       try io.sleep(...);
//!   }

const std = @import("std");
const utils = @import("utils.zig");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");
const format_mod = @import("format.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const BarStyle = style_mod.BarStyle;
pub const SpinnerStyle = style_mod.SpinnerStyle;
pub const Message = style_mod.Message;

/// Configuration passed to `Bar.init`.
pub const Options = struct {
    /// Label printed before the bar. May be empty.
    label: []const u8 = "",
    /// Color used to render the label text. `.default` = no color.
    label_color: Color = .default,
    /// Background color for the label text. `.default` = no color.
    label_bg_color: Color = .default,
    /// Total number of units (0 = indeterminate).
    total: usize = 0,
    /// Width of the bar in columns (0 = auto from terminal width).
    width: u16 = 0,
    /// Visual style.
    style: BarStyle = .{},
    /// Whether to show percentage.
    show_percent: bool = true,
    /// Color used for the percentage indicator. `.default` = no color.
    percent_color: Color = .default,
    /// Background color for the percentage indicator. `.default` = no color.
    percent_bg_color: Color = .default,
    /// Color used for the bracket characters. `.default` = no color.
    bracket_color: Color = .default,
    /// Background color for the bracket characters. `.default` = no color.
    bracket_bg_color: Color = .default,
    /// Background color for filled blocks shorthand (sets style.fill_bg if .default).
    fill_bg_color: Color = .default,
    /// Background color for empty blocks shorthand (sets style.empty_bg if .default).
    empty_bg_color: Color = .default,
    /// Whether to show `current/total` counts.
    show_count: bool = false,
    /// Whether to show elapsed time.
    show_elapsed: bool = false,
    /// Whether to show ETA.
    show_eta: bool = false,
    /// Whether to show bytes-per-second rate (set `unit_is_bytes = true`).
    show_rate: bool = false,
    /// When true, `completed` is treated as bytes and rates are formatted
    /// as B/s, KiB/s, etc.
    unit_is_bytes: bool = false,
    /// Custom unit label appended to count (e.g. "files", "items").
    unit: []const u8 = "",
    /// Dynamic message appended after all indicators. Can be changed with
    /// `bar.setMessage(...)` for per-frame updates.
    message: []const u8 = "",
    /// Message shown once the bar reaches 100%. Replaces `message` on `done()`.
    complete_message: []const u8 = "",
    /// Custom suffix format string (appended after all other indicators).
    suffix: []const u8 = "",
    /// File to render to (null = stderr).
    file: ?std.Io.File = null,
    /// Terminal info override. If null, auto-detected from `file`.
    term: ?terminal.TermInfo = null,
    /// Enable color. If null, auto-detected from terminal.
    color_enabled: ?bool = null,
    /// Printed at the absolute start of the progress bar line.
    custom_start: []const u8 = "",
    /// Printed at the absolute end of the progress bar line.
    custom_end: []const u8 = "",
    /// Whether to show current date [YYYY-MM-DD].
    show_date: bool = false,
    /// Whether to show current time [HH:MM:SS].
    show_time: bool = false,
    /// Offset in seconds to adjust timezone from UTC (e.g. 19800 for UTC+5:30).
    timezone_offset_sec: i32 = 0,
    /// Use exponential moving average to smooth rate/ETA display.
    smooth_rate: bool = false,
    /// EMA alpha for rate smoothing (0.0–1.0, default 0.2).
    smooth_alpha: f64 = 0.2,
    /// Custom format template. When non-empty, overrides standard layout.
    /// Supports: {label} {bar} {percent} {elapsed} {eta} {rate} {count} {time} {date} {message} {spinner}
    template: []const u8 = "",
    /// Minimum milliseconds between renders (0 = no throttle).
    min_interval_ms: u64 = 0,
    /// Fill color shorthand (sets style.fill_fg if style.fill_fg is .default).
    fill_color: Color = .default,
    /// Empty color shorthand (sets style.empty_fg if style.empty_fg is .default).
    empty_color: Color = .default,
    /// Fill gradient shorthand (sets style.fill_gradient if null).
    fill_gradient: ?style_mod.Gradient = null,
    /// Empty gradient shorthand (sets style.empty_gradient if null).
    empty_gradient: ?style_mod.Gradient = null,
    /// Color used for the entire progress bar line. `.default` = use sub-component colors.
    color: Color = .default,
    /// Background color used for the entire progress bar line. `.default` = no color.
    bg_color: Color = .default,
    /// Color for the bar when complete (100%). `.default` = use style.fill_fg or gradient.
    complete_color: Color = .default,
    /// Custom elapsed time offset in seconds.
    start_time_offset_sec: i64 = 0,
    /// Number of empty padding lines printed above the progress bar line.
    padding_lines_above: usize = 0,
    /// Number of empty padding lines printed below the progress bar line.
    padding_lines_below: usize = 0,
    /// Initial completed count.
    initial_completed: usize = 0,
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
    /// Disable newline for non-TTY output.
    disable_new_line: bool = true,
    /// Array of messages to cycle through during run.
    messages: ?[]const []const u8 = null,
    /// Array of message-icon objects to cycle through during run.
    icon_messages: ?[]const Message = null,
    /// Interval in milliseconds to transition messages.
    message_interval_ms: u32 = 1500,
    /// Callback on progress update.
    on_progress: ?*const fn (bar: *Bar, completed: usize, total: usize) void = null,
    /// Callback when progress bar completes/stops.
    on_complete: ?*const fn (bar: *Bar) void = null,
    /// Callback when bar succeeds (succeed() called).
    on_success: ?*const fn (bar: *Bar) void = null,
    /// Callback when bar fails (fail() called).
    on_failure: ?*const fn (bar: *Bar) void = null,
    /// Callback when bar warns (warn() called).
    on_warn: ?*const fn (bar: *Bar) void = null,
    /// Callback when bar provides info (info() called).
    on_info: ?*const fn (bar: *Bar) void = null,
    /// Format time as 12-hour AM/PM format (defaults to 24-hour).
    time_format_12h: bool = false,
    /// Maximum label width limit (0 = no limit). Truncates label if exceeded.
    max_label_width: usize = 0,
    /// Maximum dynamic message width limit (0 = no limit). Truncates message if exceeded.
    max_message_width: usize = 0,
    /// Maximum suffix width limit (0 = no limit). Truncates suffix if exceeded.
    max_suffix_width: usize = 0,
    /// Flag indicating that this bar is managed by a MultiBar parent layout.
    is_multibar: bool = false,
    /// Spacing gap after icons (defaults to " ").
    icon_gap: []const u8 = " ",
    /// Spacing gap after label (defaults to " ").
    label_gap: []const u8 = " ",
    /// Spacing gap after date/time prefix (defaults to " ").
    datetime_gap: []const u8 = " ",
};

/// A single animated progress bar.
///
/// Thread safety: `completed` is an atomic value, so `setCompleted` /
/// `increment` are safe to call from any thread. All rendering happens on
/// the thread that calls `render`.
pub const Bar = struct {
    io: std.Io,
    opts: Options,

    completed: std.atomic.Value(usize),
    total: std.atomic.Value(usize),
    started_ns: i96,
    done_flag: std.atomic.Value(bool),
    on_complete_called: std.atomic.Value(bool),

    colorizer: Colorizer,
    term: terminal.TermInfo,
    file: std.Io.File,

    last_line_len: usize,
    write_buf: [4096]u8,

    msg_buf: [512:0]u8,
    msg_len: usize,

    // Rate smoothing state
    smoothed_rate: f64,
    last_render_ns: i96,
    spinner_frame: usize,

    status_icon: ?[]const u8,
    status_color: Color,

    msg_index: usize,
    last_msg_change_time: i64,
    msg_icon: ?[]const u8,
    first_render: bool,

    /// Create a `Bar` and start timing.
    ///
    /// The returned struct is large — prefer stack or heap allocation.
    pub fn init(io: std.Io, opts: Options) Bar {
        terminal.setupTerminal();

        const file = opts.file orelse std.Io.File.stderr();
        const term_info = opts.term orelse terminal.query(file, io);
        const color_on = opts.color_enabled orelse term_info.ansi_supported;
        const now = std.Io.Clock.awake.now(io);

        const initial_message = if (opts.icon_messages) |imsgs| (if (imsgs.len > 0) imsgs[0].text else opts.message) else if (opts.messages) |msgs| (if (msgs.len > 0) msgs[0] else opts.message) else opts.message;
        var msg_buf: [512:0]u8 = @splat(0);
        const msg_len = blk: {
            const src = initial_message;
            const len = @min(src.len, 511);
            @memcpy(msg_buf[0..len], src[0..len]);
            msg_buf[len] = 0;
            break :blk len;
        };

        // Apply fill/empty color shorthands to the style
        var resolved_style = opts.style;
        if (opts.fill_color != .default and resolved_style.fill_fg == .default) {
            resolved_style.fill_fg = opts.fill_color;
        }
        if (opts.fill_bg_color != .default and resolved_style.fill_bg == .default) {
            resolved_style.fill_bg = opts.fill_bg_color;
        }
        if (opts.empty_color != .default and resolved_style.empty_fg == .default) {
            resolved_style.empty_fg = opts.empty_color;
        }
        if (opts.empty_bg_color != .default and resolved_style.empty_bg == .default) {
            resolved_style.empty_bg = opts.empty_bg_color;
        }
        if (opts.fill_gradient != null and resolved_style.fill_gradient == null) {
            resolved_style.fill_gradient = opts.fill_gradient;
        }
        if (opts.empty_gradient != null and resolved_style.empty_gradient == null) {
            resolved_style.empty_gradient = opts.empty_gradient;
        }
        if (opts.complete_color != .default and resolved_style.complete_fg == .default) {
            resolved_style.complete_fg = opts.complete_color;
        }

        var resolved_opts = opts;
        resolved_opts.style = resolved_style;

        const initial_icon = if (opts.icon_messages) |imsgs| (if (imsgs.len > 0) imsgs[0].icon else null) else null;

        return Bar{
            .io = io,
            .opts = resolved_opts,
            .completed = std.atomic.Value(usize).init(opts.initial_completed),
            .total = std.atomic.Value(usize).init(opts.total),
            .started_ns = now.nanoseconds,
            .done_flag = std.atomic.Value(bool).init(false),
            .on_complete_called = std.atomic.Value(bool).init(false),
            .colorizer = Colorizer{
                .enabled = color_on,
                .ansi_enabled = term_info.ansi_supported,
                .cr_enabled = term_info.is_tty,
            },
            .term = term_info,
            .file = file,
            .last_line_len = 0,
            .write_buf = undefined,
            .msg_buf = msg_buf,
            .msg_len = msg_len,
            .smoothed_rate = 0.0,
            .last_render_ns = now.nanoseconds,
            .spinner_frame = 0,
            .status_icon = null,
            .status_color = .default,
            .msg_index = 0,
            .last_msg_change_time = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(io).nanoseconds, std.time.ns_per_ms))),
            .msg_icon = initial_icon,
            .first_render = true,
        };
    }

    /// Update the total.
    pub fn setTotal(bar: *Bar, total: usize) void {
        bar.total.store(total, .release);
    }

    /// Atomically set the completed count.
    pub fn setCompleted(bar: *Bar, n: usize) void {
        bar.completed.store(n, .release);
        bar.triggerCallbacks(n);
    }

    /// Atomically increment the completed count by 1.
    pub fn increment(bar: *Bar) void {
        const prev = bar.completed.fetchAdd(1, .release);
        bar.triggerCallbacks(prev + 1);
    }

    /// Atomically increment the completed count by `n`.
    pub fn incrementBy(bar: *Bar, n: usize) void {
        const prev = bar.completed.fetchAdd(n, .release);
        bar.triggerCallbacks(prev + n);
    }

    fn triggerCallbacks(bar: *Bar, n: usize) void {
        const total = bar.total.load(.acquire);
        if (bar.opts.on_progress) |cb| {
            cb(bar, n, total);
        }
        if (total > 0 and n >= total) {
            if (!bar.on_complete_called.swap(true, .acq_rel)) {
                if (bar.opts.on_complete) |cb| {
                    cb(bar);
                }
            }
        }
    }

    /// Update the dynamic message shown after the indicators.
    /// Safe to call from any thread; rendered on the next `render()` call.
    pub fn setMessage(bar: *Bar, msg: []const u8) void {
        const len = @min(msg.len, 511);
        @memcpy(bar.msg_buf[0..len], msg[0..len]);
        bar.msg_buf[len] = 0;
        bar.msg_len = len;
    }

    /// Update the custom unit label.
    pub fn setUnit(bar: *Bar, unit: []const u8) void {
        bar.opts.unit = unit;
    }

    /// Reset progress to 0 and restart the elapsed timer.
    pub fn reset(bar: *Bar) void {
        bar.completed.store(0, .release);
        bar.smoothed_rate = 0.0;
        bar.spinner_frame = 0;
        const now = std.Io.Clock.awake.now(bar.io);
        bar.started_ns = now.nanoseconds;
        bar.last_render_ns = now.nanoseconds;
    }

    /// Return the current progress fraction (0.0–1.0).
    pub fn currentFraction(bar: *const Bar) f64 {
        const completed = bar.completed.load(.acquire);
        const total = bar.total.load(.acquire);
        return utils.fraction(completed, total);
    }

    /// Return elapsed milliseconds since init/reset.
    pub fn elapsedMs(bar: *const Bar) u64 {
        const now = std.Io.Clock.awake.now(bar.io);
        const elapsed_ns = now.nanoseconds - bar.started_ns;
        if (elapsed_ns <= 0) return 0;
        return @intCast(@divTrunc(elapsed_ns, std.time.ns_per_ms));
    }

    /// Render one frame to the terminal (call periodically from your loop).
    ///
    /// Write errors are silently ignored — the bar simply does not update.
    pub fn render(bar: *Bar) void {
        // Throttle
        if (bar.opts.min_interval_ms > 0) {
            const now_ns = std.Io.Clock.awake.now(bar.io).nanoseconds;
            const elapsed_ms: u64 = @intCast(@max(0, @divTrunc(now_ns - bar.last_render_ns, std.time.ns_per_ms)));
            if (elapsed_ms < bar.opts.min_interval_ms) return;
            bar.last_render_ns = now_ns;
        }
        bar.renderInner() catch {};
    }

    pub fn renderInner(bar: *Bar) !void {
        if (bar.opts.is_multibar) return;
        if (bar.opts.width == 0) {
            bar.term = terminal.query(bar.file, bar.io);
        }

        if (!bar.term.is_tty and bar.opts.disable_new_line and !bar.done_flag.load(.acquire)) {
            return;
        }

        var fw: std.Io.File.Writer = .init(bar.file, bar.io, &bar.write_buf);
        const w = &fw.interface;

        // 1. Move cursor to the start of the block if on TTY
        if (bar.term.is_tty and !bar.first_render) {
            try bar.colorizer.cursorUp(w, bar.opts.padding_lines_above + 1 + bar.opts.padding_lines_below);
        }
        bar.first_render = false;

        // 2. Print above padding lines
        var i: usize = 0;
        while (i < bar.opts.padding_lines_above) : (i += 1) {
            if (bar.opts.bg_color != .default) {
                try bar.colorizer.begin(w, .default, bar.opts.bg_color, &.{});
            }
            try bar.colorizer.clearLine(w);
            try w.writeByte('\n');
            if (bar.opts.bg_color != .default) {
                try bar.colorizer.reset(w);
            }
        }

        // 3. Print the main progress bar line
        const line_color = if (bar.opts.color != .default)
            bar.opts.color
        else if (bar.status_color != .default)
            bar.status_color
        else
            .default;

        if (line_color != .default or bar.opts.bg_color != .default) {
            try bar.colorizer.begin(w, line_color, bar.opts.bg_color, &.{});
        }
        try bar.colorizer.clearLine(w);
        try bar.renderContent(w);
        if (line_color != .default or bar.opts.bg_color != .default) {
            try bar.colorizer.reset(w);
        }
        if (bar.term.is_tty or !bar.opts.disable_new_line) {
            try w.writeByte('\n');
        }

        // 4. Print below padding lines
        i = 0;
        while (i < bar.opts.padding_lines_below) : (i += 1) {
            if (bar.opts.bg_color != .default) {
                try bar.colorizer.begin(w, .default, bar.opts.bg_color, &.{});
            }
            try bar.colorizer.clearLine(w);
            try w.writeByte('\n');
            if (bar.opts.bg_color != .default) {
                try bar.colorizer.reset(w);
            }
        }

        if (bar.term.is_tty) {
            try bar.colorizer.cr(w);
        }
        try fw.flush();
    }

    /// Render bar content into an external writer.
    ///
    /// Does NOT emit a clearLine prefix or a trailing newline/flush.
    /// Used by `MultiBar` to batch all bars through a single writer.
    pub fn renderContent(bar: *Bar, w: *std.Io.Writer) !void {
        const completed = bar.completed.load(.acquire);
        const total = bar.total.load(.acquire);

        // Cycle messages if configured
        if (bar.opts.icon_messages) |imsgs| {
            if (imsgs.len > 0 and !bar.done_flag.load(.acquire)) {
                const now = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(bar.io).nanoseconds, std.time.ns_per_ms)));
                if (bar.last_msg_change_time == 0) {
                    bar.last_msg_change_time = now;
                    bar.setMessage(imsgs[0].text);
                    bar.msg_icon = imsgs[0].icon;
                }
                const elapsed = now - bar.last_msg_change_time;
                if (elapsed >= bar.opts.message_interval_ms) {
                    bar.msg_index = (bar.msg_index + 1) % imsgs.len;
                    const item = imsgs[bar.msg_index];
                    bar.setMessage(item.text);
                    bar.msg_icon = item.icon;
                    bar.last_msg_change_time = now;
                }
            }
        } else if (bar.opts.messages) |msgs| {
            if (msgs.len > 0 and !bar.done_flag.load(.acquire)) {
                const now = @as(i64, @intCast(@divTrunc(std.Io.Clock.real.now(bar.io).nanoseconds, std.time.ns_per_ms)));
                if (bar.last_msg_change_time == 0) {
                    bar.last_msg_change_time = now;
                    bar.setMessage(msgs[0]);
                }
                const elapsed = now - bar.last_msg_change_time;
                if (elapsed >= bar.opts.message_interval_ms) {
                    bar.msg_index = (bar.msg_index + 1) % msgs.len;
                    bar.setMessage(msgs[bar.msg_index]);
                    bar.last_msg_change_time = now;
                }
            }
        }

        // Update rate smoothing
        if (bar.opts.smooth_rate) {
            const elapsed_s = bar.elapsedSeconds();
            if (elapsed_s > 0 and completed > 0) {
                const raw_rate = @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s));
                bar.smoothed_rate = utils.smoothRate(bar.smoothed_rate, raw_rate, bar.opts.smooth_alpha);
            }
        }

        // Template rendering path
        if (bar.opts.template.len > 0) {
            const elapsed_s = bar.elapsedSeconds();
            const eta_s = if (total > 0 and completed > 0) bar.etaSeconds(completed, total) else 0;
            const raw_rate = if (elapsed_s > 0 and completed > 0)
                @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s))
            else
                0.0;
            const display_rate = if (bar.opts.smooth_rate) bar.smoothed_rate else raw_rate;

            const ts_ns = std.Io.Clock.real.now(bar.io).nanoseconds;
            const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + bar.opts.timezone_offset_sec;

            const msg_slice = bar.msg_buf[0..bar.msg_len];
            const bar_width = effectiveBarWidth(bar, total);

            const line_color = if (bar.opts.color != .default)
                bar.opts.color
            else if (bar.status_color != .default)
                bar.status_color
            else
                .default;

            const ctx = format_mod.RenderCtx{
                .label = bar.opts.label,
                .completed = completed,
                .total = total,
                .elapsed_s = elapsed_s,
                .eta_s = eta_s,
                .rate = display_rate,
                .unit_is_bytes = bar.opts.unit_is_bytes,
                .unit = bar.opts.unit,
                .message = msg_slice,
                .timestamp_s = ts,
                .bar_width = bar_width,
                .style = bar.opts.style,
                .colorizer = bar.colorizer,
                .spinner_frame = bar.spinner_frame,
                .spinner_frames = &.{ "|", "/", "-", "\\" },
                .spinner_color = .default,
                .spinner_bg_color = .default,
                .icon = bar.opts.icon,
                .msg_icon = bar.msg_icon,
                .status_icon = bar.status_icon,
                .status_color = bar.status_color,
                .line_color = line_color,
                .line_bg_color = bar.opts.bg_color,
                .label_color = bar.opts.label_color,
                .label_bg_color = bar.opts.label_bg_color,
                .percent_color = bar.opts.percent_color,
                .percent_bg_color = bar.opts.percent_bg_color,
                .fill_color = bar.opts.fill_color,
                .fill_bg_color = bar.opts.fill_bg_color,
                .empty_color = bar.opts.empty_color,
                .empty_bg_color = bar.opts.empty_bg_color,
                .icon_gap = bar.opts.icon_gap,
                .label_gap = bar.opts.label_gap,
                .datetime_gap = bar.opts.datetime_gap,
            };
            try format_mod.renderTemplate(w, bar.opts.template, &ctx);
            bar.spinner_frame += 1;
            return;
        }

        // Standard rendering path
        const msg_slice = bar.msg_buf[0..bar.msg_len];

        // Truncate strings first so we have exact widths
        var l_buf: [256]u8 = undefined;
        const label_str = if (bar.opts.max_label_width > 0)
            utils.truncateUtf8(&l_buf, bar.opts.label, bar.opts.max_label_width)
        else
            bar.opts.label;

        var m_buf: [512]u8 = undefined;
        const message_str = if (bar.opts.max_message_width > 0)
            utils.truncateUtf8(&m_buf, msg_slice, bar.opts.max_message_width)
        else
            msg_slice;

        var s_buf: [256]u8 = undefined;
        const suffix_str = if (bar.opts.max_suffix_width > 0)
            utils.truncateUtf8(&s_buf, bar.opts.suffix, bar.opts.max_suffix_width)
        else
            bar.opts.suffix;

        // Determine which components to render dynamically
        var render_suffix = (bar.opts.suffix.len > 0);
        var render_message = (msg_slice.len > 0);
        var render_rate = (bar.opts.show_rate and completed > 0);
        var render_eta = (bar.opts.show_eta and total > 0 and completed > 0);
        var render_elapsed = (bar.opts.show_elapsed);
        var render_count = (bar.opts.show_count and total > 0);
        var render_datetime = (bar.opts.show_date or bar.opts.show_time);

        const custom_start_len = utils.stringDisplayWidth(bar.opts.custom_start);
        const custom_end_len = utils.stringDisplayWidth(bar.opts.custom_end);

        var icon_len: usize = 0;
        if (bar.status_icon) |s_icon| {
            icon_len = utils.stringDisplayWidth(s_icon) + 1;
        } else {
            if (bar.opts.icon) |icon| {
                if (icon.len > 0) icon_len += utils.stringDisplayWidth(icon) + 1;
            }
            if (bar.msg_icon) |icon| {
                if (icon.len > 0) icon_len += utils.stringDisplayWidth(icon) + 1;
            }
        }

        var dt_len: usize = 0;
        if (render_datetime) {
            if (bar.opts.show_date and bar.opts.show_time) {
                dt_len = if (bar.opts.time_format_12h) 25 else 22;
            } else if (bar.opts.show_date) {
                dt_len = 13;
            } else if (bar.opts.show_time) {
                dt_len = if (bar.opts.time_format_12h) 14 else 11;
            }
        }

        const label_len = if (bar.opts.label.len > 0) utils.stringDisplayWidth(label_str) + 1 else 0;

        // Calculate dynamic avail space
        var occupied_for_avail: usize = 0;
        occupied_for_avail += custom_start_len + custom_end_len + icon_len + dt_len + label_len;
        occupied_for_avail += utils.stringDisplayWidth(bar.opts.style.left_bracket) + utils.stringDisplayWidth(bar.opts.style.right_bracket);
        if (total > 0 and bar.opts.show_percent) occupied_for_avail += 5;
        if (render_count) {
            var cbuf: [64]u8 = undefined;
            occupied_for_avail += utils.stringDisplayWidth(utils.formatCount(&cbuf, completed, total, bar.opts.unit)) + 1;
        }
        if (render_elapsed) occupied_for_avail += 6;
        if (render_eta) occupied_for_avail += 10;
        if (render_rate) {
            const elapsed_s = bar.elapsedSeconds();
            if (elapsed_s > 0) {
                const raw_rate = @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s));
                const display_rate = if (bar.opts.smooth_rate) bar.smoothed_rate else raw_rate;
                var rbuf: [32]u8 = undefined;
                occupied_for_avail += utils.stringDisplayWidth(utils.formatRate(&rbuf, display_rate, bar.opts.unit_is_bytes)) + 1;
            }
        }
        if (render_message) occupied_for_avail += utils.stringDisplayWidth(message_str) + 1;
        if (render_suffix) occupied_for_avail += utils.stringDisplayWidth(suffix_str) + 1;

        const term_cols = bar.term.cols;
        const avail = @as(usize, term_cols) -| occupied_for_avail -| 1;
        const bar_width = if (bar.opts.width > 0)
            @max(2, @min(@as(usize, bar.opts.width), avail))
        else
            @max(2, avail);

        const bar_visual_len = bar_width + utils.stringDisplayWidth(bar.opts.style.left_bracket) + utils.stringDisplayWidth(bar.opts.style.right_bracket);
        const percent_len = if (total > 0 and bar.opts.show_percent) @as(usize, 5) else @as(usize, 0);

        var count_len: usize = 0;
        if (render_count) {
            var cbuf: [64]u8 = undefined;
            count_len = utils.stringDisplayWidth(utils.formatCount(&cbuf, completed, total, bar.opts.unit)) + 1;
        }

        const elapsed_len = if (render_elapsed) @as(usize, 6) else @as(usize, 0);
        const eta_len = if (render_eta) @as(usize, 10) else @as(usize, 0);

        var rate_len: usize = 0;
        if (render_rate) {
            const elapsed_s = bar.elapsedSeconds();
            if (elapsed_s > 0) {
                const raw_rate = @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s));
                const display_rate = if (bar.opts.smooth_rate) bar.smoothed_rate else raw_rate;
                var rbuf: [32]u8 = undefined;
                rate_len = utils.stringDisplayWidth(utils.formatRate(&rbuf, display_rate, bar.opts.unit_is_bytes)) + 1;
            }
        }

        const message_len = if (render_message) utils.stringDisplayWidth(message_str) + 1 else 0;
        const suffix_len = if (render_suffix) utils.stringDisplayWidth(suffix_str) + 1 else 0;

        var total_expected = custom_start_len + custom_end_len + icon_len + dt_len + label_len + bar_visual_len + percent_len + count_len + elapsed_len + eta_len + rate_len + message_len + suffix_len;

        if (term_cols > 0) {
            const limit = term_cols -| 1;
            if (total_expected > limit and render_suffix) {
                total_expected -= suffix_len;
                render_suffix = false;
            }
            if (total_expected > limit and render_message) {
                total_expected -= message_len;
                render_message = false;
            }
            if (total_expected > limit and render_rate) {
                total_expected -= rate_len;
                render_rate = false;
            }
            if (total_expected > limit and render_eta) {
                total_expected -= eta_len;
                render_eta = false;
            }
            if (total_expected > limit and render_elapsed) {
                total_expected -= elapsed_len;
                render_elapsed = false;
            }
            if (total_expected > limit and render_count) {
                total_expected -= count_len;
                render_count = false;
            }
            if (total_expected > limit and render_datetime) {
                total_expected -= dt_len;
                render_datetime = false;
            }
        }

        // Resolve active line color: custom color takes precedence, status color is fallback when finished
        const line_color = if (bar.opts.color != .default)
            bar.opts.color
        else if (bar.status_color != .default)
            bar.status_color
        else
            .default;
        const line_bg_color = bar.opts.bg_color;

        // Apply global/status color if configured
        if (line_color != .default or line_bg_color != .default) {
            try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
        }

        // Print Custom Start
        if (bar.opts.custom_start.len > 0) {
            try w.writeAll(bar.opts.custom_start);
        }

        // Print Icons (without line background color to avoid emoji highlighting)
        if (bar.status_icon) |s_icon| {
            if (line_color != .default or line_bg_color != .default) {
                try bar.colorizer.reset(w);
            }
            try color_mod.writeColored(w, bar.colorizer, s_icon, bar.status_color, .default, &.{.bold});
            try w.writeAll(bar.opts.icon_gap);
            if (line_color != .default or line_bg_color != .default) {
                try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
            }
        } else {
            var printed_any = false;
            if (bar.opts.icon) |icon| {
                if (icon.len > 0) {
                    if (line_color != .default or line_bg_color != .default) {
                        try bar.colorizer.reset(w);
                    }
                    try w.writeAll(icon);
                    try w.writeAll(bar.opts.icon_gap);
                    printed_any = true;
                }
            }
            if (bar.msg_icon) |icon| {
                if (icon.len > 0) {
                    if (line_color != .default or line_bg_color != .default) {
                        try bar.colorizer.reset(w);
                    }
                    try w.writeAll(icon);
                    try w.writeAll(bar.opts.icon_gap);
                    printed_any = true;
                }
            }
            if (printed_any and (line_color != .default or line_bg_color != .default)) {
                try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
            }
        }

        // Print Date/Time
        if (render_datetime) {
            const ts_ns = std.Io.Clock.real.now(bar.io).nanoseconds;
            const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + bar.opts.timezone_offset_sec;
            if (bar.opts.show_date and bar.opts.show_time) {
                var dbuf: [16]u8 = undefined;
                var tbuf: [32]u8 = undefined;
                const t_str = if (bar.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
                try w.print("[{s} {s}]", .{ utils.formatDate(&dbuf, ts), t_str });
                try w.writeAll(bar.opts.datetime_gap);
            } else if (bar.opts.show_date) {
                var dbuf: [16]u8 = undefined;
                try w.print("[{s}]", .{utils.formatDate(&dbuf, ts)});
                try w.writeAll(bar.opts.datetime_gap);
            } else if (bar.opts.show_time) {
                var tbuf: [32]u8 = undefined;
                const t_str = if (bar.opts.time_format_12h) utils.formatTime12h(&tbuf, ts) else utils.formatTime(&tbuf, ts);
                try w.print("[{s}]", .{t_str});
                try w.writeAll(bar.opts.datetime_gap);
            }
        }

        // Print Label
        if (bar.opts.label.len > 0) {
            if (bar.opts.label_color != .default or bar.opts.label_bg_color != .default) {
                try color_mod.writeColored(w, bar.colorizer, label_str, bar.opts.label_color, bar.opts.label_bg_color, &.{});
                try w.writeAll(bar.opts.label_gap);
                if (line_color != .default or line_bg_color != .default) {
                    try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
                }
            } else {
                try w.print("{s}", .{label_str});
                try w.writeAll(bar.opts.label_gap);
            }
        }

        // Left bracket
        if (bar.opts.bracket_color != .default or bar.opts.bracket_bg_color != .default) {
            try bar.colorizer.begin(w, bar.opts.bracket_color, bar.opts.bracket_bg_color, &.{});
        }
        try w.writeAll(bar.opts.style.left_bracket);
        if (bar.opts.bracket_color != .default or bar.opts.bracket_bg_color != .default) {
            try bar.colorizer.reset(w);
            if (line_color != .default or line_bg_color != .default) {
                try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
            }
        }

        if (total == 0) {
            try renderIndeterminate(bar, w, completed, bar_width);
        } else {
            try renderDeterminate(bar, w, completed, total, bar_width);
        }

        if (line_color != .default or line_bg_color != .default) {
            try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
        }

        // Right bracket
        if (bar.opts.bracket_color != .default or bar.opts.bracket_bg_color != .default) {
            try bar.colorizer.begin(w, bar.opts.bracket_color, bar.opts.bracket_bg_color, &.{});
        }
        try w.writeAll(bar.opts.style.right_bracket);
        if (bar.opts.bracket_color != .default or bar.opts.bracket_bg_color != .default) {
            try bar.colorizer.reset(w);
            if (line_color != .default or line_bg_color != .default) {
                try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
            }
        }

        // Percentage
        if (total > 0 and bar.opts.show_percent) {
            const frac = utils.fraction(completed, total);
            if (bar.opts.percent_color != .default or bar.opts.percent_bg_color != .default) {
                try bar.colorizer.begin(w, bar.opts.percent_color, bar.opts.percent_bg_color, &.{});
            }
            var pbuf: [8]u8 = undefined;
            try w.print(" {s}", .{utils.formatPercent(&pbuf, frac)});
            if (bar.opts.percent_color != .default or bar.opts.percent_bg_color != .default) {
                try bar.colorizer.reset(w);
                if (line_color != .default or line_bg_color != .default) {
                    try bar.colorizer.begin(w, line_color, line_bg_color, &.{});
                }
            }
        }

        // Print Count
        if (render_count) {
            var cbuf: [64]u8 = undefined;
            try w.print(" {s}", .{utils.formatCount(&cbuf, completed, total, bar.opts.unit)});
        }

        // Print Elapsed
        if (render_elapsed) {
            const elapsed_s = bar.elapsedSeconds();
            var buf: [16]u8 = undefined;
            try w.print(" {s}", .{utils.formatEta(&buf, elapsed_s)});
        }

        // Print ETA
        if (render_eta) {
            const eta = bar.etaSeconds(completed, total);
            var buf: [16]u8 = undefined;
            try w.print(" ETA {s}", .{utils.formatEta(&buf, eta)});
        }

        // Print Rate
        if (render_rate) {
            const elapsed_s = bar.elapsedSeconds();
            if (elapsed_s > 0) {
                const raw_rate = @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s));
                const display_rate = if (bar.opts.smooth_rate) bar.smoothed_rate else raw_rate;
                var rbuf: [32]u8 = undefined;
                try w.print(" {s}", .{utils.formatRate(&rbuf, display_rate, bar.opts.unit_is_bytes)});
            }
        }

        // Print Dynamic message
        if (render_message) {
            try w.print(" {s}", .{message_str});
        }

        // Print Suffix
        if (render_suffix) {
            try w.print(" {s}", .{suffix_str});
        }

        // Print Custom End
        if (bar.opts.custom_end.len > 0) {
            try w.writeAll(bar.opts.custom_end);
        }

        // Reset global color
        if (line_color != .default or line_bg_color != .default) {
            try bar.colorizer.reset(w);
        }
    }

    fn renderDeterminate(
        bar: *Bar,
        w: *std.Io.Writer,
        completed: usize,
        total: usize,
        bar_width: usize,
    ) !void {
        const frac = utils.fraction(completed, total);
        const filled = @as(usize, @intFromFloat(@as(f64, @floatFromInt(bar_width)) * frac));
        const filled_clamped = @min(filled, bar_width);
        const empty = bar_width - filled_clamped;
        const is_complete = bar.done_flag.load(.acquire) or (total > 0 and completed >= total);

        const s = bar.opts.style;
        const c = bar.colorizer;

        // Determine fill color: complete_fg > gradient > fill_fg
        const use_complete_color = is_complete and s.complete_fg != .default;

        if (filled_clamped > 0) {
            if (use_complete_color) {
                // Complete state: solid complete color
                try c.begin(w, s.complete_fg, s.fill_bg, s.attrs);
                if (s.tip.len > 0 and filled_clamped < bar_width) {
                    var i: usize = 0;
                    while (i < filled_clamped -| 1) : (i += 1) {
                        try w.writeAll(s.fill);
                    }
                    try w.writeAll(s.tip);
                } else {
                    var i: usize = 0;
                    while (i < filled_clamped) : (i += 1) {
                        try w.writeAll(s.fill);
                    }
                }
                try c.reset(w);
            } else if (s.fill_gradient) |grad| {
                // Gradient mode: each cell gets its own interpolated color
                if (s.tip.len > 0 and filled_clamped < bar_width) {
                    var i: usize = 0;
                    while (i < filled_clamped -| 1) : (i += 1) {
                        const t = if (bar_width > 1) @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(bar_width - 1)) else 0.0;
                        try c.begin(w, grad.at(t), s.fill_bg, s.attrs);
                        try w.writeAll(s.fill);
                        try c.reset(w);
                    }
                    const tip_t = if (bar_width > 1) @as(f64, @floatFromInt(filled_clamped -| 1)) / @as(f64, @floatFromInt(bar_width - 1)) else 1.0;
                    try c.begin(w, grad.at(tip_t), s.fill_bg, s.attrs);
                    try w.writeAll(s.tip);
                    try c.reset(w);
                } else {
                    var i: usize = 0;
                    while (i < filled_clamped) : (i += 1) {
                        const t = if (bar_width > 1) @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(bar_width - 1)) else 0.0;
                        try c.begin(w, grad.at(t), s.fill_bg, s.attrs);
                        try w.writeAll(s.fill);
                        try c.reset(w);
                    }
                }
            } else {
                // Solid color mode
                try c.begin(w, s.fill_fg, s.fill_bg, s.attrs);
                if (s.tip.len > 0 and filled_clamped < bar_width) {
                    var i: usize = 0;
                    while (i < filled_clamped -| 1) : (i += 1) {
                        try w.writeAll(s.fill);
                    }
                    try w.writeAll(s.tip);
                } else {
                    var i: usize = 0;
                    while (i < filled_clamped) : (i += 1) {
                        try w.writeAll(s.fill);
                    }
                }
                try c.reset(w);
            }
        }

        if (empty > 0) {
            if (s.empty_gradient) |grad| {
                // Gradient for empty portion
                var i: usize = 0;
                while (i < empty) : (i += 1) {
                    const offset = filled_clamped + i;
                    const t = if (bar_width > 1) @as(f64, @floatFromInt(offset)) / @as(f64, @floatFromInt(bar_width - 1)) else 0.0;
                    try c.begin(w, grad.at(t), s.empty_bg, &.{});
                    try w.writeAll(s.empty);
                    try c.reset(w);
                }
            } else {
                try c.begin(w, s.empty_fg, s.empty_bg, &.{});
                var i: usize = 0;
                while (i < empty) : (i += 1) {
                    try w.writeAll(s.empty);
                }
                try c.reset(w);
            }
        }
    }

    fn renderIndeterminate(
        bar: *Bar,
        w: *std.Io.Writer,
        tick: usize,
        bar_width: usize,
    ) !void {
        const bounce_len = @max(1, bar_width / 5);
        const range = bar_width -| bounce_len;
        const pos = if (range == 0) 0 else blk: {
            const cycle = range * 2;
            const t = tick % cycle;
            break :blk if (t <= range) t else cycle - t;
        };

        const s = bar.opts.style;
        const c = bar.colorizer;

        var i: usize = 0;
        while (i < bar_width) : (i += 1) {
            if (i >= pos and i < pos + bounce_len) {
                if (s.fill_gradient) |grad| {
                    const gt = if (bar_width > 1) @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(bar_width - 1)) else 0.0;
                    try c.begin(w, grad.at(gt), s.fill_bg, s.attrs);
                } else {
                    try c.begin(w, s.fill_fg, s.fill_bg, s.attrs);
                }
                try w.writeAll(s.fill);
                try c.reset(w);
            } else {
                try c.begin(w, s.empty_fg, s.empty_bg, &.{});
                try w.writeAll(s.empty);
                try c.reset(w);
            }
        }
    }

    /// Print a final "done" line and move to the next line.
    pub fn done(bar: *Bar) void {
        if (bar.done_flag.swap(true, .acq_rel)) return;
        if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        if (bar.status_icon == null) {
            if (bar.opts.icon != null or bar.opts.success_icon != null) {
                bar.status_icon = bar.opts.success_icon orelse "✓";
                bar.status_color = .green;
            }
        }
        bar.renderFinal() catch {};
        if (!bar.on_complete_called.swap(true, .acq_rel)) {
            if (bar.opts.on_complete) |cb| {
                cb(bar);
            }
        }
    }

    /// Stop and print a success line (✓ green tick).
    pub fn succeed(bar: *Bar, msg: []const u8) void {
        if (bar.done_flag.swap(true, .acq_rel)) return;
        bar.status_icon = bar.opts.success_icon orelse "✓";
        bar.status_color = .green;
        if (msg.len > 0) {
            bar.setMessage(msg);
        } else if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        bar.renderFinal() catch {};
        if (bar.opts.on_success) |cb| {
            cb(bar);
        }
        if (!bar.on_complete_called.swap(true, .acq_rel)) {
            if (bar.opts.on_complete) |cb| {
                cb(bar);
            }
        }
    }

    /// Stop and print a failure line (✗ red cross).
    pub fn fail(bar: *Bar, msg: []const u8) void {
        if (bar.done_flag.swap(true, .acq_rel)) return;
        bar.status_icon = bar.opts.failure_icon orelse "✗";
        bar.status_color = .red;
        if (msg.len > 0) {
            bar.setMessage(msg);
        } else if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        bar.renderFinal() catch {};
        if (bar.opts.on_failure) |cb| {
            cb(bar);
        }
        if (!bar.on_complete_called.swap(true, .acq_rel)) {
            if (bar.opts.on_complete) |cb| {
                cb(bar);
            }
        }
    }

    /// Stop and print a warning line (⚠ yellow warning).
    pub fn warn(bar: *Bar, msg: []const u8) void {
        if (bar.done_flag.swap(true, .acq_rel)) return;
        bar.status_icon = bar.opts.warning_icon orelse "⚠";
        bar.status_color = .yellow;
        if (msg.len > 0) {
            bar.setMessage(msg);
        } else if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        bar.renderFinal() catch {};
        if (bar.opts.on_warn) |cb| {
            cb(bar);
        }
        if (!bar.on_complete_called.swap(true, .acq_rel)) {
            if (bar.opts.on_complete) |cb| {
                cb(bar);
            }
        }
    }

    /// Stop and print an info line (ℹ cyan info).
    pub fn info(bar: *Bar, msg: []const u8) void {
        if (bar.done_flag.swap(true, .acq_rel)) return;
        bar.status_icon = bar.opts.info_icon orelse "ℹ";
        bar.status_color = .cyan;
        if (msg.len > 0) {
            bar.setMessage(msg);
        } else if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        bar.renderFinal() catch {};
        if (bar.opts.on_info) |cb| {
            cb(bar);
        }
        if (!bar.on_complete_called.swap(true, .acq_rel)) {
            if (bar.opts.on_complete) |cb| {
                cb(bar);
            }
        }
    }

    pub fn getActiveIcon(bar: *const Bar) []const u8 {
        if (bar.status_icon) |s_icon| {
            return s_icon;
        }
        return bar.opts.icon orelse "";
    }

    fn renderFinal(bar: *Bar) !void {
        if (bar.opts.is_multibar) return;
        var fw: std.Io.File.Writer = .init(bar.file, bar.io, &bar.write_buf);
        const w = &fw.interface;
        const total = bar.total.load(.acquire);
        if (total > 0) {
            bar.completed.store(total, .release);
        }
        try bar.renderInner();
        try w.writeByte('\n');
        try fw.flush();
    }

    fn effectiveBarWidth(bar: *const Bar, total: usize) usize {
        const term_cols = bar.term.cols;
        var occupied: usize = 0;

        occupied += utils.stringDisplayWidth(bar.opts.custom_start);
        occupied += utils.stringDisplayWidth(bar.opts.custom_end);

        if (bar.status_icon) |s_icon| {
            occupied += utils.stringDisplayWidth(s_icon) + 1;
        } else {
            if (bar.opts.icon) |icon| {
                if (icon.len > 0) occupied += utils.stringDisplayWidth(icon) + 1;
            }
            if (bar.msg_icon) |icon| {
                if (icon.len > 0) occupied += utils.stringDisplayWidth(icon) + 1;
            }
        }

        if (bar.opts.show_date and bar.opts.show_time) {
            occupied += if (bar.opts.time_format_12h) 25 else 22;
        } else if (bar.opts.show_date) {
            occupied += 13;
        } else if (bar.opts.show_time) {
            occupied += if (bar.opts.time_format_12h) 14 else 11;
        }

        if (bar.opts.label.len > 0) {
            occupied += utils.stringDisplayWidth(bar.opts.label) + 1;
        }

        occupied += utils.stringDisplayWidth(bar.opts.style.left_bracket) + utils.stringDisplayWidth(bar.opts.style.right_bracket);

        if (bar.opts.show_percent) {
            occupied += 5;
        }

        if (bar.opts.show_count) {
            var temp = total;
            var digits: usize = 0;
            if (temp == 0) digits = 1;
            while (temp > 0) : (temp /= 10) digits += 1;
            occupied += digits * 2 + 2;
        }

        if (bar.opts.show_elapsed) {
            occupied += 6;
        }

        if (bar.opts.show_eta) {
            occupied += 10;
        }

        if (bar.opts.show_rate) {
            occupied += 12;
        }

        if (bar.msg_len > 0) {
            occupied += utils.stringDisplayWidth(bar.msg_buf[0..bar.msg_len]) + 1;
        }

        if (bar.opts.suffix.len > 0) {
            occupied += utils.stringDisplayWidth(bar.opts.suffix) + 1;
        }

        const avail = @as(usize, term_cols) -| occupied -| 1;
        if (bar.opts.width > 0) {
            return @max(2, @min(@as(usize, bar.opts.width), avail));
        }
        return @max(2, avail);
    }

    fn elapsedSeconds(bar: *const Bar) u64 {
        const now = std.Io.Clock.awake.now(bar.io);
        const elapsed_ns = now.nanoseconds - bar.started_ns;
        const base_s = @as(i64, @intCast(@divTrunc(elapsed_ns, std.time.ns_per_s)));
        return @intCast(@max(0, base_s + bar.opts.start_time_offset_sec));
    }

    fn etaSeconds(bar: *const Bar, completed: usize, total: usize) u64 {
        if (completed >= total) return 0;
        const elapsed = @as(f64, @floatFromInt(bar.elapsedSeconds()));
        if (elapsed <= 0.0) return 0;
        const rate = @as(f64, @floatFromInt(completed)) / elapsed;
        if (rate <= 0.0) return 0;
        const remaining = @as(f64, @floatFromInt(total - completed));
        return @intFromFloat(remaining / rate);
    }
};

test "Bar.init default options" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 100,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setCompleted(50);
    try std.testing.expectEqual(@as(usize, 50), bar.completed.load(.acquire));
    try std.testing.expectEqual(@as(usize, 100), bar.total.load(.acquire));
}

test "Bar.increment" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.increment();
    bar.increment();
    try std.testing.expectEqual(@as(usize, 2), bar.completed.load(.acquire));
}

test "Bar.incrementBy" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 100,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.incrementBy(25);
    try std.testing.expectEqual(@as(usize, 25), bar.completed.load(.acquire));
}

test "Bar.setMessage" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setMessage("processing...");
    try std.testing.expectEqual(@as(usize, 13), bar.msg_len);
}

test "Bar.setUnit" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setUnit("files");
    try std.testing.expectEqualSlices(u8, "files", bar.opts.unit);
}

test "Bar.reset" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setCompleted(8);
    bar.reset();
    try std.testing.expectEqual(@as(usize, 0), bar.completed.load(.acquire));
    try std.testing.expectApproxEqAbs(0.0, bar.smoothed_rate, 1e-10);
}

test "Bar.currentFraction" {
    const io = std.Options.debug_io;
    var bar = Bar.init(io, .{
        .total = 100,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setCompleted(50);
    try std.testing.expectApproxEqAbs(0.5, bar.currentFraction(), 1e-10);
}

test "Bar renders without error" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
    });
    bar.setCompleted(5);
    bar.render();
    bar.done();
}

test "Bar fill_color shorthand applied" {
    const io = std.Options.debug_io;
    const bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .fill_color = .green,
    });
    const green_color: Color = .green;
    try std.testing.expectEqual(green_color, bar.opts.style.fill_fg);
}

test "Bar smooth_rate option accepted" {
    const io = std.Options.debug_io;
    const bar = Bar.init(io, .{
        .total = 100,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .smooth_rate = true,
        .smooth_alpha = 0.3,
    });
    try std.testing.expect(bar.opts.smooth_rate);
    try std.testing.expectApproxEqAbs(0.3, bar.opts.smooth_alpha, 1e-10);
}

test "Bar template option accepted" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 10,
        .label = "T",
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .file = invalid_file,
        .template = "{label} [{bar}] {percent}",
    });
    bar.setCompleted(5);
    bar.render();
    bar.done();
}

test "Bar template with custom separator" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .template = "{label} - {percent}",
    });
    bar.setCompleted(50);
    bar.render();
}

test "Bar custom icons and succeed/fail statuses" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .icon = "🚀",
        .success_icon = "✨",
        .failure_icon = "💥",
    });
    try std.testing.expectEqualSlices(u8, "🚀", bar.getActiveIcon());

    bar.succeed("Success!");
    try std.testing.expectEqualSlices(u8, "✨", bar.getActiveIcon());

    var bar2 = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .icon = "🚀",
        .success_icon = "✨",
        .failure_icon = "💥",
    });
    bar2.fail("Failure!");
    try std.testing.expectEqualSlices(u8, "💥", bar2.getActiveIcon());
}

test "Bar template with {icon} token" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .icon = "🚀",
        .template = "{icon} {percent}",
    });
    bar.setCompleted(50);
    bar.render();
}

test "Bar disable_new_line option" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .disable_new_line = true,
    });
    try std.testing.expect(bar.opts.disable_new_line);
    bar.render();
    bar.done();
}

test "Bar multi-message cycling" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    const msgs = [_][]const u8{ "Step 1...", "Step 2...", "Step 3..." };
    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .messages = &msgs,
        .message_interval_ms = 5,
        .disable_new_line = false,
    });
    try std.testing.expectEqualSlices(u8, "Step 1...", bar.msg_buf[0..bar.msg_len]);
    bar.render();
    io.sleep(std.Io.Duration.fromMilliseconds(15), .awake) catch {};
    bar.render();
    try std.testing.expectEqualSlices(u8, "Step 2...", bar.msg_buf[0..bar.msg_len]);
}

test "Bar callbacks and icon_messages" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };

    const TestCb = struct {
        var progress_calls: usize = 0;
        var complete_calls: usize = 0;
        pub fn progress(b: *Bar, completed: usize, total: usize) void {
            _ = b;
            _ = completed;
            _ = total;
            progress_calls += 1;
        }
        pub fn complete(b: *Bar) void {
            _ = b;
            complete_calls += 1;
        }
    };

    const msgs = [_]Message{
        .{ .text = "First", .icon = "⭐" },
        .{ .text = "Second", .icon = "🔥" },
    };

    var bar = Bar.init(io, .{
        .total = 10,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .icon_messages = &msgs,
        .message_interval_ms = 5,
        .disable_new_line = false,
        .on_progress = TestCb.progress,
        .on_complete = TestCb.complete,
    });

    try std.testing.expectEqualSlices(u8, "⭐", bar.msg_icon.?);
    try std.testing.expectEqualSlices(u8, "First", bar.msg_buf[0..bar.msg_len]);

    bar.setCompleted(5);
    try std.testing.expectEqual(@as(usize, 1), TestCb.progress_calls);

    bar.increment();
    try std.testing.expectEqual(@as(usize, 2), TestCb.progress_calls);

    bar.incrementBy(4); // reaches total (10)
    try std.testing.expectEqual(@as(usize, 3), TestCb.progress_calls);
    try std.testing.expectEqual(@as(usize, 1), TestCb.complete_calls);

    // Verify calling done() does not re-trigger completion callback
    bar.done();
    try std.testing.expectEqual(@as(usize, 1), TestCb.complete_calls);
}

test "Bar 12-hour format and size controls" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };

    var bar = Bar.init(io, .{
        .total = 10,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .time_format_12h = true,
        .max_label_width = 5,
        .max_message_width = 6,
        .max_suffix_width = 4,
        .label = "Super Long Label Here",
        .message = "Hello World Message",
        .suffix = "Some Long Suffix",
        .disable_new_line = true,
    });

    bar.render();

    try std.testing.expect(bar.opts.time_format_12h);
    try std.testing.expectEqual(@as(usize, 5), bar.opts.max_label_width);
    try std.testing.expectEqual(@as(usize, 6), bar.opts.max_message_width);
    try std.testing.expectEqual(@as(usize, 4), bar.opts.max_suffix_width);

    bar.done();
}

pub fn ProgressReader(comptime ReaderType: type) type {
    return struct {
        const Self = @This();
        underlying_reader: ReaderType,
        bar: *Bar,

        pub fn read(self: *Self, dest: []u8) !usize {
            const bytes_read = try self.underlying_reader.read(dest);
            if (bytes_read > 0) {
                _ = self.bar.incrementBy(bytes_read);
            }
            return bytes_read;
        }

        pub fn readAll(self: *Self, dest: []u8) !usize {
            const T = switch (@typeInfo(ReaderType)) {
                .pointer => |p| p.child,
                else => ReaderType,
            };
            if (@hasDecl(T, "readAll")) {
                const bytes_read = try self.underlying_reader.readAll(dest);
                if (bytes_read > 0) {
                    _ = self.bar.incrementBy(bytes_read);
                }
                return bytes_read;
            } else {
                var total_read: usize = 0;
                while (total_read < dest.len) {
                    const n = try self.read(dest[total_read..]);
                    if (n == 0) break;
                    total_read += n;
                }
                return total_read;
            }
        }

        pub fn reader(self: *Self) *Self {
            return self;
        }
    };
}

pub fn progressReader(bar: *Bar, underlying: anytype) ProgressReader(@TypeOf(underlying)) {
    return .{
        .underlying_reader = underlying,
        .bar = bar,
    };
}

pub fn ProgressWriter(comptime WriterType: type) type {
    return struct {
        const Self = @This();
        underlying_writer: WriterType,
        bar: *Bar,

        pub fn write(self: *Self, bytes: []const u8) !usize {
            const bytes_written = try self.underlying_writer.write(bytes);
            if (bytes_written > 0) {
                _ = self.bar.incrementBy(bytes_written);
            }
            return bytes_written;
        }

        pub fn writeAll(self: *Self, bytes: []const u8) !void {
            const T = switch (@typeInfo(WriterType)) {
                .pointer => |p| p.child,
                else => WriterType,
            };
            if (@hasDecl(T, "writeAll")) {
                try self.underlying_writer.writeAll(bytes);
                _ = self.bar.incrementBy(bytes.len);
            } else {
                var total_written: usize = 0;
                while (total_written < bytes.len) {
                    const n = try self.write(bytes[total_written..]);
                    if (n == 0) return error.WriteFailed;
                    total_written += n;
                }
            }
        }

        pub fn writer(self: *Self) *Self {
            return self;
        }
    };
}

pub fn progressWriter(bar: *Bar, underlying: anytype) ProgressWriter(@TypeOf(underlying)) {
    return .{
        .underlying_writer = underlying,
        .bar = bar,
    };
}

pub const ProgressIoReader = struct {
    underlying: *std.Io.Reader,
    bar: *Bar,
    interface: std.Io.Reader,

    pub fn init(bar: *Bar, underlying: *std.Io.Reader) ProgressIoReader {
        return .{
            .underlying = underlying,
            .bar = bar,
            .interface = .{
                .vtable = &.{
                    .stream = stream,
                },
                .buffer = &.{},
                .seek = 0,
                .end = 0,
            },
        };
    }

    fn stream(io_reader: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        const self: *ProgressIoReader = @alignCast(@fieldParentPtr("interface", io_reader));
        const bytes_read = try self.underlying.stream(w, limit);
        if (bytes_read > 0) {
            _ = self.bar.incrementBy(bytes_read);
        }
        return bytes_read;
    }

    pub fn reader(self: *ProgressIoReader) *std.Io.Reader {
        return &self.interface;
    }
};

pub fn progressIoReader(bar: *Bar, underlying: *std.Io.Reader) ProgressIoReader {
    return ProgressIoReader.init(bar, underlying);
}

pub const ProgressIoWriter = struct {
    underlying: *std.Io.Writer,
    bar: *Bar,
    interface: std.Io.Writer,

    pub fn init(bar: *Bar, underlying: *std.Io.Writer) ProgressIoWriter {
        return .{
            .underlying = underlying,
            .bar = bar,
            .interface = .{
                .vtable = &.{
                    .drain = drain,
                },
                .buffer = &.{},
                .end = 0,
            },
        };
    }

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const self: *ProgressIoWriter = @alignCast(@fieldParentPtr("interface", w));
        var total_written: usize = 0;
        for (data) |slice| {
            var i: usize = 0;
            while (i < splat) : (i += 1) {
                try self.underlying.writeAll(slice);
                total_written += slice.len;
            }
        }
        if (total_written > 0) {
            _ = self.bar.incrementBy(total_written);
        }
        return total_written;
    }

    pub fn writer(self: *ProgressIoWriter) *std.Io.Writer {
        return &self.interface;
    }
};

pub fn progressIoWriter(bar: *Bar, underlying: *std.Io.Writer) ProgressIoWriter {
    return ProgressIoWriter.init(bar, underlying);
}

test "Bar ProgressReader and ProgressWriter" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };

    var bar = Bar.init(io, .{
        .total = 100,
        .file = invalid_file,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
        .disable_new_line = true,
    });

    const data = "hello world loaders.zig library!";

    // 1. Test duck-typed ProgressReader
    const MockReader = struct {
        data: []const u8,
        pos: usize = 0,

        pub fn read(self: *@This(), dest: []u8) !usize {
            if (self.pos >= self.data.len) return 0;
            const len = @min(dest.len, self.data.len - self.pos);
            @memcpy(dest[0..len], self.data[self.pos .. self.pos + len]);
            self.pos += len;
            return len;
        }
    };

    var mr = MockReader{ .data = data };
    var p_reader = progressReader(&bar, &mr);

    var out_buf: [128]u8 = undefined;
    const read_len = try p_reader.reader().readAll(&out_buf);
    try std.testing.expectEqual(data.len, read_len);
    try std.testing.expectEqual(data.len, bar.completed.load(.acquire));

    // Reset bar completed
    bar.setCompleted(0);

    // 2. Test duck-typed ProgressWriter
    const MockWriter = struct {
        buf: []u8,
        pos: usize = 0,

        pub fn write(self: *@This(), bytes: []const u8) !usize {
            if (self.pos + bytes.len > self.buf.len) return error.NoSpace;
            @memcpy(self.buf[self.pos .. self.pos + bytes.len], bytes);
            self.pos += bytes.len;
            return bytes.len;
        }
    };

    var dest_buf: [128]u8 = undefined;
    var mw = MockWriter{ .buf = &dest_buf };
    var p_writer = progressWriter(&bar, &mw);

    try p_writer.writer().writeAll(data);
    try std.testing.expectEqual(data.len, bar.completed.load(.acquire));
    try std.testing.expectEqualSlices(u8, data, dest_buf[0..data.len]);

    // Reset bar completed
    bar.setCompleted(0);

    // 3. Test concrete ProgressIoReader and ProgressIoWriter
    var mr_fixed = std.Io.Reader.fixed(data);
    var p_io_reader = progressIoReader(&bar, &mr_fixed);

    var dest_buf2: [128]u8 = undefined;
    var mw_fixed = std.Io.Writer.fixed(&dest_buf2);
    var p_io_writer = progressIoWriter(&bar, &mw_fixed);

    const stream_len = try p_io_reader.reader().stream(p_io_writer.writer(), .unlimited);
    try std.testing.expectEqual(data.len, stream_len);
    // Both reader and writer are wrapped, so completion increments by 2x data.len
    try std.testing.expectEqual(data.len * 2, bar.completed.load(.acquire));
    try std.testing.expectEqualSlices(u8, data, dest_buf2[0..data.len]);
}
