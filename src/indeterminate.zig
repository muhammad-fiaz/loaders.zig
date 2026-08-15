const std = @import("std");
const template_mod = @import("template.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");
const progress_bar = @import("progress_bar.zig");

pub const FontStyle = style_mod.FontStyle;
pub const Formatters = template_mod.FormatterSet;
pub const ThreadMode = progress_bar.ThreadMode;
pub const Status = progress_bar.Status;
pub const FinishConfig = progress_bar.FinishConfig;
pub const Callback = progress_bar.Callback;
pub const InitError = template_mod.InitError;

pub const IndeterminateStyle = struct {
    filled: []const u8 = ".",
    head: []const u8 = ">",
    left_bracket: []const u8 = "[",
    right_bracket: []const u8 = "]",
};

pub const IndeterminateConfig = struct {
    segment_width: u32 = 10,
    width: u32 = 40,
    style: IndeterminateStyle = .{},
    template: []const u8 = "{bar}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,
    text_style: FontStyle = .{},
    formatters: Formatters = .{},
    interval_ms: u32 = 80,
    thread_mode: ThreadMode = .none,
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const IndeterminateState = struct {
    position: u32,
    elapsed_ns: u64,
    status: Status,
};

const Direction = enum { forward, backward };

pub const Indeterminate = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: IndeterminateConfig,
    position: u32,
    direction: Direction,
    status_state: Status,
    start_time: std.Io.Timestamp,
    elapsed_ns: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),
    draw_on_update: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: IndeterminateConfig) InitError!Indeterminate {
        try template_mod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .position = 0,
            .direction = .forward,
            .status_state = .pending,
            .start_time = .zero,
            .elapsed_ns = 0,
            .mutex = .init,
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
            .draw_on_update = true,
        };
    }

    pub fn deinit(self: *Indeterminate) void {
        self.stopRenderThread();
    }

    pub fn start(self: *Indeterminate) !void {
        self.lock();
        defer self.unlock();
        if (self.status_state != .pending) return;
        self.status_state = .running;
        self.start_time = std.Io.Timestamp.now(self.io, .awake);
        self.maybeRedraw();
        if (self.config.thread_mode == .auto) {
            self.stop_thread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    pub fn tickFrame(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.status_state != .running) return;
        if (self.direction == .forward) {
            self.position += 1;
            if (self.position >= self.config.width - 1) {
                self.direction = .backward;
            }
        } else {
            if (self.position == 0) {
                self.direction = .forward;
                self.position += 1;
            } else {
                self.position -= 1;
            }
        }
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.on_tick) |cb| cb(self.config.ctx);
    }

    pub fn forceRedraw(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.draw_on_update) self.locklessRedraw();
    }

    pub fn pause(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .running) {
            self.updateElapsed();
            self.status_state = .paused;
        }
    }

    pub fn continue_(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .paused) {
            self.status_state = .running;
            self.start_time = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsed_ns) });
            self.maybeRedraw();
        }
    }

    pub fn stop(self: *Indeterminate, config: FinishConfig) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.status_state == .finished or self.status_state == .failed) return;
        self.status_state = .finished;
        self.updateElapsed();
        if (self.config.on_finish) |cb| cb(self.config.ctx);
        if (self.draw_on_update) {
            if (config.clear) {
                terminal.eraseLine(self.io);
            } else if (config.final_text) |ft| {
                terminal.eraseLine(self.io);
                var writer = terminal.stdoutWriter(self.io);
                writer.writeAll(ft) catch {};
                if (config.newline) writer.writeAll("\n") catch {};
            } else {
                if (config.newline) {
                    var writer = terminal.stdoutWriter(self.io);
                    writer.writeAll("\n") catch {};
                }
            }
        }
    }

    pub fn fail(self: *Indeterminate, message: []const u8) void {
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

    pub fn setText(self: *Indeterminate, text: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.text = text;
        self.maybeRedraw();
    }

    pub fn setColor(self: *Indeterminate, color: ?[]const u8) void {
        self.lock();
        defer self.unlock();
        self.config.color = color;
        self.maybeRedraw();
    }

    pub fn setTemplate(self: *Indeterminate, template: []const u8) !void {
        try template_mod.validate(template, self.config.formatters);
        self.lock();
        defer self.unlock();
        self.config.template = template;
        self.maybeRedraw();
    }

    pub fn state(self: *Indeterminate) IndeterminateState {
        self.lock();
        defer self.unlock();
        return .{
            .position = self.position,
            .elapsed_ns = self.elapsed_ns,
            .status = self.status_state,
        };
    }

    pub fn getStatus(self: *Indeterminate) Status {
        self.lock();
        defer self.unlock();
        return self.status_state;
    }

    pub fn setDrawOnUpdate(self: *Indeterminate, draw: bool) void {
        self.draw_on_update = draw;
    }

    pub fn redrawLine(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        self.locklessRedraw();
    }

    /// Marks the bar finished without drawing. Used by MultiBar.
    pub fn finishNow(self: *Indeterminate) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.status_state == .finished or self.status_state == .failed) return;
        self.status_state = .finished;
        self.updateElapsed();
        if (self.config.on_finish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *Indeterminate) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *Indeterminate) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *Indeterminate) void {
        if (self.draw_on_update and self.status_state == .running) {
            self.locklessRedraw();
        }
    }

    fn renderLoop(self: *Indeterminate) void {
        while (!self.stop_thread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.interval_ms);
            self.tickFrame();
        }
    }

    fn stopRenderThread(self: *Indeterminate) void {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *Indeterminate) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.start_time.nanoseconds;
        self.elapsed_ns = @intCast(@max(diff, 0));
    }

    fn locklessRedraw(self: *Indeterminate) void {
        var writer = terminal.stdoutWriter(self.io);

        const width = self.config.width;

        var bar_buf: [2048]u8 = undefined;
        var bar_acc = template_mod.Accum.init(&bar_buf);
        const style = self.config.style;
        bar_acc.write(style.left_bracket) catch return;
        var j: u32 = 0;
        while (j < width) : (j += 1) {
            if (j == self.position) {
                bar_acc.write(style.head) catch return;
            } else {
                bar_acc.write(style.filled) catch return;
            }
        }
        bar_acc.write(style.right_bracket) catch return;

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = template_mod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .bar = bar_acc.get(),
            .elapsed_ns = self.elapsed_ns,
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
};