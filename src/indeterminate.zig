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

pub const IndeterminateStyle = struct {
    filled: []const u8 = ".",
    head: []const u8 = ">",
    leftBracket: []const u8 = "[",
    rightBracket: []const u8 = "]",
};

pub const IndeterminateConfig = struct {
    segmentWidth: u32 = 10,
    width: u32 = 40,
    style: IndeterminateStyle = .{},
    template: []const u8 = "{bar}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?tint.ansi.Sequence = null,
    textStyle: FontStyle = .{},
    formatters: Formatters = .{},
    intervalMs: u32 = 80,
    threadMode: ThreadMode = .none,
    onTick: ?Callback = null,
    onFinish: ?Callback = null,
    ctx: ?*anyopaque = null,
};

pub const IndeterminateState = struct {
    position: u32,
    elapsedNs: u64,
    status: Status,
};

const Direction = enum { forward, backward };

pub const Indeterminate = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: IndeterminateConfig,
    position: u32,
    direction: Direction,
    statusState: Status,
    startTime: std.Io.Timestamp,
    elapsedNs: u64,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stopThread: std.atomic.Value(bool),
    drawOnUpdate: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: IndeterminateConfig) InitError!Indeterminate {
        try templateMod.validate(config.template, config.formatters);
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .position = 0,
            .direction = .forward,
            .statusState = .pending,
            .startTime = .zero,
            .elapsedNs = 0,
            .mutex = .init,
            .thread = null,
            .stopThread = std.atomic.Value(bool).init(false),
            .drawOnUpdate = true,
        };
    }

    pub fn deinit(self: *Indeterminate) void {
        self.stopRenderThread();
    }

    pub fn start(self: *Indeterminate) !void {
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

    pub fn tickFrame(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.statusState != .running) return;
        if (self.config.width == 0) return;
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
        if (self.config.onTick) |cb| cb(self.config.ctx);
    }

    pub fn forceRedraw(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.drawOnUpdate) self.locklessRedraw();
    }

    pub fn pause(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .running) {
            self.updateElapsed();
            self.statusState = .paused;
        }
    }

    pub fn unpause(self: *Indeterminate) void {
        self.lock();
        defer self.unlock();
        if (self.statusState == .paused) {
            self.statusState = .running;
            self.startTime = std.Io.Timestamp.now(self.io, .awake)
                .subDuration(.{ .nanoseconds = @intCast(self.elapsedNs) });
            self.maybeRedraw();
        }
    }

    pub fn stop(self: *Indeterminate, config: FinishConfig) void {
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

    pub fn setText(self: *Indeterminate, text: []const u8) void {
        self.lock();
        defer self.unlock();
        self.config.text = text;
        self.maybeRedraw();
    }

    pub fn setColor(self: *Indeterminate, color: ?tint.ansi.Sequence) void {
        self.lock();
        defer self.unlock();
        self.config.color = color;
        self.maybeRedraw();
    }

    pub fn setTemplate(self: *Indeterminate, template: []const u8) !void {
        try templateMod.validate(template, self.config.formatters);
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
            .elapsedNs = self.elapsedNs,
            .status = self.statusState,
        };
    }

    pub fn getStatus(self: *Indeterminate) Status {
        self.lock();
        defer self.unlock();
        return self.statusState;
    }

    pub fn setDrawOnUpdate(self: *Indeterminate, draw: bool) void {
        self.drawOnUpdate = draw;
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
        if (self.statusState == .finished or self.statusState == .failed) return;
        self.statusState = .finished;
        self.updateElapsed();
        if (self.config.onFinish) |cb| cb(self.config.ctx);
    }

    fn lock(self: *Indeterminate) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *Indeterminate) void {
        self.mutex.unlock(self.io);
    }

    fn maybeRedraw(self: *Indeterminate) void {
        if (self.drawOnUpdate and self.statusState == .running) {
            self.locklessRedraw();
        }
    }

    fn renderLoop(self: *Indeterminate) void {
        while (!self.stopThread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.intervalMs);
            self.tickFrame();
        }
    }

    fn stopRenderThread(self: *Indeterminate) void {
        self.stopThread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }

    fn updateElapsed(self: *Indeterminate) void {
        const now = std.Io.Timestamp.now(self.io, .awake);
        const diff = now.nanoseconds - self.startTime.nanoseconds;
        self.elapsedNs = @intCast(@max(diff, 0));
    }

    fn locklessRedraw(self: *Indeterminate) void {
        var writer = terminal.stdoutWriter(self.io);

        const width = self.config.width;

        var barBuf: [2048]u8 = undefined;
        var barAcc = templateMod.Accum.init(&barBuf);
        const style = self.config.style;
        barAcc.write(style.leftBracket) catch return;
        var j: u32 = 0;
        while (j < width) : (j += 1) {
            if (j == self.position) {
                barAcc.write(style.head) catch return;
            } else {
                barAcc.write(style.filled) catch return;
            }
        }
        barAcc.write(style.rightBracket) catch return;

        var buf: [4096]u8 = undefined;
        var scratch: [64]u8 = undefined;
        const values = templateMod.Values{
            .prefix = self.config.prefix,
            .suffix = self.config.suffix,
            .text = self.config.text,
            .bar = barAcc.get(),
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

test "indeterminate handles zero width without crashing" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    var ind = try Indeterminate.init(std.testing.allocator, io, .{ .width = 0 });
    defer ind.deinit();
    ind.setDrawOnUpdate(false);
    try ind.start();
    ind.tickFrame();
    ind.forceRedraw();
    try std.testing.expectEqual(Status.running, ind.getStatus());
}
