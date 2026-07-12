//! loaders.zig — Root module for the loaders.zig library.
//!
//! Import this module and you get access to every public symbol:
//!
//!   const loaders = @import("loaders");
//!
//!   // Progress bars
//!   loaders.ProgressBar
//!   loaders.ProgressOptions
//!   loaders.BarStyle
//!
//!   // Spinners
//!   loaders.Spinner
//!   loaders.SpinnerStyle
//!
//!   // Batch progress
//!   loaders.BatchBar
//!   loaders.BatchOptions
//!   loaders.BatchTask
//!   loaders.TaskInit
//!   loaders.TaskState
//!
//!   // Color and styling
//!   loaders.Color
//!   loaders.Rgb
//!   loaders.Colorizer
//!   loaders.Attribute
//!   loaders.Gradient
//!   loaders.Message
//!
//!   // Template rendering
//!   loaders.RenderCtx
//!   loaders.renderTemplate
//!   loaders.hasToken
//!
//!   // Utilities
//!   loaders.utils
//!   loaders.terminal
//!   loaders.TermInfo
//!
//!   // Update checker
//!   loaders.UpdateChecker
//!   loaders.UpdateResult
//!
//!   // Version
//!   loaders.version

const std = @import("std");

const bar_mod = @import("progressbar.zig");
const spinner_mod = @import("spinner.zig");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal_mod = @import("terminal.zig");
const utils_mod = @import("utils.zig");
const batch_mod = @import("batch.zig");
const update_checker_mod = @import("update_checker.zig");
const version_mod = @import("version.zig");

pub const bar = bar_mod;
pub const spinner = spinner_mod;
pub const color = color_mod;
pub const style = style_mod;
pub const terminal = terminal_mod;
pub const utils = utils_mod;
pub const batch = batch_mod;

pub const ProgressBar = bar_mod.ProgressBar;
pub const Bar = bar_mod.ProgressBar;
pub const BarOptions = bar_mod.Options;
pub const ProgressOptions = bar_mod.Options;
pub const ProgressReader = bar_mod.ProgressReader;
pub const progressReader = bar_mod.progressReader;
pub const ProgressWriter = bar_mod.ProgressWriter;
pub const progressWriter = bar_mod.progressWriter;
pub const ProgressIoReader = bar_mod.ProgressIoReader;
pub const progressIoReader = bar_mod.progressIoReader;
pub const ProgressIoWriter = bar_mod.ProgressIoWriter;
pub const progressIoWriter = bar_mod.progressIoWriter;

pub const Spinner = spinner_mod.Spinner;
pub const SpinnerOptions = spinner_mod.Options;

pub const BatchBar = batch_mod.BatchBar;
pub const BatchOptions = batch_mod.BatchOptions;
pub const BatchTask = batch_mod.BatchTask;
pub const TaskInit = batch_mod.TaskInit;
pub const TaskState = batch_mod.TaskState;

pub const Color = color_mod.Color;
pub const Rgb = color_mod.Rgb;
pub const Colorizer = color_mod.Colorizer;
pub const Attribute = color_mod.Attribute;
pub const writeColored = color_mod.writeColored;

pub const BarStyle = style_mod.BarStyle;
pub const SpinnerStyle = style_mod.SpinnerStyle;
pub const Gradient = style_mod.Gradient;
pub const Message = style_mod.Message;

pub const TermInfo = terminal_mod.TermInfo;

pub const RenderCtx = bar_mod.RenderCtx;
pub const renderTemplate = bar_mod.renderTemplate;
pub const hasToken = bar_mod.hasToken;

pub const UpdateChecker = update_checker_mod;
pub const UpdateResult = update_checker_mod.UpdateResult;

pub const version: []const u8 = version_mod.version;

comptime {
    _ = bar_mod;
    _ = spinner_mod;
    _ = color_mod;
    _ = style_mod;
    _ = terminal_mod;
    _ = utils_mod;
    _ = batch_mod;
    _ = update_checker_mod;
    _ = version_mod;
}

test {
    _ = bar_mod;
    _ = spinner_mod;
    _ = color_mod;
    _ = style_mod;
    _ = terminal_mod;
    _ = utils_mod;
    _ = batch_mod;
    _ = update_checker_mod;
    _ = version_mod;
}
