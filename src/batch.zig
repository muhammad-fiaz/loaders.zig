const std = @import("std");
const progress_bar = @import("progress_bar.zig");
const terminal = @import("terminal.zig");

pub const ProgressBar = progress_bar.ProgressBar;

pub const Mode = enum {
    sequential,
    parallel,
};

pub const BatchConfig = struct {
    mode: Mode = .sequential,
    show_overall_bar: bool = true,
    overall_bar_config: ?progress_bar.ProgressBarConfig = null,
    per_item_bar_config: ?progress_bar.ProgressBarConfig = null,
    max_workers: u32 = 4,
    interval_ms: u32 = 30,
    ctx: ?*anyopaque = null,
};

pub const BatchRunner = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: BatchConfig,
    overall_bar: ?*ProgressBar,
    item_bar: ?*ProgressBar,
    mutex: std.Io.Mutex,
    next_index: std.atomic.Value(usize),
    completed: std.atomic.Value(u64),
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),
    started: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: BatchConfig) !BatchRunner {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .overall_bar = null,
            .item_bar = null,
            .mutex = .init,
            .next_index = std.atomic.Value(usize).init(0),
            .completed = std.atomic.Value(u64).init(0),
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
            .started = false,
        };
    }

    pub fn itemBar(self: *BatchRunner) ?*ProgressBar {
        return self.item_bar;
    }

    pub fn overallBar(self: *BatchRunner) ?*ProgressBar {
        return self.overall_bar;
    }

    pub fn deinit(self: *BatchRunner) void {
        self.stopRenderThread();
        if (self.overall_bar) |bar| {
            bar.deinit();
            self.allocator.destroy(bar);
        }
        if (self.item_bar) |bar| {
            bar.deinit();
            self.allocator.destroy(bar);
        }
    }

    pub fn run(self: *BatchRunner, comptime Item: type, items: []const Item, worker: *const fn (Item, ?*anyopaque) void) !void {
        if (self.config.show_overall_bar and self.overall_bar == null) {
            const default_cfg: progress_bar.ProgressBarConfig = .{ .total = items.len };
            var cfg = self.config.overall_bar_config orelse default_cfg;
            cfg.total = items.len;
            const bar_ptr = try self.allocator.create(ProgressBar);
            errdefer self.allocator.destroy(bar_ptr);
            bar_ptr.* = try ProgressBar.init(self.allocator, self.io, cfg);
            bar_ptr.setDrawOnUpdate(false);
            self.overall_bar = bar_ptr;
        }
        if (self.config.per_item_bar_config) |cfg| {
            if (self.item_bar == null) {
                var c = cfg;
                c.total = 1;
                const bar_ptr = try self.allocator.create(ProgressBar);
                errdefer self.allocator.destroy(bar_ptr);
                bar_ptr.* = try ProgressBar.init(self.allocator, self.io, c);
                bar_ptr.setDrawOnUpdate(false);
                self.item_bar = bar_ptr;
            }
        }

        if (self.overall_bar) |bar| bar.start() catch {};
        if (self.item_bar) |bar| bar.start() catch {};

        self.stop_thread.store(false, .release);
        self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;

        self.next_index.store(0, .release);
        self.completed.store(0, .release);

        switch (self.config.mode) {
            .sequential => {
                for (items) |item| {
                    if (self.item_bar) |bar| bar.setProgress(0);
                    worker(item, self.config.ctx);
                    _ = self.completed.fetchAdd(1, .acq_rel);
                    if (self.item_bar) |bar| bar.setProgress(1);
                    self.updateBars();
                }
            },
            .parallel => {
                const n_workers: usize = @intCast(@min(
                    self.config.max_workers,
                    @max(@as(u32, 1), @as(u32, @intCast(items.len))),
                ));
                const Loop = struct {
                    fn run(r: *BatchRunner, wi: []const Item, w: *const fn (Item, ?*anyopaque) void) void {
                        while (true) {
                            const idx = r.next_index.fetchAdd(1, .acq_rel);
                            if (idx >= wi.len) return;
                            if (r.item_bar) |bar| bar.setProgress(0);
                            w(wi[idx], r.config.ctx);
                            _ = r.completed.fetchAdd(1, .acq_rel);
                            r.updateBars();
                        }
                    }
                };
                var threads = try self.allocator.alloc(std.Thread, n_workers);
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
        if (self.overall_bar) |bar| bar.finishNow();
        if (self.item_bar) |bar| bar.finishNow();
        if (self.started) {
            const n: u16 = if (self.overall_bar != null and self.item_bar != null) 2 else 1;
            terminal.moveUp(self.io, n);
        }
        if (self.overall_bar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        if (self.item_bar) |bar| {
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
        if (self.overall_bar) |bar| bar.setProgress(done);
    }

    fn renderLoop(self: *BatchRunner) void {
        while (!self.stop_thread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.interval_ms);
            self.redrawAll();
        }
    }

    fn redrawAll(self: *BatchRunner) void {
        self.lock();
        defer self.unlock();
        if (self.overall_bar == null and self.item_bar == null) return;
        const n: u16 = if (self.overall_bar != null and self.item_bar != null) 2 else 1;
        if (self.started) terminal.moveUp(self.io, n);
        if (self.overall_bar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        if (self.item_bar) |bar| {
            bar.redrawLine();
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        var writer = terminal.stdoutWriter(self.io);
        writer.flush() catch {};
        self.started = true;
    }

    fn stopRenderThread(self: *BatchRunner) void {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }
};
