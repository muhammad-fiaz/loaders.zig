const std = @import("std");
const progress_bar = @import("progress_bar.zig");
const spinner_mod = @import("spinner.zig");
const terminal = @import("terminal.zig");

pub const ProgressBar = progress_bar.ProgressBar;
pub const Spinner = spinner_mod.Spinner;
pub const FinishConfig = progress_bar.FinishConfig;

pub const Mode = enum {
    sequential,
    parallel,
};

pub const MultiBarConfig = struct {
    mode: Mode = .parallel,
    interval_ms: u32 = 30,
    hide_bar_when_complete: bool = false,
};

pub const Tracker = union(enum) {
    bar: *ProgressBar,
    spinner: *Spinner,
};

pub const MultiBar = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: MultiBarConfig,
    trackers: std.ArrayListUnmanaged(Tracker),
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),
    started: bool,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: MultiBarConfig) !MultiBar {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .trackers = .empty,
            .mutex = .init,
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
            .started = false,
        };
    }

    pub fn deinit(self: *MultiBar) void {
        self.stopRenderThread();
        for (self.trackers.items) |tracker| {
            switch (tracker) {
                .bar => |bar| {
                    bar.deinit();
                    self.allocator.destroy(bar);
                },
                .spinner => |sp| {
                    sp.deinit();
                    self.allocator.destroy(sp);
                },
            }
        }
        self.trackers.deinit(self.allocator);
    }

    pub fn addBar(self: *MultiBar, config: progress_bar.ProgressBarConfig) !usize {
        const bar_ptr = try self.allocator.create(ProgressBar);
        errdefer self.allocator.destroy(bar_ptr);
        bar_ptr.* = try ProgressBar.init(self.allocator, self.io, config);
        bar_ptr.setDrawOnUpdate(false);
        self.lock();
        defer self.unlock();
        try self.trackers.append(self.allocator, .{ .bar = bar_ptr });
        return self.trackers.items.len - 1;
    }

    pub fn addSpinner(self: *MultiBar, config: spinner_mod.SpinnerConfig) !usize {
        const sp_ptr = try self.allocator.create(Spinner);
        errdefer self.allocator.destroy(sp_ptr);
        sp_ptr.* = try Spinner.init(self.allocator, self.io, config);
        sp_ptr.setDrawOnUpdate(false);
        self.lock();
        defer self.unlock();
        try self.trackers.append(self.allocator, .{ .spinner = sp_ptr });
        return self.trackers.items.len - 1;
    }

    pub fn getBar(self: *MultiBar, index: usize) *ProgressBar {
        return switch (self.trackers.items[index]) {
            .bar => |bar| bar,
            .spinner => unreachable,
        };
    }

    pub fn getSpinner(self: *MultiBar, index: usize) *Spinner {
        return switch (self.trackers.items[index]) {
            .bar => unreachable,
            .spinner => |sp| sp,
        };
    }

    pub fn count(self: *MultiBar) usize {
        return self.trackers.items.len;
    }

    pub fn run(self: *MultiBar) !void {
        self.lock();
        defer self.unlock();
        for (self.trackers.items) |tracker| {
            switch (tracker) {
                .bar => |bar| {
                    if (bar.getStatus() == .pending) bar.start() catch {};
                },
                .spinner => |sp| {
                    if (sp.getStatus() == .pending) sp.start() catch {};
                },
            }
        }
        if (self.thread == null) {
            self.stop_thread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    pub fn finishAll(self: *MultiBar, config: FinishConfig) void {
        self.stopRenderThread();
        self.lock();
        defer self.unlock();
        for (self.trackers.items) |tracker| {
            switch (tracker) {
                .bar => |bar| bar.finishNow(),
                .spinner => |sp| sp.finishNow(),
            }
        }
        if (self.started) {
            const n = self.visibleCount();
            if (n > 0) {
                terminal.moveUp(self.io, n);
                for (self.trackers.items) |tracker| {
                    const finished = self.isTrackerFinished(tracker);
                    if (finished and self.config.hide_bar_when_complete) {
                        terminal.eraseLine(self.io);
                        var w = terminal.stdoutWriter(self.io);
                        w.writeAll("\n") catch {};
                        continue;
                    }
                    switch (tracker) {
                        .bar => |bar| bar.redrawLine(),
                        .spinner => |sp| sp.redrawLine(),
                    }
                    var w = terminal.stdoutWriter(self.io);
                    w.writeAll("\n") catch {};
                }
            }
        }
        var writer = terminal.stdoutWriter(self.io);
        if (config.final_text) |ft| {
            writer.writeAll(ft) catch {};
        }
        if (config.newline and self.trackers.items.len > 0) {
            writer.writeAll("\n") catch {};
        }
        writer.flush() catch {};
    }

    fn lock(self: *MultiBar) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *MultiBar) void {
        self.mutex.unlock(self.io);
    }

    fn renderLoop(self: *MultiBar) void {
        switch (self.config.mode) {
            .parallel => {
                while (!self.stop_thread.load(.acquire)) {
                    terminal.sleepMs(self.io, self.config.interval_ms);
                    self.redrawAll();
                }
            },
            .sequential => {
                var i: usize = 0;
                while (i < self.trackers.items.len) {
                    if (self.stop_thread.load(.acquire)) return;
                    terminal.sleepMs(self.io, self.config.interval_ms);
                    if (!self.isFinished(i)) {
                        self.redrawOne(i);
                    } else {
                        self.commitLine();
                        i += 1;
                    }
                }
            },
        }
    }

    fn redrawAll(self: *MultiBar) void {
        self.lock();
        defer self.unlock();
        const n: u16 = @intCast(self.trackers.items.len);
        if (n == 0) return;
        if (self.started) terminal.moveUp(self.io, self.visibleCount());
        for (self.trackers.items) |tracker| {
            const finished = self.isTrackerFinished(tracker);
            if (finished and self.config.hide_bar_when_complete) {
                terminal.eraseLine(self.io);
                var writer = terminal.stdoutWriter(self.io);
                writer.writeAll("\n") catch {};
                continue;
            }
            switch (tracker) {
                .bar => |bar| bar.redrawLine(),
                .spinner => |sp| sp.redrawLine(),
            }
            var writer = terminal.stdoutWriter(self.io);
            writer.writeAll("\n") catch {};
        }
        var writer = terminal.stdoutWriter(self.io);
        writer.flush() catch {};
        self.started = true;
    }

    fn visibleCount(self: *MultiBar) u16 {
        if (!self.config.hide_bar_when_complete) return @intCast(self.trackers.items.len);
        var vis: u16 = 0;
        for (self.trackers.items) |tracker| {
            if (!self.isTrackerFinished(tracker)) vis += 1;
        }
        return vis;
    }

    fn isTrackerFinished(self: *MultiBar, tracker: Tracker) bool {
        _ = self;
        return switch (tracker) {
            .bar => |bar| {
                const s = bar.getStatus();
                return s == .finished or s == .failed;
            },
            .spinner => |sp| {
                const s = sp.getStatus();
                return s == .finished or s == .failed;
            },
        };
    }

    fn redrawOne(self: *MultiBar, index: usize) void {
        self.lock();
        defer self.unlock();
        if (index >= self.trackers.items.len) return;
        switch (self.trackers.items[index]) {
            .bar => |bar| bar.redrawLine(),
            .spinner => |sp| sp.redrawLine(),
        }
    }

    fn isFinished(self: *MultiBar, index: usize) bool {
        self.lock();
        defer self.unlock();
        if (index >= self.trackers.items.len) return true;
        return switch (self.trackers.items[index]) {
            .bar => |bar| {
                const s = bar.getStatus();
                return s == .finished or s == .failed;
            },
            .spinner => |sp| {
                const s = sp.getStatus();
                return s == .finished or s == .failed;
            },
        };
    }

    fn commitLine(self: *MultiBar) void {
        var writer = terminal.stdoutWriter(self.io);
        writer.writeAll("\n") catch {};
    }

    fn stopRenderThread(self: *MultiBar) void {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            t.join();
        }
    }
};