const std = @import("std");
const tint = @import("tint");
const templateMod = @import("template.zig");
const styleMod = @import("style.zig");
const terminal = @import("terminal.zig");

pub const FontStyle = styleMod.FontStyle;
pub const Formatters = templateMod.FormatterSet;
pub const InitError = templateMod.InitError;

pub const ThreadMode = enum {
    /// Manual rendering — the caller drives updates.
    none,
    /// A background thread redraws the bar until it finishes.
    auto,
    /// The caller drives updates from an external thread.
    external,
};

pub const Status = enum {
    pending,
    running,
    paused,
    finished,
    failed,
};

pub const Direction = enum {
    incremental,
    decremental,
};

pub const FinishConfig = struct {
    clear: bool = false,
    finalText: ?[]const u8 = null,
    newline: bool = true,
};

pub const CustomBarStyle = struct {
    filled: []const u8 = "#",
    empty: []const u8 = "-",
    head: []const u8 = ">",
    leftBracket: []const u8 = "[",
    rightBracket: []const u8 = "]",
    partialFill: ?[]const []const u8 = null,
};

pub const Callback = *const fn (ctx: ?*anyopaque) void;

pub const ProgressBarConfig = struct {
    total: u64,
    current: u64 = 0,
    minProgress: u64 = 0,
    width: u32 = 40,
    style: CustomBarStyle = .{},
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

pub const ProgressState = struct {
    progress: u64,
    total: u64,
    percent: f64,
    elapsedNs: u64,
    etaNs: u64,
    speed: f64,
    status: Status,
};

pub const ProgressBar = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: ProgressBarConfig,
    progress: u64,
    statusState: Status,
    startTime: std.Io.Timestamp,
    elapsedNs: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stopThread: std.atomic.Value(bool),
    drawOnUpdate: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: ProgressBarConfig) InitError!ProgressBar {
        try templateMod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .progress = config.current,
            .statusState = .pending,
            .startTime = .zero,
            .elapsedNs = 0,
            .mutex = .init,
            .thread = null,
            .stopThread = std.atomic.Value(bool).init(false),
            .drawOnUpdate = true,
        };
    }

    pub fn deinit(self: *ProgressBar) void {
        self.stopRenderThread();
    }

    pub fn start(self: *ProgressBar) !void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .pending) {
            self.startLocked();
            self.maybeRedraw();
        }
    }

    pub fn tick(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .pending) self.startLocked();
        if (self.statusState != .running) return;
        if (self.progress < self.config.total) self.progress += 1;
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.onTick) |cb| cb(self.config.ctx);
    }

    pub fn setProgress(self: *ProgressBar, value: u64) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .pending) self.startLocked();
        if (self.statusState != .running) return;
        self.progress = @min(value, self.config.total);
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.onTick) |cb| cb(self.config.ctx);
    }

    pub fn pause(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .running) {
            self.updateElapsed();
            self.statusState = .paused;
            if (self.config.onPause) |cb| cb(self.config.ctx);
        }
    }

    pub fn unpause(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .paused) {
            self.statusState = .running;
            self.startTime = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsedNs) });
            self.maybeRedraw();
            if (self.config.onUnpause) |cb| cb(self.config.ctx);
        }
    }

    pub fn forceRedraw(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.drawOnUpdate) self.locklessRedraw();
    }

    pub fn finish(self: *ProgressBar, config: FinishConfig) void {
        self.finishNow();
        self.lock();
        defer self.unlock();
        if (self.drawOnUpdate) {
            self.locklessRedraw();
            self.finishLine(config);
        }
    }

    pub fn fail(self: *ProgressBar, message: []const u8) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .failed;
        if (self.config.onFinish) |cb| cb(self.config.ctx);
        if (self.drawOnUpdate) {
            terminal.eraseLine(self.io);
            const writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\x1b[31m") catch {};
            writer.writeAll("FAILED: ") catch {};
            writer.writeAll(message) catch {};
            writer.writeAll("\x1b[0m") catch {};
            writer.writeAll("\n") catch {};
            writer.flush() catch {};
        }
    }

    pub fn setText(self: *ProgressBar, text: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.text = text;
        self.maybeRedraw();
    }

    pub fn setPrefix(self: *ProgressBar, prefix: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.prefix = prefix;
    }

    pub fn setSuffix(self: *ProgressBar, suffix: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.suffix = suffix;
    }

    pub fn setColor(self: *ProgressBar, color: ?tint.ansi.Sequence) void {
        self.lock();
        defer self.unlock();
        self.config.color = color;
    }

    pub fn setStyle(self: *ProgressBar, style: CustomBarStyle) void {
        self.lock();
        defer self.unlock();
        self.config.style = style;
    }

    pub fn setTemplate(self: *ProgressBar, template: []const u8) !void {
        try templateMod.validate(template, self.config.formatters);
        self.lock();
        defer self.unlock();
        self.config.template = template;
        self.maybeRedraw();
    }

    pub fn state(self: *ProgressBar) ProgressState {
        self.lock();
        defer self.unlock();
        return .{
            .progress = self.progress,
            .total = self.config.total,
            .percent = self.percentage(),
            .elapsedNs = self.elapsedNs,
            .etaNs = self.etaNs(),
            .speed = self.speedPerSec(),
            .status = self.statusState,
        };
    }

    pub fn getStatus(self: *ProgressBar) Status {
        self.lock();
        defer self.unlock();
        return self.statusState;
    }

    pub fn getCurrent(self: *ProgressBar) u64 {
        self.lock();
        defer self.unlock();
        return self.progress;
    }

    pub fn setDrawOnUpdate(self: *ProgressBar, draw: bool) void {
        self.drawOnUpdate = draw;
    }

    pub fn redrawLine(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        self.locklessRedraw();
    }

    /// Marks the bar finished without drawing. Used by MultiBar and BatchRunner.
    pub fn finishNow(self: *ProgressBar) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .finished;
        self.progress = self.config.total;
        self.updateElapsed();
        if (self.config.onFinish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *ProgressBar) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *ProgressBar) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *ProgressBar) void {
        if (self.drawOnUpdate and (self.statusState == .running or self.statusState == .paused)) {
            self.locklessRedraw();
        }
    }

    fn startLocked(self: *ProgressBar) void {
        self.statusState = .running;
        self.startTime = std.Io.Timestamp.now(self.io, .awake);
        if (self.config.threadMode == .auto) {
            self.stopThread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    fn renderLoop(self: *ProgressBar) void {
        while (!self.stopThread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.intervalMs);
            self.lock();
            const running = self.statusState == .running;
            self.unlock();
            if (running) self.forceRedraw();
        }
    }

    fn stopRenderThread(self: *ProgressBar) void {
        self.stopThread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *ProgressBar) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.startTime.nanoseconds;
        self.elapsedNs = @intCast(@max(diff, 0));
    }

    fn effective(self: *ProgressBar) u64 {
        return self.progress;
    }

    fn percentage(self: *ProgressBar) f64 {
        if (self.config.total == 0) return 0;
        return @as(f64, @floatFromInt(self.effective())) / @as(f64, @floatFromInt(self.config.total)) * 100.0;
    }

    fn etaNs(self: *ProgressBar) u64 {
        const eff = self.effective();
        if (eff > 0 and eff < self.config.total) {
            return (self.elapsedNs * (self.config.total - eff)) / eff;
        }
        return 0;
    }

    fn speedPerSec(self: *ProgressBar) f64 {
        if (self.elapsedNs == 0) return 0;
        return @as(f64, @floatFromInt(self.effective())) / (@as(f64, @floatFromInt(self.elapsedNs)) / 1e9);
    }

    fn finishLine(self: *ProgressBar, config: FinishConfig) void {
        const writer = terminal.stdoutWriter(self.io);
        if (config.clear) {
            terminal.eraseLine(self.io);
        } else if (config.finalText) |ft| {
            terminal.eraseLine(self.io);
            writer.writeAll(ft) catch {};
            if (config.newline) writer.writeAll("\n") catch {};
        } else {
            if (config.newline) writer.writeAll("\n") catch {};
        }
    }

    fn locklessRedraw(self: *ProgressBar) void {
        const writer = terminal.stdoutWriter(self.io);

        var barBuf: [2048]u8 = undefined;
        var barAcc = templateMod.Accum.init(&barBuf);
        self.renderBar(&barAcc);

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = templateMod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .bar = barAcc.get(),
            .percent = self.percentage(),
            .count = self.progress,
            .total = self.config.total,
            .elapsedNs = self.elapsedNs,
            .etaNs = self.etaNs(),
            .speed = self.speedPerSec(),
            .color = self.config.color,
        };
        const rendered = templateMod.render(&buf, &scratch, self.config.template, values, self.config.formatters) catch return;
        // Clear line and write content
        writer.writeAll("\r\x1b[K") catch {};
        if (self.config.color) |seq| writer.writeAll(seq.slice()) catch {};
        if (!self.config.textStyle.isEmpty()) {
            writer.writeAll(self.config.textStyle.toAnsi().slice()) catch {};
        }
        writer.writeAll(rendered) catch {};
        if (self.config.color != null) writer.writeAll("\x1b[0m") catch {};
        writer.flush() catch {};
    }

    fn renderBar(self: *ProgressBar, acc: *templateMod.Accum) void {
        const barStyle = self.config.style;
        acc.write(barStyle.leftBracket) catch return;
        const width = self.config.width;
        const total = self.config.total;
        const eff = self.effective();
        const filledCount: u32 = if (total > 0)
            @intCast(@min(@as(u64, width) * eff / total, width))
        else
            0;
        var j: u32 = 0;
        while (j < width) : (j += 1) {
            if (j < filledCount) {
                acc.write(barStyle.filled) catch return;
            } else if (j == filledCount and eff < total) {
                if (barStyle.partialFill) |parts| {
                    if (total > 0 and width > 0) {
                        const remainder = (@as(u64, width) * eff) % total;
                        const frac = @as(f64, @floatFromInt(remainder)) / @as(f64, @floatFromInt(total));
                        const idx: usize = @intFromFloat(frac * 7.0);
                        acc.write(parts[@min(idx, parts.len - 1)]) catch return;
                    }
                } else {
                    acc.write(barStyle.head) catch return;
                }
            } else {
                acc.write(barStyle.empty) catch return;
            }
        }
        acc.write(barStyle.rightBracket) catch return;
    }
};

test "progress bar init validates template" {
    try std.testing.expectError(error.MissingFormatter, ProgressBar.init(std.testing.allocator, std.testing.io, .{
        .total = 10,
        .template = "{bar} {elapsed}",
    }));
}
