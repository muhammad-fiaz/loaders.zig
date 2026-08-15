const std = @import("std");
const template_mod = @import("template.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");

pub const FontStyle = style_mod.FontStyle;
pub const Formatters = template_mod.FormatterSet;
pub const InitError = template_mod.InitError;

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
    final_text: ?[]const u8 = null,
    newline: bool = true,
};

pub const CustomBarStyle = struct {
    filled: []const u8 = "#",
    empty: []const u8 = "-",
    head: []const u8 = ">",
    left_bracket: []const u8 = "[",
    right_bracket: []const u8 = "]",
    partial_fill: ?[]const []const u8 = null,
};

pub const Callback = *const fn (ctx: ?*anyopaque) void;

pub const ProgressBarConfig = struct {
    total: u64,
    current: u64 = 0,
    min_progress: u64 = 0,
    width: u32 = 40,
    style: CustomBarStyle = .{},
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

pub const ProgressState = struct {
    progress: u64,
    total: u64,
    percent: f64,
    elapsed_ns: u64,
    eta_ns: u64,
    speed: f64,
    status: Status,
};

pub const ProgressBar = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: ProgressBarConfig,
    progress: u64,
    status_state: Status,
    start_time: std.Io.Timestamp,
    elapsed_ns: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),
    draw_on_update: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: ProgressBarConfig) InitError!ProgressBar {
        try template_mod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .progress = config.current,
            .status_state = .pending,
            .start_time = .zero,
            .elapsed_ns = 0,
            .mutex = .init,
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
            .draw_on_update = true,
        };
    }

    pub fn deinit(self: *ProgressBar) void {
        self.stopRenderThread();
    }

    pub fn start(self: *ProgressBar) !void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .pending) {
            self.startLocked();
            self.maybeRedraw();
        }
    }

    pub fn tick(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .pending) self.startLocked();
        if (self.status_state != .running) return;
        if (self.progress < self.config.total) self.progress += 1;
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.on_tick) |cb| cb(self.config.ctx);
    }

    pub fn setProgress(self: *ProgressBar, value: u64) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .pending) self.startLocked();
        if (self.status_state != .running) return;
        self.progress = @min(value, self.config.total);
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.on_tick) |cb| cb(self.config.ctx);
    }

    pub fn pause(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .running) {
            self.updateElapsed();
            self.status_state = .paused;
            if (self.config.on_pause) |cb| cb(self.config.ctx);
        }
    }

    pub fn continue_(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .paused) {
            self.status_state = .running;
            self.start_time = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsed_ns) });
            self.maybeRedraw();
            if (self.config.on_resume) |cb| cb(self.config.ctx);
        }
    }

    pub fn forceRedraw(self: *ProgressBar) void {
        self.lock();
        defer self.unlock();
        if (self.draw_on_update) self.locklessRedraw();
    }

    pub fn finish(self: *ProgressBar, config: FinishConfig) void {
        self.finishNow();
        self.lock();
        defer self.unlock();
        if (self.draw_on_update) {
            self.locklessRedraw();
            self.finishLine(config);
        }
    }

    pub fn fail(self: *ProgressBar, message: []const u8) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.status_state == .finished or self.status_state == .failed) return;
        self.status_state = .failed;
        if (self.config.on_finish) |cb| cb(self.config.ctx);
        if (self.draw_on_update) {
            terminal.eraseLine(self.io);
            var writer = terminal.stdoutWriter(self.io);
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

    pub fn setColor(self: *ProgressBar, color: ?[]const u8) void {
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
        try template_mod.validate(template, self.config.formatters);
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
            .elapsed_ns = self.elapsed_ns,
            .eta_ns = self.etaNs(),
            .speed = self.speedPerSec(),
            .status = self.status_state,
        };
    }

    pub fn getStatus(self: *ProgressBar) Status {
        self.lock();
        defer self.unlock();
        return self.status_state;
    }

    pub fn getCurrent(self: *ProgressBar) u64 {
        self.lock();
        defer self.unlock();
        return self.progress;
    }

    pub fn setDrawOnUpdate(self: *ProgressBar, draw: bool) void {
        self.draw_on_update = draw;
    }

    pub fn redrawLine(self: *ProgressBar) void {
        self.locklessRedraw();
    }

    /// Marks the bar finished without drawing. Used by MultiBar and BatchRunner.
    pub fn finishNow(self: *ProgressBar) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.status_state == .finished or self.status_state == .failed) return;
        self.status_state = .finished;
        self.progress = self.config.total;
        self.updateElapsed();
        if (self.config.on_finish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *ProgressBar) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *ProgressBar) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *ProgressBar) void {
        if (self.draw_on_update and (self.status_state == .running or self.status_state == .paused)) {
            self.locklessRedraw();
        }
    }

    fn startLocked(self: *ProgressBar) void {
        self.status_state = .running;
        self.start_time = std.Io.Timestamp.now(self.io, .awake);
        if (self.config.thread_mode == .auto) {
            self.stop_thread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    fn renderLoop(self: *ProgressBar) void {
        while (!self.stop_thread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.interval_ms);
            self.lock();
            const running = self.status_state == .running;
            self.unlock();
            if (running) self.forceRedraw();
        }
    }

    fn stopRenderThread(self: *ProgressBar) void {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *ProgressBar) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.start_time.nanoseconds;
        self.elapsed_ns = @intCast(@max(diff, 0));
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
            return (self.elapsed_ns * (self.config.total - eff)) / eff;
        }
        return 0;
    }

    fn speedPerSec(self: *ProgressBar) f64 {
        if (self.elapsed_ns == 0) return 0;
        return @as(f64, @floatFromInt(self.effective())) / (@as(f64, @floatFromInt(self.elapsed_ns)) / 1e9);
    }

    fn finishLine(self: *ProgressBar, config: FinishConfig) void {
        var writer = terminal.stdoutWriter(self.io);
        if (config.clear) {
            terminal.eraseLine(self.io);
        } else if (config.final_text) |ft| {
            terminal.eraseLine(self.io);
            writer.writeAll(ft) catch {};
            if (config.newline) writer.writeAll("\n") catch {};
        } else {
            if (config.newline) writer.writeAll("\n") catch {};
        }
    }

    fn locklessRedraw(self: *ProgressBar) void {
        var writer = terminal.stdoutWriter(self.io);

        var bar_buf: [2048]u8 = undefined;
        var bar_acc = template_mod.Accum.init(&bar_buf);
        self.renderBar(&bar_acc);

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = template_mod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .bar = bar_acc.get(),
            .percent = self.percentage(),
            .count = self.progress,
            .total = self.config.total,
            .elapsed_ns = self.elapsed_ns,
            .eta_ns = self.etaNs(),
            .speed = self.speedPerSec(),
            .color = self.config.color,
        };
        const rendered = template_mod.render(&buf, &scratch, self.config.template, values, self.config.formatters) catch return;
        // Clear line and write content
        writer.writeAll("\r\x1b[K") catch {};
        if (self.config.color) |c| writer.writeAll(c) catch {};
        if (!self.config.text_style.isEmpty()) {
            var style_buf: [32]u8 = undefined;
            writer.writeAll(self.config.text_style.toAnsi(&style_buf)) catch {};
        }
        writer.writeAll(rendered) catch {};
        if (self.config.color != null) writer.writeAll("\x1b[0m") catch {};
        writer.flush() catch {};
    }

    fn renderBar(self: *ProgressBar, acc: *template_mod.Accum) void {
        const style = self.config.style;
        acc.write(style.left_bracket) catch return;
        const width = self.config.width;
        const total = self.config.total;
        const eff = self.effective();
        const filled_count: u32 = if (total > 0)
            @intCast(@min(@as(u64, width) * eff / total, width))
        else
            0;
        var j: u32 = 0;
        while (j < width) : (j += 1) {
            if (j < filled_count) {
                acc.write(style.filled) catch return;
            } else if (j == filled_count and eff < total) {
                if (style.partial_fill) |parts| {
                    if (total > 0 and width > 0) {
                        const remainder = (@as(u64, width) * eff) % total;
                        const frac = @as(f64, @floatFromInt(remainder)) / @as(f64, @floatFromInt(total));
                        const idx: usize = @intFromFloat(frac * 7.0);
                        acc.write(parts[@min(idx, parts.len - 1)]) catch return;
                    }
                } else {
                    acc.write(style.head) catch return;
                }
            } else {
                acc.write(style.empty) catch return;
            }
        }
        acc.write(style.right_bracket) catch return;
    }
};

test "progress bar init validates template" {
    try std.testing.expectError(error.MissingFormatter, ProgressBar.init(std.testing.allocator, std.testing.io, .{
        .total = 10,
        .template = "{bar} {elapsed}",
    }));
}
