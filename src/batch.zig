const std = @import("std");
const progressBar = @import("progress_bar.zig");
const terminal = @import("terminal.zig");

pub const ProgressBar = progressBar.ProgressBar;

pub const Mode = enum {
    sequential,
    parallel,
};

pub const BatchConfig = struct {
    mode: Mode = .sequential,
    showOverallBar: bool = true,
    overallBarConfig: ?progressBar.ProgressBarConfig = null,
    perItemBarConfig: ?progressBar.ProgressBarConfig = null,
    maxWorkers: u32 = 4,
    intervalMs: u32 = 30,
    ctx: ?*anyopaque = null,
};

pub const BatchRunner = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: BatchConfig,
    overallBar: ?*ProgressBar,
    itemBar: ?*ProgressBar,
    mutex: std.Io.Mutex,
    nextIndex: std.atomic.Value(usize),
    completed: std.atomic.Value(u64),
    thread: ?std.Thread,
    stopThread: std.atomic.Value(bool),
    started: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: BatchConfig) !BatchRunner {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .overallBar = null,
            .itemBar = null,
            .mutex = .init,
            .nextIndex = std.atomic.Value(usize).init(0),
            .completed = std.atomic.Value(u64).init(0),
            .thread = null,
            .stopThread = std.atomic.Value(bool).init(false),
            .started = false,
        };
    }

    pub fn getItemBar(self: *BatchRunner) ?*ProgressBar {
        return self.itemBar;
    }

    pub fn getOverallBar(self: *BatchRunner) ?*ProgressBar {
        return self.overallBar;
    }

    pub fn deinit(self: *BatchRunner) void {
        self.stopRenderThread();
        if (self.overallBar) |bar| {
            bar.deinit();
            self.allocator.destroy(bar);
        }
        if (self.itemBar) |bar| {
            bar.deinit();
            self.allocator.destroy(bar);
        }
    }

    pub fn run(self: *BatchRunner, comptime Item: type, items: []const Item, worker: *const fn (Item, ?*anyopaque) void) !void {
        if (self.config.showOverallBar and self.overallBar == null) {
            const defaultCfg: progressBar.ProgressBarConfig = .{ .total = items.len };
            var cfg = self.config.overallBarConfig orelse defaultCfg;
            cfg.total = items.len;
            const barPtr = try self.allocator.create(ProgressBar);
            errdefer self.allocator.destroy(barPtr);
            barPtr.* = try ProgressBar.init(self.allocator, self.io, cfg);
            barPtr.setDrawOnUpdate(false);
            self.overallBar = barPtr;
        }
        if (self.config.perItemBarConfig) |cfg| {
            if (self.itemBar == null) {
                var c = cfg;
                c.total = 1;
                const barPtr = try self.allocator.create(ProgressBar);
                errdefer self.allocator.destroy(barPtr);
                barPtr.* = try ProgressBar.init(self.allocator, self.io, c);
                barPtr.setDrawOnUpdate(false);
                self.itemBar = barPtr;
            }
        }

        if (self.overallBar) |bar| bar.start() catch {};
        if (self.itemBar) |bar| bar.start() catch {};

        self.stopThread.store(false, .release);
        self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;

        self.nextIndex.store(0, .release);
        self.completed.store(0, .release);

        switch (self.config.mode) {
            .sequential => {
                for (items) |item| {
                    if (self.itemBar) |bar| bar.setProgress(0);
                    worker(item, self.config.ctx);
                    _ = self.completed.fetchAdd(1, .acq_rel);
                    if (self.itemBar) |bar| bar.setProgress(1);
                    self.updateBars();
                }
            },
            .parallel => {
                const nWorkers: usize = @intCast(@min(
                    self.config.maxWorkers,
                    @max(@as(u32, 1), @as(u32, @intCast(items.len))),
                ));
                const Loop = struct {
                    fn run(r: *BatchRunner, wi: []const Item, w: *const fn (Item, ?*anyopaque) void) void {
                        while (true) {
                            const idx = r.nextIndex.fetchAdd(1, .acq_rel);
                            if (idx >= wi.len) return;
                            if (r.itemBar) |bar| bar.setProgress(0);
                            w(wi[idx], r.config.ctx);
                            _ = r.completed.fetchAdd(1, .acq_rel);
                            r.updateBars();
                        }
                    }
                };
                var threads = try self.allocator.alloc(std.Thread, nWorkers);
                defer self.allocator.free(threads);
                var spawned: usize = 0;
                errdefer {
                    for (threads[0..spawned]) |t| t.join();
                }
                for (threads) |*t| {
                    t.* = try std.Thread.spawn(.{}, Loop.run, .{ self, items, worker });
                    spawned += 1;
                }
                for (threads) |t| t.join();
            },
        }

        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        if (self.overallBar) |bar| bar.finishNow();
        if (self.itemBar) |bar| bar.finishNow();
        if (self.started) {
            const n: u16 = if (self.overallBar != null and self.itemBar != null) 2 else 1;
            terminal.moveUp(self.io, n);
        }
        if (self.overallBar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        if (self.itemBar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        var writer = terminal.stdoutWriter(self.io);
        writer.flush() catch {};
    }

    fn lock(self: *BatchRunner) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *BatchRunner) void {
        self.mutex.unlock(self.io);
    }

    fn updateBars(self: *BatchRunner) void {
        self.lock();
        defer self.unlock();
        const done = self.completed.load(.acquire);
        if (self.overallBar) |bar| bar.setProgress(done);
    }

    fn renderLoop(self: *BatchRunner) void {
        while (!self.stopThread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.intervalMs);
            self.redrawAll();
        }
    }

    fn redrawAll(self: *BatchRunner) void {
        self.lock();
        defer self.unlock();
        if (self.overallBar == null and self.itemBar == null) return;
        const n: u16 = if (self.overallBar != null and self.itemBar != null) 2 else 1;
        if (self.started) terminal.moveUp(self.io, n);
        if (self.overallBar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        if (self.itemBar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        var writer = terminal.stdoutWriter(self.io);
        writer.flush() catch {};
        self.started = true;
    }

    fn stopRenderThread(self: *BatchRunner) void {
        self.stopThread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }
};
