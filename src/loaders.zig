const std = @import("std");

pub const terminal = @import("terminal.zig");
pub const template = @import("template.zig");
pub const style = @import("style.zig");
pub const progress_bar = @import("progress_bar.zig");
pub const spinner = @import("spinner.zig");
pub const block_bar = @import("block_bar.zig");
pub const indeterminate = @import("indeterminate.zig");
pub const multi_bar = @import("multi_bar.zig");
pub const batch = @import("batch.zig");
pub const step = @import("step.zig");

pub const FontStyle = style.FontStyle;
pub const Color = style.Color;
pub const RgbColor = style.RgbColor;
pub const HexColor = style.HexColor;
pub const Ansi256Color = style.Ansi256Color;
pub const HslColor = style.HslColor;
pub const Style = style.Style;
pub const Named = style.Named;
pub const colorPresets = style.presets;

pub const fg = style.fg;
pub const bg = style.bg;
pub const fgRgb = style.fgRgb;
pub const bgRgb = style.bgRgb;
pub const fgHex = style.fgHex;
pub const bgHex = style.bgHex;
pub const fg256 = style.fg256;
pub const bg256 = style.bg256;
pub const makeRgb = style.rgb;
pub const makeHex = style.hex;
pub const makeAnsi256 = style.ansi256;
pub const makeHsl = style.hsl;
pub const makeNamed = style.named_color;

pub const ProgressBar = progress_bar.ProgressBar;
pub const ProgressBarConfig = progress_bar.ProgressBarConfig;
pub const CustomBarStyle = progress_bar.CustomBarStyle;
pub const ProgressState = progress_bar.ProgressState;
pub const Status = progress_bar.Status;
pub const FinishConfig = progress_bar.FinishConfig;
pub const ThreadMode = progress_bar.ThreadMode;
pub const Direction = progress_bar.Direction;

pub const Spinner = spinner.Spinner;
pub const SpinnerConfig = spinner.SpinnerConfig;
pub const SpinnerState = spinner.SpinnerState;

pub const BlockProgressBar = block_bar.BlockProgressBar;
pub const BlockBarConfig = block_bar.BlockBarConfig;
pub const BlockBarStyle = block_bar.BlockBarStyle;

pub const Indeterminate = indeterminate.Indeterminate;
pub const IndeterminateConfig = indeterminate.IndeterminateConfig;
pub const IndeterminateState = indeterminate.IndeterminateState;

pub const MultiBar = multi_bar.MultiBar;
pub const MultiBarConfig = multi_bar.MultiBarConfig;
pub const MultiBarMode = multi_bar.Mode;

pub const BatchRunner = batch.BatchRunner;
pub const BatchConfig = batch.BatchConfig;
pub const BatchMode = batch.Mode;

pub const StepSequence = step.StepSequence;
pub const StepSequenceConfig = step.StepSequenceConfig;
pub const StepConfig = step.StepConfig;
pub const StepKind = step.StepKind;
pub const StepStatus = step.StepStatus;

pub const FormatterSet = template.FormatterSet;
pub const TemplateValues = template.Values;
pub const renderTemplate = template.render;
pub const validateTemplate = template.validate;

pub const stdoutWriter = terminal.stdoutWriter;
pub const eraseLine = terminal.eraseLine;
pub const moveUp = terminal.moveUp;
pub const moveDown = terminal.moveDown;
pub const moveRight = terminal.moveRight;
pub const moveLeft = terminal.moveLeft;
pub const hideCursor = terminal.hideCursor;
pub const showCursor = terminal.showCursor;
pub const getTerminalSize = terminal.getSize;
pub const ensureTerminal = terminal.ensureInitialized;

pub fn sleepMs(io: std.Io, ms: u64) void {
    terminal.sleepMs(io, ms);
}

pub fn formatNs(buf: []u8, ns: u64) []const u8 {
    return template.formatNs(buf, ns);
}

pub fn formatRate(buf: []u8, per_sec: f64) []const u8 {
    return template.formatRate(buf, per_sec);
}

test {
    _ = template;
    _ = style;
    _ = progress_bar;
    _ = spinner;
    _ = block_bar;
    _ = indeterminate;
    _ = multi_bar;
    _ = step;
}

test "tint integration" {
    try std.testing.expectEqualStrings("\x1b[32m", fg(.{ .ansi4 = .green }));
    try std.testing.expectEqualStrings("\x1b[44m", bg(.{ .ansi4 = .blue }));
    try std.testing.expectEqualStrings("\x1b[38;2;255;0;0m", makeRgb(255, 0, 0).toFg());
    try std.testing.expectEqualStrings("\x1b[38;2;0;255;0m", makeHex(0x00FF00).toFg());
    try std.testing.expectEqualStrings("\x1b[38;5;196m", makeAnsi256(196).toFg());
}
