//! bar.zig — Animated progress bar.
//!
//! Usage (5 lines):
//!
//!   var bar = Bar.init(io, .{});
//!   defer bar.done();
//!   bar.setTotal(100);
//!   for (0..100) |i| {
//!       bar.setCompleted(i + 1);
//!       try io.sleep(...);
//!   }

const std = @import("std");
const utils = @import("utils.zig");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const BarStyle = style_mod.BarStyle;

/// Configuration passed to `Bar.init`.
pub const Options = struct {
    /// Label printed before the bar. May be empty.
    label: []const u8 = "",
    /// Color used to render the label text. `.default` = no color.
    label_color: Color = .default,
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
    /// Color used for the bracket characters. `.default` = no color.
    bracket_color: Color = .default,
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
};

/// A single animated progress bar.
///
/// Thread safety: `completed` is an atomic value, so `setCompleted` /
/// `increment` are safe to call from any thread.  All rendering happens on
/// the thread that calls `render`.
pub const Bar = struct {
    io: std.Io,
    opts: Options,

    completed: std.atomic.Value(usize),
    total: std.atomic.Value(usize),
    started_ns: i96,
    done_flag: std.atomic.Value(bool),

    colorizer: Colorizer,
    term: terminal.TermInfo,
    file: std.Io.File,

    last_line_len: usize,
    write_buf: [4096]u8,

    // Dynamic message storage (updated via setMessage).
    msg_buf: [512:0]u8,
    msg_len: usize,

    /// Create a `Bar` and start timing.
    ///
    /// The returned struct is large — prefer stack or heap allocation.
    pub fn init(io: std.Io, opts: Options) Bar {
        terminal.setupTerminal();

        const file = opts.file orelse std.Io.File.stderr();
        const term_info = opts.term orelse terminal.query(file, io);
        const color_on = opts.color_enabled orelse term_info.ansi_supported;
        const now = std.Io.Clock.awake.now(io);

        var msg_buf: [512:0]u8 = [_:0]u8{0} ** 512;
        const msg_len = blk: {
            const src = opts.message;
            const len = @min(src.len, 511);
            @memcpy(msg_buf[0..len], src[0..len]);
            msg_buf[len] = 0;
            break :blk len;
        };

        return Bar{
            .io = io,
            .opts = .{
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
                .file = file,
                .term = opts.term,
                .color_enabled = opts.color_enabled,
                .custom_start = opts.custom_start,
                .custom_end = opts.custom_end,
                .show_date = opts.show_date,
                .show_time = opts.show_time,
                .timezone_offset_sec = opts.timezone_offset_sec,
            },
            .completed = std.atomic.Value(usize).init(0),
            .total = std.atomic.Value(usize).init(opts.total),
            .started_ns = now.nanoseconds,
            .done_flag = std.atomic.Value(bool).init(false),
            .colorizer = Colorizer{
                .enabled = color_on,
                .ansi_enabled = term_info.ansi_supported,
            },
            .term = term_info,
            .file = file,
            .last_line_len = 0,
            .write_buf = undefined,
            .msg_buf = msg_buf,
            .msg_len = msg_len,
        };
    }

    /// Update the total.
    pub fn setTotal(bar: *Bar, total: usize) void {
        bar.total.store(total, .release);
    }

    /// Atomically set the completed count.
    pub fn setCompleted(bar: *Bar, n: usize) void {
        bar.completed.store(n, .release);
    }

    /// Atomically increment the completed count by 1.
    pub fn increment(bar: *Bar) void {
        _ = bar.completed.fetchAdd(1, .release);
    }

    /// Atomically increment the completed count by `n`.
    pub fn incrementBy(bar: *Bar, n: usize) void {
        _ = bar.completed.fetchAdd(n, .release);
    }

    /// Update the dynamic message shown after the indicators.
    /// Safe to call from any thread; rendered on the next `render()` call.
    pub fn setMessage(bar: *Bar, msg: []const u8) void {
        const len = @min(msg.len, 511);
        @memcpy(bar.msg_buf[0..len], msg[0..len]);
        bar.msg_buf[len] = 0;
        bar.msg_len = len;
    }

    /// Render one frame to the terminal (call periodically from your loop).
    ///
    /// Write errors are silently ignored — the bar simply does not update.
    pub fn render(bar: *Bar) void {
        bar.renderInner() catch {};
    }

    pub fn renderInner(bar: *Bar) !void {
        if (bar.opts.width == 0) {
            bar.term = terminal.query(bar.file, bar.io);
        }

        var fw: std.Io.File.Writer = .init(bar.file, bar.io, &bar.write_buf);
        const w = &fw.interface;

        try bar.colorizer.clearLine(w);
        try bar.renderContent(w);
        try fw.flush();
    }

    /// Render bar content into an external writer.
    ///
    /// Does NOT emit a clearLine prefix or a trailing newline/flush.
    /// Used by `MultiBar` to batch all bars through a single writer.
    pub fn renderContent(bar: *Bar, w: *std.Io.Writer) !void {
        const completed = bar.completed.load(.acquire);
        const total = bar.total.load(.acquire);

        if (bar.opts.custom_start.len > 0) {
            try w.writeAll(bar.opts.custom_start);
        }

        const ts_ns = std.Io.Clock.real.now(bar.io).nanoseconds;
        const ts = @as(i64, @intCast(@divTrunc(ts_ns, std.time.ns_per_s))) + bar.opts.timezone_offset_sec;
        if (bar.opts.show_date and bar.opts.show_time) {
            var dbuf: [16]u8 = undefined;
            var tbuf: [16]u8 = undefined;
            try w.print("[{s} {s}] ", .{ utils.formatDate(&dbuf, ts), utils.formatTime(&tbuf, ts) });
        } else if (bar.opts.show_date) {
            var dbuf: [16]u8 = undefined;
            try w.print("[{s}] ", .{utils.formatDate(&dbuf, ts)});
        } else if (bar.opts.show_time) {
            var tbuf: [16]u8 = undefined;
            try w.print("[{s}] ", .{utils.formatTime(&tbuf, ts)});
        }

        const bar_width = effectiveBarWidth(bar, total);

        if (bar.opts.label.len > 0) {
            if (bar.opts.label_color != .default) {
                try color_mod.writeColored(w, bar.colorizer, bar.opts.label, bar.opts.label_color, .default, &.{});
                try w.writeByte(' ');
            } else {
                try w.print("{s} ", .{bar.opts.label});
            }
        }

        // Left bracket
        if (bar.opts.bracket_color != .default) {
            try bar.colorizer.begin(w, bar.opts.bracket_color, .default, &.{});
        }
        try w.writeAll(bar.opts.style.left_bracket);
        if (bar.opts.bracket_color != .default) {
            try bar.colorizer.reset(w);
        }

        if (total == 0) {
            try renderIndeterminate(bar, w, completed, bar_width);
        } else {
            try renderDeterminate(bar, w, completed, total, bar_width);
        }

        // Right bracket
        if (bar.opts.bracket_color != .default) {
            try bar.colorizer.begin(w, bar.opts.bracket_color, .default, &.{});
        }
        try w.writeAll(bar.opts.style.right_bracket);
        if (bar.opts.bracket_color != .default) {
            try bar.colorizer.reset(w);
        }

        // Percentage
        if (total > 0 and bar.opts.show_percent) {
            const pct = @min(100.0, utils.fraction(completed, total) * 100.0);
            if (bar.opts.percent_color != .default) {
                try bar.colorizer.begin(w, bar.opts.percent_color, .default, &.{});
                try w.print(" {d:3.0}%", .{pct});
                try bar.colorizer.reset(w);
            } else {
                try w.print(" {d:3.0}%", .{pct});
            }
        }

        if (bar.opts.show_count and total > 0) {
            try w.print(" {d}/{d}", .{ completed, total });
        }
        if (bar.opts.show_elapsed) {
            const elapsed_s = bar.elapsedSeconds();
            var buf: [16]u8 = undefined;
            try w.print(" {s}", .{utils.formatEta(&buf, elapsed_s)});
        }
        if (bar.opts.show_eta and total > 0 and completed > 0) {
            const eta = bar.etaSeconds(completed, total);
            var buf: [16]u8 = undefined;
            try w.print(" ETA {s}", .{utils.formatEta(&buf, eta)});
        }
        if (bar.opts.show_rate and completed > 0) {
            const elapsed_s = bar.elapsedSeconds();
            if (elapsed_s > 0) {
                const rate = @as(f64, @floatFromInt(completed)) / @as(f64, @floatFromInt(elapsed_s));
                if (bar.opts.unit_is_bytes) {
                    var buf: [32]u8 = undefined;
                    const r_u = @as(u64, @intFromFloat(rate));
                    try w.print(" {s}/s", .{utils.formatBytes(&buf, r_u)});
                } else {
                    try w.print(" {d:.1}/s", .{rate});
                }
            }
        }

        // Dynamic message
        const msg_slice = bar.msg_buf[0..bar.msg_len];
        if (msg_slice.len > 0) {
            try w.print(" {s}", .{msg_slice});
        }

        if (bar.opts.suffix.len > 0) {
            try w.print(" {s}", .{bar.opts.suffix});
        }
        if (bar.opts.custom_end.len > 0) {
            try w.writeAll(bar.opts.custom_end);
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

        const style = bar.opts.style;
        const c = bar.colorizer;

        if (filled_clamped > 0) {
            try c.begin(w, style.fill_fg, style.fill_bg, style.attrs);
            if (style.tip.len > 0 and filled_clamped < bar_width) {
                var i: usize = 0;
                while (i < filled_clamped -| 1) : (i += 1) {
                    try w.writeAll(style.fill);
                }
                try w.writeAll(style.tip);
            } else {
                var i: usize = 0;
                while (i < filled_clamped) : (i += 1) {
                    try w.writeAll(style.fill);
                }
            }
            try c.reset(w);
        }

        if (empty > 0) {
            try c.begin(w, style.empty_fg, style.empty_bg, &.{});
            var i: usize = 0;
            while (i < empty) : (i += 1) {
                try w.writeAll(style.empty);
            }
            try c.reset(w);
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

        const style = bar.opts.style;
        const c = bar.colorizer;

        var i: usize = 0;
        while (i < bar_width) : (i += 1) {
            if (i >= pos and i < pos + bounce_len) {
                try c.begin(w, style.fill_fg, style.fill_bg, style.attrs);
                try w.writeAll(style.fill);
                try c.reset(w);
            } else {
                try c.begin(w, style.empty_fg, style.empty_bg, &.{});
                try w.writeAll(style.empty);
                try c.reset(w);
            }
        }
    }

    /// Print a final "done" line and move to the next line.
    pub fn done(bar: *Bar) void {
        bar.done_flag.store(true, .release);
        // If complete_message is set, swap in the message
        if (bar.opts.complete_message.len > 0) {
            bar.setMessage(bar.opts.complete_message);
        }
        bar.renderFinal() catch {};
    }

    fn renderFinal(bar: *Bar) !void {
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
        if (bar.opts.width > 0) return @as(usize, bar.opts.width);

        const term_cols = bar.term.cols;

        var occupied: usize = 0;

        occupied += bar.opts.custom_start.len;
        occupied += bar.opts.custom_end.len;

        if (bar.opts.show_date and bar.opts.show_time) {
            occupied += 22;
        } else if (bar.opts.show_date) {
            occupied += 13;
        } else if (bar.opts.show_time) {
            occupied += 11;
        }

        if (bar.opts.label.len > 0) {
            occupied += bar.opts.label.len + 1;
        }

        occupied += bar.opts.style.left_bracket.len + bar.opts.style.right_bracket.len;

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
            occupied += bar.msg_len + 1;
        }

        if (bar.opts.suffix.len > 0) {
            occupied += bar.opts.suffix.len + 1;
        }

        const avail = @as(usize, term_cols) -| occupied;
        return @max(10, avail);
    }

    fn elapsedSeconds(bar: *const Bar) u64 {
        const now = std.Io.Clock.awake.now(bar.io);
        const elapsed_ns = now.nanoseconds - bar.started_ns;
        return @intCast(@max(0, @divTrunc(elapsed_ns, std.time.ns_per_s)));
    }

    fn etaSeconds(bar: *const Bar, completed: usize, total: usize) u64 {
        if (completed == 0) return 0;
        const elapsed = @as(f64, @floatFromInt(bar.elapsedSeconds()));
        const rate = @as(f64, @floatFromInt(completed)) / elapsed;
        if (rate <= 0.0) return 0;
        const remaining = @as(f64, @floatFromInt(total - completed));
        return @intFromFloat(remaining / rate);
    }
};

// ── Tests ──────────────────────────────────────────────────────────────────────

test "Bar.init default options" {
    const io = std.Options.debug_threaded_io.?.io();
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
    const io = std.Options.debug_threaded_io.?.io();
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.increment();
    bar.increment();
    try std.testing.expectEqual(@as(usize, 2), bar.completed.load(.acquire));
}

test "Bar.setMessage" {
    const io = std.Options.debug_threaded_io.?.io();
    var bar = Bar.init(io, .{
        .total = 10,
        .term = .{ .is_tty = false, .ansi_supported = false, .cols = 80 },
        .color_enabled = false,
    });
    bar.setMessage("processing...");
    try std.testing.expectEqual(@as(usize, 13), bar.msg_len);
}

test "Bar renders without error" {
    const io = std.Options.debug_threaded_io.?.io();
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
