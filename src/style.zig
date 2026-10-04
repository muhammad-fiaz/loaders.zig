const std = @import("std");
const tint = @import("tint");

pub const Color = tint.color.Color;
pub const RgbColor = tint.color.Rgb;
pub const HexColor = tint.color.Hex;
pub const Ansi256Color = tint.color.Ansi256;
pub const HslColor = tint.color.Hsl;
pub const HsvColor = tint.color.Hsv;
pub const CmykColor = tint.color.Cmyk;
pub const XyzColor = tint.color.Xyz;
pub const LabColor = tint.color.Lab;
pub const Ansi4 = tint.color.Ansi4;
pub const Sequence = tint.ansi.Sequence;
pub const Style = tint.style.Style;
pub const Capability = tint.ansi.Capability;

pub const ansi = tint.ansi;
pub const palette = tint.palette;
pub const theme = tint.theme;
pub const tintColor = tint.color;
pub const tintStyle = tint.style;

pub fn fg(c: Color) Sequence {
    return c.fg();
}

pub fn bg(c: Color) Sequence {
    return c.bg();
}

pub fn underlineColor(c: Color) Sequence {
    return c.underline();
}

pub fn fgRgb(r: u8, g: u8, b: u8) Sequence {
    return tint.color.rgb(r, g, b).fg();
}

pub fn bgRgb(r: u8, g: u8, b: u8) Sequence {
    return tint.color.rgb(r, g, b).bg();
}

pub fn fgHex(value: u24) Sequence {
    return tint.color.hex(value).fg();
}

pub fn bgHex(value: u24) Sequence {
    return tint.color.hex(value).bg();
}

pub fn fg256(index: u8) Sequence {
    return tint.color.ansi256.index(index).fg();
}

pub fn bg256(index: u8) Sequence {
    return tint.color.ansi256.index(index).bg();
}

pub fn rgb(r: u8, g: u8, b: u8) Color {
    return tint.color.rgb(r, g, b);
}

pub fn hex(value: u24) Color {
    return tint.color.hex(value);
}

pub fn ansi256(index: u8) Color {
    return tint.color.ansi256.index(index);
}

pub fn hsl(h: u16, s: u8, l: u8) Color {
    return tint.color.hsl(h, s, l);
}

pub fn hsv(h: u16, s: u8, v: u8) Color {
    return tint.color.hsv(h, s, v);
}

pub fn cmyk(c: u8, m: u8, y: u8, k: u8) Color {
    return tint.color.cmyk(c, m, y, k);
}

pub fn kelvin(temperature: u16) Color {
    return tint.color.kelvin(temperature);
}

pub fn namedColor(name: []const u8) ?Color {
    return tint.color.parse(name);
}

pub const reset = tint.ansi.reset.all;
pub const resetFg = tint.ansi.reset.foreground;
pub const resetBg = tint.ansi.reset.background;
pub const resetAll = tint.ansi.reset.all;
pub const resetBold = tint.ansi.reset.bold;
pub const resetDim = tint.ansi.reset.dim;
pub const resetItalic = tint.ansi.reset.italic;
pub const resetUnderline = tint.ansi.reset.underline;
pub const resetBlink = tint.ansi.reset.blink;
pub const resetReverse = tint.ansi.reset.reverse;
pub const resetHidden = tint.ansi.reset.hidden;
pub const resetStrikethrough = tint.ansi.reset.strikethrough;
pub const resetOverline = tint.ansi.reset.overline;

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

    pub fn toAnsi(self: FontStyle) Sequence {
        return (Style{
            .bold = self.bold,
            .dim = self.dim,
            .italic = self.italic,
            .underline = self.underline,
            .blink = self.blink,
            .reverse = self.reverse,
            .strikethrough = self.strikethrough,
            .hidden = self.concealed,
        }).toAnsi();
    }

    pub fn toStyle(self: FontStyle) Style {
        return .{
            .bold = self.bold,
            .dim = self.dim,
            .italic = self.italic,
            .underline = self.underline,
            .blink = self.blink,
            .reverse = self.reverse,
            .strikethrough = self.strikethrough,
            .hidden = self.concealed,
        };
    }
};

pub fn colorToAnsi(colorVal: ?Color) Sequence {
    if (colorVal) |c| return c.fg();
    return .{};
}

pub fn styleToAnsi(styleVal: ?Style) Sequence {
    if (styleVal) |s| return s.toAnsi();
    return .{};
}

test "font style empty" {
    try std.testing.expect((FontStyle{}).isEmpty());
}

test "font style to ansi" {
    const out = (FontStyle{ .bold = true, .underline = true }).toAnsi();
    try std.testing.expectEqualStrings("\x1b[1;4m", out.slice());
}

test "color fg" {
    try std.testing.expectEqualStrings("\x1b[32m", fg(.{ .ansi4 = .green }).slice());
}

test "color bg" {
    try std.testing.expectEqualStrings("\x1b[44m", bg(.{ .ansi4 = .blue }).slice());
}

test "rgb color" {
    const c = rgb(255, 0, 0);
    try std.testing.expectEqualStrings("\x1b[38;2;255;0;0m", c.fg().slice());
}

test "hex color" {
    const c = hex(0x00FF00);
    try std.testing.expectEqualStrings("\x1b[38;2;0;255;0m", c.fg().slice());
}

test "ansi256 color" {
    const c = ansi256(196);
    try std.testing.expectEqualStrings("\x1b[38;5;196m", c.fg().slice());
}

test "style to ansi" {
    const s = Style{ .foreground = .{ .ansi4 = .red }, .bold = true };
    const ansiSeq = s.toAnsi();
    try std.testing.expect(ansiSeq.slice().len > 0);
}
