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

pub const SpinnerConfig = struct {
    frames: []const []const u8,
    template: []const u8 = "{frame} {text}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,
    text_style: FontStyle = .{},
    formatters: Formatters = .{},
    interval_ms: u32 = 80,
    thread_mode: ThreadMode = .none,
    show_spinner: bool = true,
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const SpinnerState = struct {
    frame_index: u64,
    frame: []const u8,
    elapsed_ns: u64,
    status: Status,
};

pub const Spinner = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: SpinnerConfig,
    index: u64,
    status_state: Status,
    start_time: std.Io.Timestamp,
    elapsed_ns: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),
    draw_on_update: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: SpinnerConfig) InitError!Spinner {
        try template_mod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .index = 0,
            .status_state = .pending,
            .start_time = .zero,
            .elapsed_ns = 0,
            .mutex = .init,
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
            .draw_on_update = true,
        };
    }

    pub fn deinit(self: *Spinner) void {
        self.stopRenderThread();
    }

    pub fn start(self: *Spinner) !void {
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

    pub fn tickFrame(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.status_state != .running) return;
        self.index += 1;
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.on_tick) |cb| cb(self.config.ctx);
    }

    pub fn setProgress(self: *Spinner, value: u64) void {
        self.lock();
        defer self.unlock();
        if (self.status_state != .running) return;
        self.index = value;
        self.updateElapsed();
        self.maybeRedraw();
    }

    pub fn getCurrent(self: *Spinner) u64 {
        self.lock();
        defer self.unlock();
        return self.index;
    }

    pub fn forceRedraw(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.draw_on_update) self.locklessRedraw();
    }

    pub fn pause(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .running) {
            self.updateElapsed();
            self.status_state = .paused;
        }
    }

    pub fn continue_(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.status_state == .paused) {
            self.status_state = .running;
            self.start_time = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsed_ns) });
            self.maybeRedraw();
        }
    }

    pub fn stop(self: *Spinner, config: FinishConfig) void {
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

    pub fn fail(self: *Spinner, message: []const u8) void {
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

    pub fn setText(self: *Spinner, text: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.text = text;
    }

    pub fn setColor(self: *Spinner, color: ?[]const u8) void {
        self.lock();
        defer self.unlock();
        self.config.color = color;
    }

    pub fn setFrames(self: *Spinner, frames: []const []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.frames = frames;
    }

    pub fn setTemplate(self: *Spinner, template: []const u8) !void {
        try template_mod.validate(template, self.config.formatters);
        self.lock();
        defer self.unlock();
        self.config.template = template;
    }

    pub fn state(self: *Spinner) SpinnerState {
        self.lock();
        defer self.unlock();
        const frame = self.config.frames[self.index % self.config.frames.len];
        return .{
            .frame_index = self.index,
            .frame = frame,
            .elapsed_ns = self.elapsed_ns,
            .status = self.status_state,
        };
    }

    pub fn getStatus(self: *Spinner) Status {
        self.lock();
        defer self.unlock();
        return self.status_state;
    }

    pub fn setDrawOnUpdate(self: *Spinner, draw: bool) void {
        self.draw_on_update = draw;
    }

    pub fn redrawLine(self: *Spinner) void {
        self.locklessRedraw();
    }

    /// Marks the spinner finished without drawing. Used by MultiBar and StepSequence.
    pub fn finishNow(self: *Spinner) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.status_state == .finished or self.status_state == .failed) return;
        self.status_state = .finished;
        self.updateElapsed();
        if (self.config.on_finish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *Spinner) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *Spinner) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *Spinner) void {
        if (self.draw_on_update and self.status_state == .running) {
            self.locklessRedraw();
        }
    }

    fn renderLoop(self: *Spinner) void {
        while (!self.stop_thread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.interval_ms);
            self.tickFrame();
        }
    }

    fn stopRenderThread(self: *Spinner) void {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *Spinner) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.start_time.nanoseconds;
        self.elapsed_ns = @intCast(@max(diff, 0));
    }

    fn locklessRedraw(self: *Spinner) void {
        var writer = terminal.stdoutWriter(self.io);

        const frame = self.config.frames[self.index % self.config.frames.len];

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = template_mod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .frame = if (self.config.show_spinner) frame else "",
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

test "spinner advances frames" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const config = SpinnerConfig{ .frames = &.{ "|", "/", "-", "\\" } };
    var sp = try Spinner.init(std.testing.allocator, io, config);
    defer sp.deinit();
    sp.setDrawOnUpdate(false);
    try sp.start();
    const s0 = sp.state();
    try std.testing.expectEqualStrings("|", s0.frame);
    sp.tickFrame();
    const s1 = sp.state();
    try std.testing.expectEqualStrings("/", s1.frame);
    try std.testing.expectEqual(Status.running, sp.getStatus());
}