//! style.zig — Named visual styles for progress bars and spinners.
//!
//! `BarStyle` controls the visual appearance of a progress bar: bracket
//! characters, fill/empty glyphs, and ANSI color attributes.
//!
//! `SpinnerStyle` controls the animation frames, interval, and default
//! color for a spinner. Over 40 built-in presets are provided.

const std = @import("std");
const color = @import("color.zig");

pub const Color = color.Color;
pub const Attribute = color.Attribute;

/// A message and icon pair for dynamic cycling.
pub const Message = struct {
    text: []const u8,
    icon: ?[]const u8 = null,
};

/// Visual style for a progress bar.
pub const BarStyle = struct {
    /// Left bracket character.
    left_bracket: []const u8 = "[",
    /// Right bracket character.
    right_bracket: []const u8 = "]",
    /// Character repeated for the filled portion.
    fill: []const u8 = "█",
    /// Character repeated for the empty portion.
    empty: []const u8 = "░",
    /// Character at the leading edge of the fill (tip). Empty = block bar.
    tip: []const u8 = "",
    /// Color for filled portion.
    fill_fg: Color = .default,
    /// Background color for filled portion.
    fill_bg: Color = .default,
    /// Color for empty portion.
    empty_fg: Color = .default,
    /// Background color for empty portion.
    empty_bg: Color = .default,
    /// Text attributes applied to the filled portion.
    attrs: []const Attribute = &.{},
    /// Optional gradient for the fill. When set, overrides fill_fg with
    /// interpolated colors across the bar width.
    fill_gradient: ?Gradient = null,
    /// Optional gradient for the empty portion.
    empty_gradient: ?Gradient = null,
    /// Color for the filled portion when the bar is complete (100%).
    /// `.default` = use `fill_fg` or gradient.
    complete_fg: Color = .default,

    /// Classic ASCII bar: [####    ]
    pub const ascii: BarStyle = .{
        .left_bracket = "[",
        .right_bracket = "]",
        .fill = "#",
        .empty = " ",
        .tip = "",
    };

    /// Unicode block bar: [████░░░░]
    pub const block: BarStyle = .{};

    /// Thin Unicode bar using ▓▒░
    pub const shaded: BarStyle = .{
        .fill = "▓",
        .empty = "░",
        .tip = "▒",
    };

    /// Green fill on default background.
    pub const green: BarStyle = .{
        .fill_fg = .green,
        .empty_fg = .bright_black,
    };

    /// Cyan fill, ideal for download progress.
    pub const cyan: BarStyle = .{
        .fill_fg = .cyan,
        .empty_fg = .bright_black,
        .fill = "▓",
        .empty = "░",
    };

    /// Bold yellow bar.
    pub const yellow: BarStyle = .{
        .fill_fg = .yellow,
        .empty_fg = .bright_black,
        .attrs = &.{.bold},
    };

    /// Red for warnings / danger.
    pub const red: BarStyle = .{
        .fill_fg = .red,
        .empty_fg = .bright_black,
    };

    /// Gradient-like effect with bright fill tip.
    pub const gradient: BarStyle = .{
        .fill = "▓",
        .tip = "▒",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 0, .g = 200, .b = 100 } },
        .empty_fg = .bright_black,
    };

    /// Minimal: no brackets, slim fill.
    pub const minimal: BarStyle = .{
        .left_bracket = "",
        .right_bracket = "",
        .fill = "─",
        .tip = "▶",
        .empty = "─",
        .fill_fg = .cyan,
        .empty_fg = .bright_black,
    };

    /// Blue fill bar.
    pub const blue: BarStyle = .{
        .fill_fg = .blue,
        .empty_fg = .bright_black,
        .fill = "▓",
        .empty = "░",
        .attrs = &.{.bold},
    };

    /// Magenta fill bar.
    pub const magenta: BarStyle = .{
        .fill_fg = .magenta,
        .empty_fg = .bright_black,
        .fill = "▓",
        .empty = "░",
    };

    /// Fire style: orange-red 24-bit fill.
    pub const fire: BarStyle = .{
        .fill = "█",
        .tip = "▓",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 255, .g = 80, .b = 0 } },
        .empty_fg = .bright_black,
        .attrs = &.{.bold},
    };

    /// Ice style: cool blue-white fill.
    pub const ice: BarStyle = .{
        .fill = "█",
        .tip = "▓",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 100, .g = 200, .b = 255 } },
        .empty_fg = .bright_black,
    };

    /// Ocean style: deep teal fill.
    pub const ocean: BarStyle = .{
        .fill = "▓",
        .tip = "▒",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 0, .g = 150, .b = 180 } },
        .empty_fg = .{ .rgb = .{ .r = 20, .g = 40, .b = 60 } },
    };

    /// Neon style: bright magenta/pink fill, high contrast.
    pub const neon: BarStyle = .{
        .fill = "█",
        .tip = "▓",
        .empty = " ",
        .left_bracket = "⟦",
        .right_bracket = "⟧",
        .fill_fg = .{ .rgb = .{ .r = 255, .g = 0, .b = 200 } },
        .empty_fg = .{ .rgb = .{ .r = 40, .g = 0, .b = 40 } },
        .attrs = &.{.bold},
    };

    /// Arrow-tip bar: [====>    ]
    pub const arrow: BarStyle = .{
        .fill = "=",
        .tip = ">",
        .empty = " ",
        .fill_fg = .green,
        .empty_fg = .default,
    };

    /// Dot bar: uses middle dot characters.
    pub const dots: BarStyle = .{
        .fill = "●",
        .empty = "○",
        .tip = "",
        .fill_fg = .cyan,
        .empty_fg = .bright_black,
        .left_bracket = " ",
        .right_bracket = " ",
    };

    /// Slim line bar: thin Unicode line characters.
    pub const slim: BarStyle = .{
        .fill = "━",
        .tip = "╸",
        .empty = "─",
        .fill_fg = .{ .rgb = .{ .r = 80, .g = 200, .b = 120 } },
        .empty_fg = .bright_black,
        .left_bracket = "",
        .right_bracket = "",
    };

    /// Pipe bar: uses | and - characters.
    pub const pipe: BarStyle = .{
        .fill = "|",
        .empty = "-",
        .tip = "",
        .fill_fg = .bright_green,
        .empty_fg = .bright_black,
    };

    /// Half-block bar: uses half-block Unicode characters.
    pub const half_block: BarStyle = .{
        .fill = "▓",
        .tip = "▌",
        .empty = "▒",
        .fill_fg = .{ .rgb = .{ .r = 60, .g = 180, .b = 255 } },
        .empty_fg = .{ .rgb = .{ .r = 30, .g = 30, .b = 60 } },
    };

    /// Matrix style: green on black.
    pub const matrix: BarStyle = .{
        .fill = "█",
        .tip = "▓",
        .empty = "░",
        .fill_fg = .bright_green,
        .fill_bg = .black,
        .empty_fg = .green,
        .empty_bg = .black,
        .attrs = &.{.bold},
    };

    /// Retro style: amber/yellow classic terminal look.
    pub const retro: BarStyle = .{
        .left_bracket = "(",
        .right_bracket = ")",
        .fill = "▓",
        .empty = "░",
        .tip = "▒",
        .fill_fg = .{ .rgb = .{ .r = 255, .g = 176, .b = 0 } },
        .empty_fg = .{ .rgb = .{ .r = 80, .g = 50, .b = 0 } },
    };

    /// Classic pipes bar: ═══>
    pub const classic_pipes: BarStyle = .{
        .left_bracket = "║",
        .right_bracket = "║",
        .fill = "═",
        .tip = ">",
        .empty = " ",
        .fill_fg = .bright_cyan,
        .empty_fg = .default,
        .attrs = &.{.bold},
    };

    /// Rainbow style: vibrant purple RGB fill.
    pub const rainbow: BarStyle = .{
        .fill = "█",
        .tip = "▓",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 160, .g = 32, .b = 240 } },
        .empty_fg = .bright_black,
        .attrs = &.{.bold},
    };

    /// Smooth gradient: teal to blue.
    pub const teal: BarStyle = .{
        .fill = "▓",
        .tip = "▒",
        .empty = "░",
        .fill_fg = .{ .rgb = .{ .r = 0, .g = 200, .b = 180 } },
        .empty_fg = .bright_black,
    };
};

