const std = @import("std");
const tint = @import("tint");

pub const Color = tint.Color;
pub const RgbColor = tint.RgbColor;
pub const HexColor = tint.HexColor;
pub const Ansi256Color = tint.Ansi256Color;
pub const HslColor = tint.HslColor;
pub const HsvColor = tint.HsvColor;
pub const CmykColor = tint.CmykColor;
pub const XyzColor = tint.XyzColor;
pub const LabColor = tint.LabColor;
pub const Style = tint.Style;
pub const Named = tint.Named;
pub const presets = tint.presets;

pub const fg = tint.fg;
pub const bg = tint.bg;
pub const underline_color = tint.underline;
pub const fgRgb = tint.fgRgb;
pub const bgRgb = tint.bgRgb;
pub const fgHex = tint.fgHex;
pub const bgHex = tint.bgHex;
pub const fg256 = tint.fg256;
pub const bg256 = tint.bg256;

pub const rgb = tint.rgb;
pub const hex = tint.hex;
pub const ansi256 = tint.ansi256;
pub const hsl = tint.hsl;
pub const hsv = tint.hsv;
pub const cmyk = tint.cmyk;
pub const kelvin = tint.kelvin;
pub const named_color = tint.named_color;

pub const reset = tint.reset;
pub const reset_fg = tint.reset_fg;
pub const reset_bg = tint.reset_bg;
pub const reset_bold = tint.reset_bold;
pub const reset_dim = tint.reset_dim;
pub const reset_italic = tint.reset_italic;
pub const reset_underline = tint.reset_underline;
pub const reset_blink = tint.reset_blink;
pub const reset_reverse = tint.reset_reverse;
pub const reset_hidden = tint.reset_hidden;
pub const reset_strikethrough = tint.reset_strikethrough;
pub const reset_overline = tint.reset_overline;

pub const FontStyle = struct {
    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    underline: bool = false,
    blink: bool = false,
    reverse: bool = false,
    strikethrough: bool = false,
    concealed: bool = false,

    pub fn isEmpty(self: FontStyle) bool {
        return !self.bold and !self.dim and !self.italic and !self.underline and
            !self.blink and !self.reverse and !self.strikethrough and !self.concealed;
    }

    pub fn toAnsi(self: FontStyle, buf: []u8) []const u8 {
        const s = Style.init(.{
            .bold = self.bold,
            .dim = self.dim,
            .italic = self.italic,
            .underline = self.underline,
            .blink = self.blink,
            .reverse = self.reverse,
            .strikethrough = self.strikethrough,
            .hidden = self.concealed,
        });
        const ansi = s.toAnsi();
        const len = @min(ansi.len, buf.len);
        for (buf[0..len], 0..) |*b, i| b.* = ansi[i];
        return buf[0..len];
    }
};

pub fn colorToAnsi(color_val: ?Color) []const u8 {
    if (color_val) |c| return c.toFg() else return "";
}

pub fn styleToAnsi(style_val: ?Style) []const u8 {
    if (style_val) |s| return s.toAnsi() else return "";
}

test "font style empty" {
    try std.testing.expect((FontStyle{}).isEmpty());
}

test "font style to ansi" {
    var buf: [64]u8 = undefined;
    const out = (FontStyle{ .bold = true, .underline = true }).toAnsi(&buf);
    try std.testing.expectEqualStrings("\x1b[1;4m", out);
}

test "color fg" {
    try std.testing.expectEqualStrings("\x1b[32m", fg(.{ .ansi4 = .green }));
}

test "color bg" {
    try std.testing.expectEqualStrings("\x1b[44m", bg(.{ .ansi4 = .blue }));
}

test "rgb color" {
    const c = rgb(255, 0, 0);
    try std.testing.expectEqualStrings("\x1b[38;2;255;0;0m", c.toFg());
}

test "hex color" {
    const c = hex(0x00FF00);
    try std.testing.expectEqualStrings("\x1b[38;2;0;255;0m", c.toFg());
}

test "ansi256 color" {
    const c = ansi256(196);
    try std.testing.expectEqualStrings("\x1b[38;5;196m", c.toFg());
}

test "style to ansi" {
    const s = Style.init(.{ .fg = .{ .ansi4 = .red }, .bold = true });
    const ansi_str = s.toAnsi();
    try std.testing.expect(ansi_str.len > 0);
}
