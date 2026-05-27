//! color.zig — ANSI color and style escape sequence generation.
//!
//! All functions write into caller-provided buffers (no allocation).
//! When `enabled == false`, all functions emit empty strings, making it
//! trivial to disable color for non-TTY targets.

const std = @import("std");

// Public types

/// Standard 16-color palette, plus 256-color and RGB modes.
pub const Color = union(enum) {
    /// ANSI 4-bit foreground colors (bold = bright variants).
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
};

/// ANSI text attributes (can be combined via StyleSet).
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

// Colorizer

/// Controls whether color output is active.
/// Set to `false` when `NO_COLOR` is set or the output is not a TTY.
pub const Colorizer = struct {
    enabled: bool,
    ansi_enabled: bool = true,
    cr_enabled: bool = true,

    /// Write the ANSI escape to set foreground/background + attributes.
    /// `fg` and `bg` may both be `.default` to skip color codes.
    /// `attrs` is a slice of attributes to set.
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

        // Collect codes into a stack buffer
        var codes_buf: [128]u8 = undefined;
        const fba = std.heap.FixedBufferAllocator.init(&codes_buf);
        _ = fba;

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
            // first = false; (unused after this)
            try w.writeAll(bg_code);
        }

        if (first) {
            // Nothing to set — emit reset to be safe
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

// Convenience functions

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

// Tests

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

test "Colorizer disabled" {
    // When disabled, no bytes should be written
    var storage: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&storage);
    const colorizer = Colorizer{ .enabled = false, .ansi_enabled = false, .cr_enabled = false };
    try colorizer.begin(&w, .red, .default, &.{.bold});
    try colorizer.reset(&w);
    try colorizer.clearLine(&w);
    try std.testing.expectEqual(@as(usize, 0), w.buffered().len);
}
