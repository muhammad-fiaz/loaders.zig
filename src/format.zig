//! format.zig — Custom template rendering engine for progress bars.
//!
//! Allows user-defined format strings using named tokens:
//!
//!   "{label} [{bar}] {percent} ETA {eta} @ {rate} {message}"
//!
//! Supported tokens:
//!   {label}   — the bar label
//!   {bar}     — the rendered fill bar (honors style)
//!   {percent} — percentage string (e.g. " 42%")
//!   {elapsed} — elapsed time (e.g. "01:23")
//!   {eta}     — estimated time remaining (e.g. "00:45")
//!   {rate}    — throughput rate (e.g. "12.3/s" or "1.00 KiB/s")
//!   {count}   — current/total count (e.g. "42/100")
//!   {time}    — current wall-clock time [HH:MM:SS]
//!   {date}    — current wall-clock date [YYYY-MM-DD]
//!   {message} — dynamic message text
//!   {spinner} — a spinner frame (used for indeterminate bars)
//!
//! Unknown tokens are passed through as-is. Literal text between tokens is
//! written unchanged. This engine is allocation-free.

const std = @import("std");
const utils = @import("utils.zig");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const BarStyle = style_mod.BarStyle;

/// Context passed to the template renderer describing bar state.
pub const RenderCtx = struct {
    label: []const u8 = "",
    completed: usize = 0,
    total: usize = 0,
    elapsed_s: u64 = 0,
    eta_s: u64 = 0,
    rate: f64 = 0.0,
    unit_is_bytes: bool = false,
    unit: []const u8 = "",
    message: []const u8 = "",
    timestamp_s: i64 = 0,
    bar_width: usize = 20,
    style: BarStyle = .{},
    colorizer: Colorizer = .{ .enabled = false, .ansi_enabled = false },
    spinner_frame: usize = 0,
    spinner_frames: []const []const u8 = &.{ "|", "/", "-", "\\" },
    spinner_color: Color = .default,
    spinner_bg_color: Color = .default,
    icon: ?[]const u8 = null,
    msg_icon: ?[]const u8 = null,
    status_icon: ?[]const u8 = null,
    status_color: Color = .default,
    line_color: Color = .default,
    line_bg_color: Color = .default,
    label_color: Color = .default,
    label_bg_color: Color = .default,
    percent_color: Color = .default,
    percent_bg_color: Color = .default,
    fill_color: Color = .default,
    fill_bg_color: Color = .default,
    empty_color: Color = .default,
    empty_bg_color: Color = .default,
    icon_gap: []const u8 = " ",
    label_gap: []const u8 = "",
    datetime_gap: []const u8 = "",
};

/// Render a format template string to `w` using the provided context.
///
/// Example template: `"{label} [{bar}] {percent} ETA {eta} @ {rate}"`
pub fn renderTemplate(w: *std.Io.Writer, template: []const u8, ctx: *const RenderCtx) !void {
    if (ctx.line_color != .default or ctx.line_bg_color != .default) {
        try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
    }
    var rest = template;
    while (rest.len > 0) {
        if (std.mem.indexOf(u8, rest, "{")) |brace_start| {
            // Write literal text before token
            if (brace_start > 0) {
                try w.writeAll(rest[0..brace_start]);
            }
            const after_brace = rest[brace_start + 1 ..];
            if (std.mem.indexOf(u8, after_brace, "}")) |brace_end| {
                const token = after_brace[0..brace_end];
                try renderToken(w, token, ctx);
                rest = after_brace[brace_end + 1 ..];
            } else {
                // No closing brace — treat as literal
                try w.writeAll(rest[brace_start..]);
                break;
            }
        } else {
            try w.writeAll(rest);
            break;
        }
    }
    if (ctx.line_color != .default or ctx.line_bg_color != .default) {
        try ctx.colorizer.reset(w);
    }
}

