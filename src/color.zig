//! color.zig — ANSI color and style escape sequence generation.
//!
//! All functions write into caller-provided buffers (no allocation).
//! When `enabled == false`, all functions emit empty strings, making it
//! trivial to disable color for non-TTY targets.
//!
//! Color modes supported:
//!   - Standard 16-color ANSI (.red, .bright_cyan, etc.)
//!   - 256-color palette (.{ .ansi256 = 200 })
//!   - 24-bit true color RGB (.{ .rgb = .{ .r=255, .g=128, .b=0 } })
//!   - Hex string parsing (Color.fromHex("#FF8800"))
//!   - No-color / terminal default (.default)

const std = @import("std");

/// Standard 16-color palette, plus 256-color and RGB modes.
pub const Color = union(enum) {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
    /// 256-color mode: index 0–255.
    ansi256: u8,
    /// True-color (24-bit RGB).
    rgb: struct { r: u8, g: u8, b: u8 },
    /// Terminal default (no color code emitted for this slot).
    default,

    /// Create a Color from explicit RGB components.
    pub fn fromRgb(r: u8, g: u8, b: u8) Color {
        return .{ .rgb = .{ .r = r, .g = g, .b = b } };
    }

    /// Create a Color from a 256-color palette index (0–255).
    pub fn fromAnsi256(index: u8) Color {
        return .{ .ansi256 = index };
    }

    /// Parse a hex color string into a Color.
    ///
    /// Accepts: `"#RRGGBB"`, `"RRGGBB"`, `"#RGB"`, `"RGB"`
    /// Returns `.default` on parse failure.
    ///
    /// Examples:
    ///   Color.fromHex("#FF8800")   => .{ .rgb = .{ .r=255, .g=136, .b=0 } }
    ///   Color.fromHex("FF8800")    => same
    ///   Color.fromHex("#F80")      => .{ .rgb = .{ .r=255, .g=136, .b=0 } }
    pub fn fromHex(hex: []const u8) Color {
        const s = if (hex.len > 0 and hex[0] == '#') hex[1..] else hex;
        if (s.len == 6) {
            const r = parseHexByte(s[0..2]) orelse return .default;
            const g = parseHexByte(s[2..4]) orelse return .default;
            const b = parseHexByte(s[4..6]) orelse return .default;
            return fromRgb(r, g, b);
        } else if (s.len == 3) {
            const r4 = parseHexNibble(s[0]) orelse return .default;
            const g4 = parseHexNibble(s[1]) orelse return .default;
            const b4 = parseHexNibble(s[2]) orelse return .default;
            return fromRgb(r4 * 17, g4 * 17, b4 * 17);
        }
        return .default;
    }

    /// Return the ANSI SGR code for a *foreground* color.
    pub fn fgCode(c: Color, buf: []u8) []const u8 {
        return switch (c) {
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
            .bright_black => "90",
            .bright_red => "91",
            .bright_green => "92",
            .bright_yellow => "93",
            .bright_blue => "94",
            .bright_magenta => "95",
            .bright_cyan => "96",
            .bright_white => "97",
            .ansi256 => |idx| std.fmt.bufPrint(buf, "38;5;{d}", .{idx}) catch "",
            .rgb => |v| std.fmt.bufPrint(buf, "38;2;{d};{d};{d}", .{ v.r, v.g, v.b }) catch "",
            .default => "",
        };
    }

    /// Return the ANSI SGR code for a *background* color.
    pub fn bgCode(c: Color, buf: []u8) []const u8 {
        return switch (c) {
            .black => "40",
            .red => "41",
            .green => "42",
            .yellow => "43",
            .blue => "44",
            .magenta => "45",
            .cyan => "46",
            .white => "47",
            .bright_black => "100",
            .bright_red => "101",
            .bright_green => "102",
            .bright_yellow => "103",
            .bright_blue => "104",
            .bright_magenta => "105",
            .bright_cyan => "106",
            .bright_white => "107",
            .ansi256 => |idx| std.fmt.bufPrint(buf, "48;5;{d}", .{idx}) catch "",
            .rgb => |v| std.fmt.bufPrint(buf, "48;2;{d};{d};{d}", .{ v.r, v.g, v.b }) catch "",
            .default => "",
        };
    }

    /// Return true if this color is `.default`.
    pub fn isDefault(c: Color) bool {
        return c == .default;
    }
};

/// ANSI text attributes (can be combined).
pub const Attribute = enum(u8) {
    bold = 1,
    dim = 2,
    italic = 3,
    underline = 4,
    blink = 5,
    blink_rapid = 6,
    reverse = 7,
    hidden = 8,
    strikethrough = 9,
};

