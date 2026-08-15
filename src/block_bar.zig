const std = @import("std");
const progress_bar = @import("progress_bar.zig");
const template_mod = @import("template.zig");
const style_mod = @import("style.zig");

pub const FontStyle = style_mod.FontStyle;
pub const Formatters = template_mod.FormatterSet;
pub const ThreadMode = progress_bar.ThreadMode;
pub const Status = progress_bar.Status;
pub const Direction = progress_bar.Direction;
pub const FinishConfig = progress_bar.FinishConfig;
pub const Callback = progress_bar.Callback;
pub const InitError = template_mod.InitError;

const block_partials = [_][]const u8{ "▏", "▎", "▍", "▌", "▋", "▊", "▉" };

pub const BlockBarStyle = struct {
    filled: []const u8 = "█",
    empty: []const u8 = " ",
    left_bracket: []const u8 = "",
    right_bracket: []const u8 = "",
};

pub const BlockBarConfig = struct {
    total: u64,
    current: u64 = 0,
    min_progress: u64 = 0,
    width: u32 = 40,
    style: BlockBarStyle = .{},
    template: []const u8 = "{bar} {percent}%",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,
    text_style: FontStyle = .{},
    formatters: Formatters = .{},
    thread_mode: ThreadMode = .none,
    interval_ms: u32 = 16,
    direction: Direction = .incremental,
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    on_pause: ?Callback = null,
    on_resume: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const BlockState = progress_bar.ProgressState;

pub const BlockProgressBar = struct {
    bar: progress_bar.ProgressBar,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: BlockBarConfig) InitError!BlockProgressBar {
        return .{
            .bar = try progress_bar.ProgressBar.init(allocator, io, .{
                .total = config.total,
                .current = config.current,
                .min_progress = config.min_progress,
                .width = config.width,
                .style = .{
                    .filled = config.style.filled,
                    .empty = config.style.empty,
                    .head = "",
                    .left_bracket = config.style.left_bracket,
                    .right_bracket = config.style.right_bracket,
                    .partial_fill = &block_partials,
                },
                .template = config.template,
                .prefix = config.prefix,
                .suffix = config.suffix,
                .text = config.text,
                .color = config.color,
                .text_style = config.text_style,
                .formatters = config.formatters,
                .thread_mode = config.thread_mode,
                .interval_ms = config.interval_ms,
                .direction = config.direction,
                .on_tick = config.on_tick,
                .on_finish = config.on_finish,
                .on_pause = config.on_pause,
                .on_resume = config.on_resume,
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

    pub fn continue_(self: *BlockProgressBar) void {
        self.bar.continue_();
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

    pub fn setColor(self: *BlockProgressBar, color: ?[]const u8) void {
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
