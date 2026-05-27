//! style.zig — Named visual styles for progress bars and spinners.
//!
//! `BarStyle` controls the visual appearance of a progress bar: bracket
//! characters, fill/empty glyphs, and ANSI color attributes.
//!
//! `SpinnerStyle` controls the animation frames, interval, and default
//! color for a spinner.  Over 30 built-in presets are provided.

const std = @import("std");
const color = @import("color.zig");

pub const Color = color.Color;
pub const Attribute = color.Attribute;

// ── Bar Style ─────────────────────────────────────────────────────────────────

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

    // ── Built-in presets ──────────────────────────────────────────────────────

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
};

// ── Spinner Style ─────────────────────────────────────────────────────────────

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

    // ── Built-in presets ──────────────────────────────────────────────────────

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

    /// Vertical bar fill animation (8-frame).
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
        .frames = &.{ "▐|\\____________▌", "▐_|\\___________▌", "▐__|\\__________▌", "▐___|\\______ ___▌", "▐____|\\________▌", "▐_____|\\________▌", "▐______|\\______▌", "▐_______|\\________▌", "▐________|\\____▌", "▐_________|\\___▌", "▐__________|\\__▌", "▐___________|\\_ ▌", "▐____________|\\▌", "▐____________/|▌", "▐___________/|_▌", "▐__________/|__▌", "▐_________/|___▌", "▐________/|____▌", "▐_______/|_____▌", "▐______/|______▌", "▐_____/|_______▌", "▐____/|________▌", "▐___/|_________▌", "▐__/|__________▌", "▐_/|___________▌", "▐/|____________▌" },
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
};

// ── Tests ──────────────────────────────────────────────────────────────────────

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
}

test "SpinnerStyle presets compile" {
    _ = SpinnerStyle.dots;
    _ = SpinnerStyle.line;
    _ = SpinnerStyle.bounce;
    _ = SpinnerStyle.pong;
    _ = SpinnerStyle.shark;
    _ = SpinnerStyle.aesthetic;
    _ = SpinnerStyle.snake;
    try @import("std").testing.expect(SpinnerStyle.dots.frames.len > 0);
    try @import("std").testing.expect(SpinnerStyle.aesthetic.frames.len > 0);
}