/// Controls whether color output is active.
/// Set to `false` when `NO_COLOR` is set or the output is not a TTY.
pub const Colorizer = struct {
    enabled: bool,
    ansi_enabled: bool = true,
    cr_enabled: bool = true,

    /// Write the ANSI escape to set foreground/background + attributes.
    /// `fg` and `bg` may both be `.default` to skip color codes.
    ///
    /// Example: `colorizer.begin(w, .green, .default, &.{.bold})`
    pub fn begin(
        self: Colorizer,
        w: *std.Io.Writer,
        fg: Color,
        bg: Color,
        attrs: []const Attribute,
    ) std.Io.Writer.Error!void {
        if (!self.enabled) return;

        var tmp: [32]u8 = undefined;
        var first = true;
        try w.writeAll("\x1b[");

        for (attrs) |attr| {
            if (!first) try w.writeByte(';');
            first = false;
            try w.print("{d}", .{@intFromEnum(attr)});
        }

        const fg_code = fg.fgCode(&tmp);
        if (fg_code.len > 0) {
            if (!first) try w.writeByte(';');
            first = false;
            try w.writeAll(fg_code);
        }

        const bg_code = bg.bgCode(&tmp);
        if (bg_code.len > 0) {
            if (!first) try w.writeByte(';');
            try w.writeAll(bg_code);
        } else if (first) {
            try w.writeAll("0");
        }

        try w.writeByte('m');
    }

    /// Write the ANSI reset sequence.
    pub fn reset(self: Colorizer, w: *std.Io.Writer) std.Io.Writer.Error!void {
        if (!self.enabled) return;
        try w.writeAll("\x1b[0m");
    }

    /// Erase the current terminal line (move cursor to start, clear to end).
    pub fn clearLine(self: Colorizer, w: *std.Io.Writer) std.Io.Writer.Error!void {
        if (self.ansi_enabled) {
            try w.writeAll("\r\x1b[2K");
        } else if (self.cr_enabled) {
            try w.writeByte('\r');
        }
    }

    /// Move cursor up `n` lines.
    pub fn cursorUp(self: Colorizer, w: *std.Io.Writer, n: usize) std.Io.Writer.Error!void {
        if (!self.ansi_enabled or n == 0) return;
        try w.print("\x1b[{d}A", .{n});
    }

    /// Move cursor down `n` lines.
    pub fn cursorDown(self: Colorizer, w: *std.Io.Writer, n: usize) std.Io.Writer.Error!void {
        if (!self.ansi_enabled or n == 0) return;
        try w.print("\x1b[{d}B", .{n});
    }

    /// Move cursor to column 0 of the current line (carriage return).
    pub fn cr(self: Colorizer, w: *std.Io.Writer) std.Io.Writer.Error!void {
        if (!self.cr_enabled) return;
        try w.writeByte('\r');
    }

    /// Hide the cursor.
    pub fn hideCursor(self: Colorizer, w: *std.Io.Writer) std.Io.Writer.Error!void {
        if (!self.ansi_enabled) return;
        try w.writeAll("\x1b[?25l");
    }

    /// Show the cursor.
    pub fn showCursor(self: Colorizer, w: *std.Io.Writer) std.Io.Writer.Error!void {
        if (!self.ansi_enabled) return;
        try w.writeAll("\x1b[?25h");
    }
};

/// Write a colored string to `w` and reset afterwards.
pub fn writeColored(
    w: *std.Io.Writer,
    colorizer: Colorizer,
    s: []const u8,
    fg: Color,
    bg: Color,
    attrs: []const Attribute,
) std.Io.Writer.Error!void {
    try colorizer.begin(w, fg, bg, attrs);
    try w.writeAll(s);
    try colorizer.reset(w);
}

fn parseHexByte(s: []const u8) ?u8 {
    if (s.len < 2) return null;
    const hi = parseHexNibble(s[0]) orelse return null;
    const lo = parseHexNibble(s[1]) orelse return null;
    return hi * 16 + lo;
}

fn parseHexNibble(c: u8) ?u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => null,
    };
}

test "Color.fgCode standard" {
    var buf: [32]u8 = undefined;
    const red_color: Color = .red;
    const green_color: Color = .green;
    const white_color: Color = .white;
    try std.testing.expectEqualSlices(u8, "31", red_color.fgCode(&buf));
    try std.testing.expectEqualSlices(u8, "32", green_color.fgCode(&buf));
    try std.testing.expectEqualSlices(u8, "37", white_color.fgCode(&buf));
}

test "Color.fgCode ansi256" {
    var buf: [32]u8 = undefined;
    const c = Color{ .ansi256 = 200 };
    try std.testing.expectEqualSlices(u8, "38;5;200", c.fgCode(&buf));
}

