const std = @import("std");

pub const tint = @import("tint");

pub const terminal = @import("terminal.zig");
pub const template = @import("template.zig");
pub const style = @import("style.zig");
pub const progressBarMod = @import("progress_bar.zig");
pub const spinnerMod = @import("spinner.zig");
pub const blockBarMod = @import("block_bar.zig");
pub const indeterminateMod = @import("indeterminate.zig");
pub const multiBarMod = @import("multi_bar.zig");
pub const batchMod = @import("batch.zig");
pub const stepMod = @import("step.zig");

pub const FontStyle = style.FontStyle;

// tint.zig color types (Zig 0.17.0 namespaced API)
pub const Color = style.Color;
pub const RgbColor = style.RgbColor;
pub const HexColor = style.HexColor;
pub const Ansi256Color = style.Ansi256Color;
pub const HslColor = style.HslColor;
pub const HsvColor = style.HsvColor;
pub const CmykColor = style.CmykColor;
pub const XyzColor = style.XyzColor;
pub const LabColor = style.LabColor;
pub const Ansi4 = style.Ansi4;
pub const Sequence = style.Sequence;

// tint.zig style types
pub const Style = style.Style;
pub const Capability = style.Capability;

// tint.zig color constructors
pub const fg = style.fg;
pub const bg = style.bg;
pub const underline = style.underlineColor;
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
pub const makeHsv = style.hsv;
pub const makeCmyk = style.cmyk;
pub const makeKelvin = style.kelvin;
pub const makeNamed = style.namedColor;
pub const colorToAnsi = style.colorToAnsi;
pub const styleToAnsi = style.styleToAnsi;

// tint.zig reset sequences
pub const reset = style.reset;
pub const resetFg = style.resetFg;
pub const resetBg = style.resetBg;
pub const resetAll = style.resetAll;

pub const ProgressBar = progressBarMod.ProgressBar;
pub const ProgressBarConfig = progressBarMod.ProgressBarConfig;
pub const CustomBarStyle = progressBarMod.CustomBarStyle;
pub const ProgressState = progressBarMod.ProgressState;
pub const Status = progressBarMod.Status;
pub const FinishConfig = progressBarMod.FinishConfig;
pub const ThreadMode = progressBarMod.ThreadMode;
pub const Direction = progressBarMod.Direction;

pub const Spinner = spinnerMod.Spinner;
pub const SpinnerConfig = spinnerMod.SpinnerConfig;
pub const SpinnerState = spinnerMod.SpinnerState;

pub const BlockProgressBar = blockBarMod.BlockProgressBar;
pub const BlockBarConfig = blockBarMod.BlockBarConfig;
pub const BlockBarStyle = blockBarMod.BlockBarStyle;

pub const Indeterminate = indeterminateMod.Indeterminate;
pub const IndeterminateConfig = indeterminateMod.IndeterminateConfig;
pub const IndeterminateState = indeterminateMod.IndeterminateState;

pub const MultiBar = multiBarMod.MultiBar;
pub const MultiBarConfig = multiBarMod.MultiBarConfig;
pub const MultiBarMode = multiBarMod.Mode;

pub const BatchRunner = batchMod.BatchRunner;
pub const BatchConfig = batchMod.BatchConfig;
pub const BatchMode = batchMod.Mode;

pub const StepSequence = stepMod.StepSequence;
pub const StepSequenceConfig = stepMod.StepSequenceConfig;
pub const StepConfig = stepMod.StepConfig;
pub const StepKind = stepMod.StepKind;
pub const StepStatus = stepMod.StepStatus;

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

pub fn formatRate(buf: []u8, perSec: f64) []const u8 {
    return template.formatRate(buf, perSec);
}

test {
    _ = template;
    _ = style;
    _ = progressBarMod;
    _ = spinnerMod;
    _ = blockBarMod;
    _ = indeterminateMod;
    _ = multiBarMod;
    _ = stepMod;
}

test "tint integration" {
    try std.testing.expectEqualStrings("\x1b[32m", fg(.{ .ansi4 = .green }).slice());
    try std.testing.expectEqualStrings("\x1b[44m", bg(.{ .ansi4 = .blue }).slice());
    try std.testing.expectEqualStrings("\x1b[38;2;255;0;0m", makeRgb(255, 0, 0).fg().slice());
    try std.testing.expectEqualStrings("\x1b[38;2;0;255;0m", makeHex(0x00FF00).fg().slice());
    try std.testing.expectEqualStrings("\x1b[38;5;196m", makeAnsi256(196).fg().slice());
}