fn renderToken(w: *std.Io.Writer, token: []const u8, ctx: *const RenderCtx) !void {
    if (std.mem.eql(u8, token, "icon")) {
        if (ctx.status_icon) |s_icon| {
            try color_mod.writeColored(w, ctx.colorizer, s_icon, ctx.status_color, .default, &.{.bold});
            try w.writeAll(ctx.icon_gap);
            if (ctx.line_color != .default or ctx.line_bg_color != .default) {
                try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
            }
        } else {
            if (ctx.icon) |icon| {
                if (icon.len > 0) {
                    try w.writeAll(icon);
                    try w.writeAll(ctx.icon_gap);
                }
            }
            if (ctx.msg_icon) |icon| {
                if (icon.len > 0) {
                    try w.writeAll(icon);
                    try w.writeAll(ctx.icon_gap);
                }
            }
        }
    } else if (std.mem.eql(u8, token, "label")) {
        if (ctx.label_color != .default or ctx.label_bg_color != .default) {
            try color_mod.writeColored(w, ctx.colorizer, ctx.label, ctx.label_color, ctx.label_bg_color, &.{});
            try w.writeAll(ctx.label_gap);
            if (ctx.line_color != .default or ctx.line_bg_color != .default) {
                try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
            }
        } else {
            try w.writeAll(ctx.label);
            try w.writeAll(ctx.label_gap);
        }
    } else if (std.mem.eql(u8, token, "bar")) {
        try renderBarFill(w, ctx);
        if (ctx.line_color != .default or ctx.line_bg_color != .default) {
            try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
        }
    } else if (std.mem.eql(u8, token, "percent")) {
        if (ctx.total > 0) {
            var buf: [8]u8 = undefined;
            const frac = utils.fraction(ctx.completed, ctx.total);
            const pct_str = utils.formatPercent(&buf, frac);
            if (ctx.percent_color != .default or ctx.percent_bg_color != .default) {
                try color_mod.writeColored(w, ctx.colorizer, pct_str, ctx.percent_color, ctx.percent_bg_color, &.{});
                if (ctx.line_color != .default or ctx.line_bg_color != .default) {
                    try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
                }
            } else {
                try w.writeAll(pct_str);
            }
        } else {
            try w.writeAll("  ?%");
        }
    } else if (std.mem.eql(u8, token, "elapsed")) {
        var buf: [16]u8 = undefined;
        try w.writeAll(utils.formatEta(&buf, ctx.elapsed_s));
    } else if (std.mem.eql(u8, token, "eta")) {
        if (ctx.total > 0 and ctx.completed > 0 and ctx.eta_s > 0) {
            var buf: [16]u8 = undefined;
            try w.writeAll(utils.formatEta(&buf, ctx.eta_s));
        } else {
            try w.writeAll("?:??");
        }
    } else if (std.mem.eql(u8, token, "rate")) {
        if (ctx.rate > 0) {
            var buf: [32]u8 = undefined;
            try w.writeAll(utils.formatRate(&buf, ctx.rate, ctx.unit_is_bytes));
        } else {
            try w.writeAll("?/s");
        }
    } else if (std.mem.eql(u8, token, "count")) {
        var buf: [64]u8 = undefined;
        try w.writeAll(utils.formatCount(&buf, ctx.completed, ctx.total, ctx.unit));
    } else if (std.mem.eql(u8, token, "time")) {
        var buf: [16]u8 = undefined;
        try w.writeAll(utils.formatTime(&buf, ctx.timestamp_s));
    } else if (std.mem.eql(u8, token, "date")) {
        var buf: [16]u8 = undefined;
        try w.writeAll(utils.formatDate(&buf, ctx.timestamp_s));
    } else if (std.mem.eql(u8, token, "message")) {
        try w.writeAll(ctx.message);
    } else if (std.mem.eql(u8, token, "spinner")) {
        if (ctx.spinner_frames.len > 0) {
            const frame = ctx.spinner_frames[ctx.spinner_frame % ctx.spinner_frames.len];
            try color_mod.writeColored(w, ctx.colorizer, frame, ctx.spinner_color, ctx.spinner_bg_color, &.{});
            if (ctx.line_color != .default or ctx.line_bg_color != .default) {
                try ctx.colorizer.begin(w, ctx.line_color, ctx.line_bg_color, &.{});
            }
        }
    } else {
        // Unknown token — pass through literally
        try w.writeByte('{');
        try w.writeAll(token);
        try w.writeByte('}');
    }
}

