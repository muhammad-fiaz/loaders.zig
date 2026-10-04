const std = @import("std");
const tint = @import("tint");
const templateMod = @import("template.zig");
const styleMod = @import("style.zig");
const terminal = @import("terminal.zig");
const progressBar = @import("progress_bar.zig");

pub const FontStyle = styleMod.FontStyle;
pub const Formatters = templateMod.FormatterSet;
pub const ThreadMode = progressBar.ThreadMode;
pub const Status = progressBar.Status;
pub const FinishConfig = progressBar.FinishConfig;
pub const Callback = progressBar.Callback;
pub const InitError = templateMod.InitError;

pub const SpinnerConfig = struct {
    frames: []const []const u8,
    template: []const u8 = "{frame} {text}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?tint.ansi.Sequence = null,
    textStyle: FontStyle = .{},
    formatters: Formatters = .{},
    intervalMs: u32 = 80,
    threadMode: ThreadMode = .none,
    showSpinner: bool = true,
    onTick: ?Callback = null,
    onFinish: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const SpinnerState = struct {
    frameIndex: u64,
    frame: []const u8,
    elapsedNs: u64,
    status: Status,
};

pub const Spinner = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: SpinnerConfig,
    index: u64,
    statusState: Status,
    startTime: std.Io.Timestamp,
    elapsedNs: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stopThread: std.atomic.Value(bool),
    drawOnUpdate: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: SpinnerConfig) InitError!Spinner {
        try templateMod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .index = 0,
            .statusState = .pending,
            .startTime = .zero,
            .elapsedNs = 0,
            .mutex = .init,
            .thread = null,
            .stopThread = std.atomic.Value(bool).init(false),
            .drawOnUpdate = true,
        };
    }

    pub fn deinit(self: *Spinner) void {
        self.stopRenderThread();
    }

    pub fn start(self: *Spinner) !void {
        self.lock();
        defer self.unlock();
        if (self.statusState != .pending) return;
        self.statusState = .running;
        self.startTime = std.Io.Timestamp.now(self.io, .awake);
        self.maybeRedraw();
        if (self.config.threadMode == .auto) {
            self.stopThread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    pub fn tickFrame(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.statusState != .running) return;
        self.index += 1;
        self.updateElapsed();
        self.maybeRedraw();
        if (self.config.onTick) |cb| cb(self.config.ctx);
    }

    pub fn setProgress(self: *Spinner, value: u64) void {
        self.lock();
        defer self.unlock();
        if (self.statusState != .running) return;
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
        if (self.drawOnUpdate) self.locklessRedraw();
    }

    pub fn pause(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .running) {
            self.updateElapsed();
            self.statusState = .paused;
        }
    }

    pub fn unpause(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .paused) {
            self.statusState = .running;
            self.startTime = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsedNs) });
            self.maybeRedraw();
        }
    }

    pub fn stop(self: *Spinner, config: FinishConfig) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .finished;
        self.updateElapsed();
        if (self.config.onFinish) |cb| cb(self.config.ctx);
        if (self.drawOnUpdate) {
            if (config.clear) {
                terminal.eraseLine(self.io);
            } else if (config.finalText) |ft| {
                terminal.eraseLine(self.io);
                const writer = terminal.stdoutWriter(self.io);
                writer.writeAll(ft) catch {};
                if (config.newline) writer.writeAll("\n") catch {};
            } else {
                if (config.newline) {
                    const writer = terminal.stdoutWriter(self.io);
                    writer.writeAll("\n") catch {};
                }
            }
        }
    }

    pub fn fail(self: *Spinner, message: []const u8) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .failed;
        if (self.config.onFinish) |cb| cb(self.config.ctx);
        if (self.drawOnUpdate) {
            terminal.eraseLine(self.io);
            const writer = terminal.stdoutWriter(self.io);
            writer.writeAll(tint.color.ansi4.red.fg().slice()) catch {};
            writer.writeAll("FAILED: ") catch {};
            writer.writeAll(message) catch {};
            writer.writeAll(tint.ansi.reset.all) catch {};
            writer.writeAll("\n") catch {};
            writer.flush() catch {};
        }
    }

    pub fn setText(self: *Spinner, text: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.text = text;
    }

    pub fn setColor(self: *Spinner, color: ?tint.ansi.Sequence) void {
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
        try templateMod.validate(template, self.config.formatters);
        self.lock();
        defer self.unlock();
        self.config.template = template;
    }

    pub fn state(self: *Spinner) SpinnerState {
        self.lock();
        defer self.unlock();
        if (self.config.frames.len == 0) {
            return .{
                .frameIndex = self.index,
                .frame = "",
                .elapsedNs = self.elapsedNs,
                .status = self.statusState,
            };
        }
        const frame = self.config.frames[self.index % self.config.frames.len];
        return .{
            .frameIndex = self.index,
            .frame = frame,
            .elapsedNs = self.elapsedNs,
            .status = self.statusState,
        };
    }

    pub fn getStatus(self: *Spinner) Status {
        self.lock();
        defer self.unlock();
        return self.statusState;
    }

    pub fn setDrawOnUpdate(self: *Spinner, draw: bool) void {
        self.drawOnUpdate = draw;
    }

    pub fn redrawLine(self: *Spinner) void {
        self.lock();
        defer self.unlock();
        self.locklessRedraw();
    }

    /// Marks the spinner finished without drawing. Used by MultiBar and StepSequence.
    pub fn finishNow(self: *Spinner) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .finished;
        self.updateElapsed();
        if (self.config.onFinish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *Spinner) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *Spinner) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *Spinner) void {
        if (self.drawOnUpdate and self.statusState == .running) {
            self.locklessRedraw();
        }
    }

    fn renderLoop(self: *Spinner) void {
        while (!self.stopThread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.intervalMs);
            self.tickFrame();
        }
    }

    fn stopRenderThread(self: *Spinner) void {
        self.stopThread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *Spinner) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.startTime.nanoseconds;
        self.elapsedNs = @intCast(@max(diff, 0));
    }

    fn locklessRedraw(self: *Spinner) void {
        const writer = terminal.stdoutWriter(self.io);

        if (self.config.frames.len == 0) return;
        const frame = self.config.frames[self.index % self.config.frames.len];

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = templateMod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .frame = if (self.config.showSpinner) frame else "",
            .elapsedNs = self.elapsedNs,
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
        if (self.config.color != null) writer.writeAll(tint.ansi.reset.all) catch {};
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

test "spinner handles empty frames without crashing" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const config = SpinnerConfig{ .frames = &.{} };
    var sp = try Spinner.init(std.testing.allocator, io, config);
    defer sp.deinit();
    sp.setDrawOnUpdate(false);
    try sp.start();
    const s = sp.state();
    try std.testing.expectEqualStrings("", s.frame);
    sp.tickFrame();
    sp.forceRedraw();
    try std.testing.expectEqual(Status.running, sp.getStatus());
}