test "Color.bgCode rgb" {
    var buf: [32]u8 = undefined;
    const c = Color{ .rgb = .{ .r = 255, .g = 128, .b = 0 } };
    try std.testing.expectEqualSlices(u8, "48;2;255;128;0", c.bgCode(&buf));
}

test "Color.fromRgb" {
    const c = Color.fromRgb(100, 200, 50);
    switch (c) {
        .rgb => |v| {
            try std.testing.expectEqual(@as(u8, 100), v.r);
            try std.testing.expectEqual(@as(u8, 200), v.g);
            try std.testing.expectEqual(@as(u8, 50), v.b);
        },
        else => return error.WrongVariant,
    }
}

test "Color.fromAnsi256" {
    const c = Color.fromAnsi256(150);
    try std.testing.expectEqual(Color{ .ansi256 = 150 }, c);
}

test "Color.fromHex 6-digit" {
    const c = Color.fromHex("#FF8800");
    switch (c) {
        .rgb => |v| {
            try std.testing.expectEqual(@as(u8, 255), v.r);
            try std.testing.expectEqual(@as(u8, 136), v.g);
            try std.testing.expectEqual(@as(u8, 0), v.b);
        },
        else => return error.WrongVariant,
    }
}

test "Color.fromHex 6-digit no hash" {
    const c = Color.fromHex("00FF00");
    switch (c) {
        .rgb => |v| {
            try std.testing.expectEqual(@as(u8, 0), v.r);
            try std.testing.expectEqual(@as(u8, 255), v.g);
            try std.testing.expectEqual(@as(u8, 0), v.b);
        },
        else => return error.WrongVariant,
    }
}

test "Color.fromHex 3-digit shorthand" {
    const c = Color.fromHex("#F80");
    switch (c) {
        .rgb => |v| {
            try std.testing.expectEqual(@as(u8, 255), v.r);
            try std.testing.expectEqual(@as(u8, 136), v.g);
            try std.testing.expectEqual(@as(u8, 0), v.b);
        },
        else => return error.WrongVariant,
    }
}

test "Color.fromHex invalid returns default" {
    const c = Color.fromHex("GGHHII");
    try std.testing.expectEqual(Color.default, c);
}

test "Color.fromHex empty returns default" {
    const c = Color.fromHex("");
    try std.testing.expectEqual(Color.default, c);
}

test "Color.isDefault" {
    const default_color: Color = .default;
    const red_color: Color = .red;
    const ansi_color = Color{ .ansi256 = 1 };
    try std.testing.expect(default_color.isDefault());
    try std.testing.expect(!red_color.isDefault());
    try std.testing.expect(!ansi_color.isDefault());
}

test "Colorizer disabled" {
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const colorizer = Colorizer{ .enabled = false, .ansi_enabled = false, .cr_enabled = false };
    try colorizer.begin(&w, .red, .default, &.{.bold});
    try colorizer.reset(&w);
    try colorizer.clearLine(&w);
    try std.testing.expectEqual(@as(usize, 0), w.buffered().len);
}

test "Color.fgCode all bright variants" {
    var buf: [32]u8 = undefined;
    const bright_black: Color = .bright_black;
    const bright_red: Color = .bright_red;
    const bright_white: Color = .bright_white;
    try std.testing.expectEqualSlices(u8, "90", bright_black.fgCode(&buf));
    try std.testing.expectEqualSlices(u8, "91", bright_red.fgCode(&buf));
    try std.testing.expectEqualSlices(u8, "97", bright_white.fgCode(&buf));
}

test "Color.bgCode all standard variants" {
    var buf: [32]u8 = undefined;
    const black_c: Color = .black;
    const white_c: Color = .white;
    const bright_black_c: Color = .bright_black;
    const bright_white_c: Color = .bright_white;
    try std.testing.expectEqualSlices(u8, "40", black_c.bgCode(&buf));
    try std.testing.expectEqualSlices(u8, "47", white_c.bgCode(&buf));
    try std.testing.expectEqualSlices(u8, "100", bright_black_c.bgCode(&buf));
    try std.testing.expectEqualSlices(u8, "107", bright_white_c.bgCode(&buf));
}

test "Color.fromHex lowercase hex" {
    const c = Color.fromHex("#ff0080");
    switch (c) {
        .rgb => |v| {
            try std.testing.expectEqual(@as(u8, 255), v.r);
            try std.testing.expectEqual(@as(u8, 0), v.g);
            try std.testing.expectEqual(@as(u8, 128), v.b);
        },
        else => return error.WrongVariant,
    }
}