fn renderBarFill(w: *std.Io.Writer, ctx: *const RenderCtx) !void {
    const bar_width = ctx.bar_width;
    const s = ctx.style;
    const c = ctx.colorizer;

    const fill_fg_col = if (ctx.fill_color != .default) ctx.fill_color else s.fill_fg;
    const empty_fg_col = if (ctx.empty_color != .default) ctx.empty_color else s.empty_fg;

    if (ctx.total == 0) {
        const bounce_len = @max(1, bar_width / 5);
        const range = bar_width -| bounce_len;
        const pos = if (range == 0) 0 else blk: {
            const cycle = range * 2;
            const t = ctx.completed % cycle;
            break :blk if (t <= range) t else cycle - t;
        };
        var i: usize = 0;
        while (i < bar_width) : (i += 1) {
            if (i >= pos and i < pos + bounce_len) {
                try c.begin(w, fill_fg_col, s.fill_bg, s.attrs);
                try w.writeAll(s.fill);
                try c.reset(w);
            } else {
                try c.begin(w, empty_fg_col, s.empty_bg, &.{});
                try w.writeAll(s.empty);
                try c.reset(w);
            }
        }
        return;
    }

    const frac = utils.fraction(ctx.completed, ctx.total);
    const filled = @as(usize, @intFromFloat(@as(f64, @floatFromInt(bar_width)) * frac));
    const filled_clamped = @min(filled, bar_width);
    const empty = bar_width - filled_clamped;

    if (filled_clamped > 0) {
        try c.begin(w, fill_fg_col, s.fill_bg, s.attrs);
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

    if (empty > 0) {
        try c.begin(w, empty_fg_col, s.empty_bg, &.{});
        var i: usize = 0;
        while (i < empty) : (i += 1) {
            try w.writeAll(s.empty);
        }
        try c.reset(w);
    }
}

/// Check if `template` contains a given token (e.g. "bar", "percent").
pub fn hasToken(template: []const u8, token: []const u8) bool {
    var needle_buf: [64]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buf, "{{{s}}}", .{token}) catch return false;
    return std.mem.indexOf(u8, template, needle) != null;
}

test "renderTemplate literals pass through" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{};
    try renderTemplate(&w, "Hello World", &ctx);
    try std.testing.expectEqualSlices(u8, "Hello World", w.buffered());
}

test "renderTemplate label token" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .label = "MyTask" };
    try renderTemplate(&w, "Task: {label}", &ctx);
    try std.testing.expectEqualSlices(u8, "Task: MyTask", w.buffered());
}

test "renderTemplate percent token determinate" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .completed = 50, .total = 100 };
    try renderTemplate(&w, "{percent}", &ctx);
    try std.testing.expectEqualSlices(u8, " 50%", w.buffered());
}

test "renderTemplate percent token indeterminate" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .completed = 0, .total = 0 };
    try renderTemplate(&w, "{percent}", &ctx);
    try std.testing.expectEqualSlices(u8, "  ?%", w.buffered());
}

test "renderTemplate count token with unit" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .completed = 3, .total = 10, .unit = "items" };
    try renderTemplate(&w, "{count}", &ctx);
    try std.testing.expectEqualSlices(u8, "3/10 items", w.buffered());
}

test "renderTemplate elapsed token" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .elapsed_s = 65 };
    try renderTemplate(&w, "{elapsed}", &ctx);
    try std.testing.expectEqualSlices(u8, "01:05", w.buffered());
}

test "renderTemplate rate token" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .rate = 5.5, .unit_is_bytes = false };
    try renderTemplate(&w, "{rate}", &ctx);
    try std.testing.expectEqualSlices(u8, "5.5/s", w.buffered());
}

test "renderTemplate message token" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{ .message = "processing..." };
    try renderTemplate(&w, "{message}", &ctx);
    try std.testing.expectEqualSlices(u8, "processing...", w.buffered());
}

test "renderTemplate unknown token passthrough" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{};
    try renderTemplate(&w, "{unknown_field}", &ctx);
    try std.testing.expectEqualSlices(u8, "{unknown_field}", w.buffered());
}

test "hasToken" {
    try std.testing.expect(hasToken("{label} [{bar}] {percent}", "bar"));
    try std.testing.expect(hasToken("{label} [{bar}] {percent}", "label"));
    try std.testing.expect(!hasToken("{label} [{bar}] {percent}", "rate"));
}

test "renderTemplate composite" {
    var storage: [512]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{
        .label = "Work",
        .completed = 0,
        .total = 0,
        .message = "init",
    };
    try renderTemplate(&w, "[{label}] {message}", &ctx);
    try std.testing.expectEqualSlices(u8, "[Work] init", w.buffered());
}

test "renderTemplate colors" {
    var storage: [512]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{
        .label = "Task",
        .label_color = .red,
        .line_color = .green,
        .colorizer = .{ .enabled = true, .ansi_enabled = true },
    };
    try renderTemplate(&w, "Start {label} End", &ctx);
    try std.testing.expectEqualSlices(u8, "\x1b[32mStart \x1b[31mTask\x1b[0m\x1b[32m End\x1b[0m", w.buffered());
}

test "renderTemplate icon spacing" {
    var storage: [512]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const ctx = RenderCtx{
        .icon = "🔥",
        .msg_icon = "🐹",
    };
    try renderTemplate(&w, "{icon}", &ctx);
    try std.testing.expectEqualSlices(u8, "🔥 🐹 ", w.buffered());
}