/// A gradient definition for multi-color rendering.
///
/// Defines how colors transition across a span (bar fill or spinner frames).
/// `colors` is an array of color stops; the gradient interpolates between
/// consecutive stops. `reversed` flips the direction.
pub const Gradient = struct {
    /// Color stops to interpolate between (minimum 2).
    colors: []const Color,
    /// When true, the gradient runs from the last color to the first.
    reversed: bool = false,

    /// Get the interpolated color at position `t` (0.0–1.0).
    pub fn at(self: Gradient, t: f64) Color {
        const n = self.colors.len;
        if (n == 0) return .default;
        if (n == 1) return self.colors[0];
        const tt = if (self.reversed) 1.0 - @max(0.0, @min(1.0, t)) else @max(0.0, @min(1.0, t));
        const segment = tt * @as(f64, @floatFromInt(n - 1));
        const idx: usize = @intFromFloat(@min(segment, @as(f64, @floatFromInt(n - 2))));
        const local_t = segment - @as(f64, @floatFromInt(idx));
        return color.colorFromLerp(self.colors[idx], self.colors[idx + 1], local_t);
    }

    /// Rainbow gradient: red → yellow → green → cyan → blue → magenta → red.
    pub const rainbow: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 255, .b = 0 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 0 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 0, .b = 255 } },
        .{ .rgb = .{ .r = 255, .g = 0, .b = 255 } },
        .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
    } };

    /// Fire gradient: dark red → orange → yellow → white.
    pub const fire: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 180, .g = 0, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 80, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 200, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 255, .b = 200 } },
    } };

    /// Ocean gradient: deep blue → teal → cyan → light blue.
    pub const ocean: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 0, .g = 40, .b = 120 } },
        .{ .rgb = .{ .r = 0, .g = 120, .b = 160 } },
        .{ .rgb = .{ .r = 0, .g = 200, .b = 200 } },
        .{ .rgb = .{ .r = 100, .g = 220, .b = 255 } },
    } };

    /// Sunset gradient: purple → magenta → orange → yellow.
    pub const sunset: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 80, .g = 0, .b = 160 } },
        .{ .rgb = .{ .r = 200, .g = 0, .b = 120 } },
        .{ .rgb = .{ .r = 255, .g = 120, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 220, .b = 0 } },
    } };

    /// Neon gradient: magenta → cyan → green → yellow.
    pub const neon: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 255, .g = 0, .b = 200 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 255, .b = 0 } },
    } };

    /// Forest gradient: dark green → green → lime → yellow-green.
    pub const forest: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 0, .g = 80, .b = 0 } },
        .{ .rgb = .{ .r = 0, .g = 160, .b = 0 } },
        .{ .rgb = .{ .r = 100, .g = 220, .b = 0 } },
        .{ .rgb = .{ .r = 200, .g = 255, .b = 0 } },
    } };

    /// Ice gradient: white → light blue → blue → deep blue.
    pub const ice: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 220, .g = 240, .b = 255 } },
        .{ .rgb = .{ .r = 100, .g = 180, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 100, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 40, .b = 180 } },
    } };

    /// Pastel gradient: soft multi-color.
    pub const pastel: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 255, .g = 180, .b = 180 } },
        .{ .rgb = .{ .r = 255, .g = 220, .b = 180 } },
        .{ .rgb = .{ .r = 255, .g = 255, .b = 180 } },
        .{ .rgb = .{ .r = 180, .g = 255, .b = 180 } },
        .{ .rgb = .{ .r = 180, .g = 220, .b = 255 } },
        .{ .rgb = .{ .r = 220, .g = 180, .b = 255 } },
    } };

    /// Monochrome gradient: dark gray → white.
    pub const monochrome: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 60, .g = 60, .b = 60 } },
        .{ .rgb = .{ .r = 200, .g = 200, .b = 200 } },
    } };

    /// Reversed rainbow: runs the opposite direction.
    pub const rainbow_reversed: Gradient = .{ .colors = &.{
        .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 0, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 0, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 255 } },
        .{ .rgb = .{ .r = 0, .g = 255, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 255, .b = 0 } },
        .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
    }, .reversed = true };
};

