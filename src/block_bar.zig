const std = @import("std");
const tint = @import("tint");
const progressBar = @import("progress_bar.zig");
const templateMod = @import("template.zig");
const styleMod = @import("style.zig");

pub const FontStyle = styleMod.FontStyle;
pub const Formatters = templateMod.FormatterSet;
pub const ThreadMode = progressBar.ThreadMode;
pub const Status = progressBar.Status;
pub const Direction = progressBar.Direction;
pub const FinishConfig = progressBar.FinishConfig;
pub const Callback = progressBar.Callback;
pub const InitError = templateMod.InitError;

const blockPartials = [_][]const u8{ "▏", "▎", "▍", "▌", "▋", "▊", "▉" };

pub const BlockBarStyle = struct {
    filled: []const u8 = "█",
    empty: []const u8 = " ",
    leftBracket: []const u8 = "",
    rightBracket: []const u8 = "",
};

pub const BlockBarConfig = struct {
    total: u64,
    current: u64 = 0,
    minProgress: u64 = 0,
    width: u32 = 40,
    style: BlockBarStyle = .{},
    template: []const u8 = "{bar} {percent}%",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?tint.ansi.Sequence = null,
    textStyle: FontStyle = .{},
    formatters: Formatters = .{},
    threadMode: ThreadMode = .none,
    intervalMs: u32 = 16,
    direction: Direction = .incremental,
    onTick: ?Callback = null,
    onFinish: ?Callback = null,
    onPause: ?Callback = null,
    onUnpause: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const BlockState = progressBar.ProgressState;

pub const BlockProgressBar = struct {
    bar: progressBar.ProgressBar,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: BlockBarConfig) InitError!BlockProgressBar {
        return .{
            .bar = try progressBar.ProgressBar.init(allocator, io, .{
                .total = config.total,
                .current = config.current,
                .minProgress = config.minProgress,
                .width = config.width,
                .style = .{
                    .filled = config.style.filled,
                    .empty = config.style.empty,
                    .head = "",
                    .leftBracket = config.style.leftBracket,
                    .rightBracket = config.style.rightBracket,
                    .partialFill = &blockPartials,
                },
                .template = config.template,
                .prefix = config.prefix,
                .suffix = config.suffix,
                .text = config.text,
                .color = config.color,
                .textStyle = config.textStyle,
                .formatters = config.formatters,
                .threadMode = config.threadMode,
                .intervalMs = config.intervalMs,
                .direction = config.direction,
                .onTick = config.onTick,
                .onFinish = config.onFinish,
                .onPause = config.onPause,
                .onUnpause = config.onUnpause,
                .ctx = config.ctx,
            }),
        };
    }

    pub fn deinit(self: *BlockProgressBar) void {
        self.bar.deinit();
    }

    pub fn start(self: *BlockProgressBar) !void {
        try self.bar.start();
    }

    pub fn tick(self: *BlockProgressBar) void {
        self.bar.tick();
    }

    pub fn setProgress(self: *BlockProgressBar, value: u64) void {
        self.bar.setProgress(value);
    }

    pub fn pause(self: *BlockProgressBar) void {
        self.bar.pause();
    }

    pub fn unpause(self: *BlockProgressBar) void {
        self.bar.unpause();
    }

    pub fn forceRedraw(self: *BlockProgressBar) void {
        self.bar.forceRedraw();
    }

    pub fn finish(self: *BlockProgressBar, config: FinishConfig) void {
        self.bar.finish(config);
    }

    pub fn fail(self: *BlockProgressBar, message: []const u8) void {
        self.bar.fail(message);
    }

    pub fn setText(self: *BlockProgressBar, text: []const u8) void {
        self.bar.setText(text);
    }

    pub fn setPrefix(self: *BlockProgressBar, prefix: []const u8) void {
        self.bar.setPrefix(prefix);
    }

    pub fn setSuffix(self: *BlockProgressBar, suffix: []const u8) void {
        self.bar.setSuffix(suffix);
    }

    pub fn setColor(self: *BlockProgressBar, color: ?tint.ansi.Sequence) void {
        self.bar.setColor(color);
    }

    pub fn setTemplate(self: *BlockProgressBar, template: []const u8) !void {
        try self.bar.setTemplate(template);
    }

    pub fn state(self: *BlockProgressBar) BlockState {
        return self.bar.state();
    }

    pub fn getStatus(self: *BlockProgressBar) Status {
        return self.bar.getStatus();
    }

    pub fn getCurrent(self: *BlockProgressBar) u64 {
        return self.bar.getCurrent();
    }
};