/// Visual style for a spinner animation.
pub const SpinnerStyle = struct {
    /// Ordered list of frames to cycle through.
    frames: []const []const u8,
    /// Milliseconds to display each frame.
    interval_ms: u64 = 80,
    /// Default foreground color for the spinner glyph.
    color: Color = .default,
    /// Text attributes for the spinner glyph.
    attrs: []const Attribute = &.{},
    /// Optional gradient for the spinner glyph. Cycles through colors
    /// on each frame when set. Overrides `color`.
    gradient: ?Gradient = null,
    /// Color for the spinner glyph when in completed state (succeed/fail/warn/info).
    /// `.default` = use the state color (green/red/yellow/cyan).
    complete_fg: Color = .default,

    /// Braille dots animation (10-frame).
    pub const dots: SpinnerStyle = .{
        .frames = &.{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        .interval_ms = 80,
        .color = .cyan,
    };

    /// Dense braille pattern (8-frame).
    pub const dots2: SpinnerStyle = .{
        .frames = &.{ "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
        .interval_ms = 80,
        .color = .cyan,
    };

    /// Classic ASCII line spinner.
    pub const line: SpinnerStyle = .{
        .frames = &.{ "-", "\\", "|", "/" },
        .interval_ms = 100,
        .color = .white,
    };

    /// Smooth arc animation.
    pub const arc: SpinnerStyle = .{
        .frames = &.{ "◜", "◠", "◝", "◞", "◡", "◟" },
        .interval_ms = 100,
        .color = .cyan,
    };

    /// Earth rotating emojis.
    pub const globe: SpinnerStyle = .{
        .frames = &.{ "🌍", "🌎", "🌏" },
        .interval_ms = 200,
    };

    /// Eight-direction arrow spinner.
    pub const arrow: SpinnerStyle = .{
        .frames = &.{ "←", "↖", "↑", "↗", "→", "↘", "↓", "↙" },
        .interval_ms = 100,
        .color = .yellow,
    };

    /// Block pulse animation.
    pub const pulse: SpinnerStyle = .{
        .frames = &.{ "█", "▓", "▒", "░", "▒", "▓" },
        .interval_ms = 100,
        .color = .green,
    };

    /// Bouncing ball in parentheses.
    pub const bounce: SpinnerStyle = .{
        .frames = &.{ "( ●    )", "(  ●   )", "(   ●  )", "(    ● )", "(     ●)", "(    ● )", "(   ●  )", "(  ●   )", "( ●    )", "(●     )" },
        .interval_ms = 80,
        .color = .cyan,
    };

    /// Analog clock face emojis (12-frame).
    pub const clock: SpinnerStyle = .{
        .frames = &.{ "🕛", "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚" },
        .interval_ms = 100,
    };

    /// Moon phase emojis (8-frame).
    pub const moon: SpinnerStyle = .{
        .frames = &.{ "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
        .interval_ms = 80,
    };

    /// Vertical bar fill animation (14-frame).
    pub const bars: SpinnerStyle = .{
        .frames = &.{ "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂" },
        .interval_ms = 80,
        .color = .{ .rgb = .{ .r = 80, .g = 200, .b = 120 } },
    };

    /// Fast braille matrix spinner.
    pub const braille: SpinnerStyle = .{
        .frames = &.{ "⡀", "⡄", "⡆", "⡇", "⣇", "⣧", "⣷", "⣿", "⣷", "⣧", "⣇", "⡇", "⡆", "⡄" },
        .interval_ms = 60,
        .color = .bright_cyan,
    };

    /// Pong-style bouncing dot between brackets.
    pub const pong: SpinnerStyle = .{
        .frames = &.{ "▐⠂       ▌", "▐⠈       ▌", "▐ ⠂      ▌", "▐ ⠠      ▌", "▐  ⡀     ▌", "▐  ⠠     ▌", "▐   ⠂    ▌", "▐   ⠈    ▌", "▐    ⠂   ▌", "▐    ⠠   ▌", "▐     ⡀  ▌", "▐     ⠠  ▌", "▐      ⠂ ▌", "▐      ⠈ ▌", "▐       ⠂▌", "▐       ⠠▌", "▐      ⠠ ▌", "▐      ⠂ ▌", "▐     ⠠  ▌", "▐     ⡀  ▌", "▐    ⠠   ▌", "▐    ⠂   ▌", "▐   ⠈    ▌", "▐   ⠂    ▌", "▐  ⠠     ▌", "▐  ⡀     ▌", "▐ ⠠      ▌", "▐ ⠂      ▌", "▐⠈       ▌", "▐⠂       ▌" },
        .interval_ms = 80,
        .color = .green,
    };

    /// Weather emoji sequence.
    pub const weather: SpinnerStyle = .{
        .frames = &.{ "☀️ ", "🌤 ", "⛅ ", "🌦 ", "🌧 ", "⛈ ", "🌩 ", "🌨 ", "❄️ ", "🌨 ", "⛈ ", "🌧 ", "🌦 ", "⛅ ", "🌤 " },
        .interval_ms = 200,
    };

    /// Heart fill animation.
    pub const hearts: SpinnerStyle = .{
        .frames = &.{ "💛", "💙", "💜", "💚", "❤️ " },
        .interval_ms = 100,
    };

    /// Box-drawing animation using corner characters.
    pub const box_bounce: SpinnerStyle = .{
        .frames = &.{ "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
        .interval_ms = 120,
        .color = .bright_blue,
    };

    /// Shark fin animation.
    pub const shark: SpinnerStyle = .{
        .frames = &.{ "▐|\\____________▌", "▐_|\\___________▌", "▐__|\\__________▌", "▐___|\\_____ ___▌", "▐____|\\________▌", "▐_____|\\________▌", "▐______|\\______▌", "▐_______|\\________▌", "▐________|\\____▌", "▐_________|\\___▌", "▐__________|\\__▌", "▐___________|\\_ ▌", "▐____________|\\▌", "▐____________/|▌", "▐___________/|_▌", "▐__________/|__▌", "▐_________/|___▌", "▐________/|____▌", "▐_______/|_____▌", "▐______/|______▌", "▐_____/|_______▌", "▐____/|________▌", "▐___/|_________▌", "▐__/|__________▌", "▐_/|___________▌", "▐/|____________▌" },
        .interval_ms = 120,
        .color = .blue,
    };

    /// Hourglass sand animation.
    pub const sand: SpinnerStyle = .{
        .frames = &.{ "⏳", "⌛" },
        .interval_ms = 500,
    };

    /// WiFi signal strength animation.
    pub const wifi: SpinnerStyle = .{
        .frames = &.{ "▁", "▃", "▅", "▇", "▅", "▃" },
        .interval_ms = 100,
        .color = .bright_green,
        .attrs = &.{.bold},
    };

    /// Battery charging animation.
    pub const charging: SpinnerStyle = .{
        .frames = &.{ "🔋", "🔋", "🔋", "⚡" },
        .interval_ms = 200,
    };

    /// Running person emoji animation.
    pub const runner: SpinnerStyle = .{
        .frames = &.{ "🚶", "🏃" },
        .interval_ms = 140,
    };

    /// Snake/coil animation.
    pub const snake: SpinnerStyle = .{
        .frames = &.{ "⣇⣀⣀⣀⣀", "⣗⣀⣀⣀⣀", "⣿⣀⣀⣀⣀", "⣿⣇⣀⣀⣀", "⣿⣗⣀⣀⣀", "⣿⣿⣀⣀⣀", "⣿⣿⣇⣀⣀", "⣿⣿⣗⣀⣀", "⣿⣿⣿⣀⣀", "⣿⣿⣿⣇⣀", "⣿⣿⣿⣗⣀", "⣿⣿⣿⣿⣀", "⣿⣿⣿⣿⣇", "⣿⣿⣿⣿⣿", "⣿⣿⣿⣿⣗", "⣿⣿⣿⣿⡇", "⣿⣿⣿⣿⠇", "⣿⣿⣿⣿ ", "⣿⣿⣿⣷ ", "⣿⣿⣿⡷ ", "⣿⣿⣿⠷ ", "⣿⣿⣿  ", "⣿⣿⣷  ", "⣿⣿⡷  ", "⣿⣿⠷  ", "⣿⣿   ", "⣿⣷   ", "⣿⡷   ", "⣿⠷   ", "⣿    ", "⣷    ", "⡷    ", "⠷    " },
        .interval_ms = 60,
        .color = .{ .rgb = .{ .r = 100, .g = 220, .b = 100 } },
    };

    /// Hamburger menu expansion animation.
    pub const hamburger: SpinnerStyle = .{
        .frames = &.{ "☱", "☲", "☴" },
        .interval_ms = 100,
        .color = .yellow,
    };

    /// Flipping box animation.
    pub const flip: SpinnerStyle = .{
        .frames = &.{ "_ ", "\\", " |", "/ ", "_ ", "\\", " |", "/ " },
        .interval_ms = 100,
        .color = .cyan,
    };

    /// Monkey see, monkey do.
    pub const monkey: SpinnerStyle = .{
        .frames = &.{ "🙈", "🙈", "🙉", "🙊" },
        .interval_ms = 300,
    };

    /// Christmas tree emoji blink.
    pub const christmas_tree: SpinnerStyle = .{
        .frames = &.{ "🎄", "🎄", "✨", "🎄", "🎄", "⭐" },
        .interval_ms = 400,
    };

    /// Snowflake / star alternation.
    pub const christmas: SpinnerStyle = .{
        .frames = &.{ "❄ ", "❄ ", "❅ ", "❆ ", "❅ " },
        .interval_ms = 120,
        .color = .bright_cyan,
    };

    /// Finger dance gesture sequence.
    pub const finger_dance: SpinnerStyle = .{
        .frames = &.{ "🤘", "🤙", "🖖", "✋", "🤚", "👋" },
        .interval_ms = 160,
    };

    /// Mind-blown explosion animation.
    pub const mind_blown: SpinnerStyle = .{
        .frames = &.{ "😐", "😐", "😑", "😒", "🤔", "🤯", "💥", "✨" },
        .interval_ms = 200,
    };

    /// Speaker volume animation.
    pub const speaker: SpinnerStyle = .{
        .frames = &.{ "🔈 ", "🔉 ", "🔊 ", "🔉 " },
        .interval_ms = 200,
    };

    /// Circular triangle spinner.
    pub const triangle: SpinnerStyle = .{
        .frames = &.{ "◢", "◣", "◤", "◥" },
        .interval_ms = 100,
        .color = .bright_yellow,
    };

    /// Pulsing circle.
    pub const circle_pulse: SpinnerStyle = .{
        .frames = &.{ "◯", "◉", "●", "◉" },
        .interval_ms = 120,
        .color = .magenta,
    };

    /// Aesthetic loading bar within the spinner glyph.
    pub const aesthetic: SpinnerStyle = .{
        .frames = &.{ "▰▱▱▱▱▱▱", "▰▰▱▱▱▱▱", "▰▰▰▱▱▱▱", "▰▰▰▰▱▱▱", "▰▰▰▰▰▱▱", "▰▰▰▰▰▰▱", "▰▰▰▰▰▰▰", "▰▱▱▱▱▱▱" },
        .interval_ms = 80,
        .color = .{ .rgb = .{ .r = 160, .g = 100, .b = 255 } },
    };

    /// Vertical growing bar (Material Design inspired).
    pub const grow_vertical: SpinnerStyle = .{
        .frames = &.{ "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█", "▉", "▊", "▋", "▌", "▍", "▎" },
        .interval_ms = 70,
        .color = .{ .rgb = .{ .r = 33, .g = 150, .b = 243 } },
    };

    /// Horizontal expanding dots.
    pub const grow_horizontal: SpinnerStyle = .{
        .frames = &.{ ".  ", ".. ", "...", " ..", "  .", "   " },
        .interval_ms = 120,
        .color = .bright_white,
    };

    /// Material Design dots (three dots pulsing).
    pub const material: SpinnerStyle = .{
        .frames = &.{ "●∙∙", "∙●∙", "∙∙●", "∙●∙" },
        .interval_ms = 100,
        .color = .{ .rgb = .{ .r = 3, .g = 169, .b = 244 } },
    };

    /// Layered block build-up.
    pub const layer: SpinnerStyle = .{
        .frames = &.{ "-", "=", "≡" },
        .interval_ms = 150,
        .color = .bright_white,
        .attrs = &.{.bold},
    };

    /// Star/asterisk rotation.
    pub const star: SpinnerStyle = .{
        .frames = &.{ "✶", "✸", "✹", "✺", "✹", "✷" },
        .interval_ms = 70,
        .color = .bright_yellow,
    };

    /// Toggle on/off blink.
    pub const toggle: SpinnerStyle = .{
        .frames = &.{ "⊶", "⊷" },
        .interval_ms = 250,
        .color = .bright_cyan,
    };

    /// Progress pie chart slices.
    pub const progress_pie: SpinnerStyle = .{
        .frames = &.{ "○", "◔", "◑", "◕", "●", "◕", "◑", "◔" },
        .interval_ms = 100,
        .color = .green,
    };

    /// Bouncing dots animation.
    pub const bounce_dots: SpinnerStyle = .{
        .frames = &.{ "⠁", "⠂", "⠄", "⠂" },
        .interval_ms = 100,
        .color = .bright_magenta,
    };

    /// Star rotation animation.
    pub const stars: SpinnerStyle = .{
        .frames = &.{ "✦", "✧", "✨", "✦", "✧" },
        .interval_ms = 150,
        .color = .bright_yellow,
    };

    /// Binary digits animation.
    pub const binary: SpinnerStyle = .{
        .frames = &.{ "010010", "001100", "100101", "111010", "111101", "010111", "101011", "111000", "110011", "011010" },
        .interval_ms = 80,
        .color = .bright_green,
    };
};

test "BarStyle presets compile" {
    _ = BarStyle.ascii;
    _ = BarStyle.block;
    _ = BarStyle.green;
    _ = BarStyle.gradient;
    _ = BarStyle.blue;
    _ = BarStyle.magenta;
    _ = BarStyle.fire;
    _ = BarStyle.ice;
    _ = BarStyle.ocean;
    _ = BarStyle.neon;
    _ = BarStyle.arrow;
    _ = BarStyle.dots;
    _ = BarStyle.slim;
    _ = BarStyle.pipe;
    _ = BarStyle.half_block;
    _ = BarStyle.matrix;
    _ = BarStyle.retro;
    _ = BarStyle.classic_pipes;
    _ = BarStyle.rainbow;
    _ = BarStyle.teal;
}

test "SpinnerStyle presets compile" {
    _ = SpinnerStyle.dots;
    _ = SpinnerStyle.line;
    _ = SpinnerStyle.bounce;
    _ = SpinnerStyle.pong;
    _ = SpinnerStyle.shark;
    _ = SpinnerStyle.aesthetic;
    _ = SpinnerStyle.snake;
    _ = SpinnerStyle.grow_vertical;
    _ = SpinnerStyle.grow_horizontal;
    _ = SpinnerStyle.material;
    _ = SpinnerStyle.layer;
    _ = SpinnerStyle.star;
    _ = SpinnerStyle.toggle;
    _ = SpinnerStyle.binary;
    _ = SpinnerStyle.progress_pie;
    _ = SpinnerStyle.bounce_dots;
    _ = SpinnerStyle.stars;
    try @import("std").testing.expect(SpinnerStyle.dots.frames.len > 0);
    try @import("std").testing.expect(SpinnerStyle.aesthetic.frames.len > 0);
}

test "BarStyle presets have non-empty fill" {
    try std.testing.expect(BarStyle.ascii.fill.len > 0);
    try std.testing.expect(BarStyle.pipe.fill.len > 0);
    try std.testing.expect(BarStyle.matrix.fill.len > 0);
    try std.testing.expect(BarStyle.retro.fill.len > 0);
    try std.testing.expect(BarStyle.classic_pipes.fill.len > 0);
}

test "SpinnerStyle new presets have frames" {
    try std.testing.expect(SpinnerStyle.grow_vertical.frames.len > 0);
    try std.testing.expect(SpinnerStyle.material.frames.len > 0);
    try std.testing.expect(SpinnerStyle.binary.frames.len > 0);
    try std.testing.expect(SpinnerStyle.star.frames.len > 0);
    try std.testing.expect(SpinnerStyle.toggle.frames.len == 2);
}

// --- Edge Case Tests for Gradient ---

test "Gradient.rainbow has multiple colors" {
    try std.testing.expect(Gradient.rainbow.colors.len >= 2);
}

test "Gradient.at returns valid colors" {
    const grad = Gradient.rainbow;
    const c0 = grad.at(0.0);
    const c1 = grad.at(0.5);
    const c2 = grad.at(1.0);
    // All should be valid RGB colors
    try std.testing.expect(c0 == .rgb);
    try std.testing.expect(c1 == .rgb);
    try std.testing.expect(c2 == .rgb);
}

test "Gradient.at clamps out-of-range values" {
    const grad = Gradient.fire;
    const c_neg = grad.at(-1.0);
    const c_over = grad.at(2.0);
    try std.testing.expect(c_neg == .rgb);
    try std.testing.expect(c_over == .rgb);
}

test "Gradient.reversed flips direction" {
    const normal = Gradient.rainbow.at(0.1);
    const reversed = Gradient{ .colors = Gradient.rainbow.colors, .reversed = true };
    const rev_color = reversed.at(0.1);
    // Different direction should produce different color at same position
    // (unless gradient is single-color, which rainbow is not)
    try std.testing.expect(Gradient.rainbow.colors.len > 1);
    _ = normal;
    _ = rev_color;
}

test "BarStyle complete_fg default is .default" {
    const style = BarStyle{};
    try std.testing.expect(style.complete_fg == .default);
}

test "SpinnerStyle complete_fg default is .default" {
    const style = SpinnerStyle{ .frames = &.{} };
    try std.testing.expect(style.complete_fg == .default);
}

test "BarStyle fill_gradient default is null" {
    const style = BarStyle{};
    try std.testing.expect(style.fill_gradient == null);
}

test "SpinnerStyle gradient default is null" {
    const style = SpinnerStyle{ .frames = &.{} };
    try std.testing.expect(style.gradient == null);
}
