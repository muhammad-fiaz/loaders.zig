const std = @import("std");
const progress_bar = @import("progress_bar.zig");
const spinner_mod = @import("spinner.zig");
const terminal = @import("terminal.zig");

pub const StepStatus = enum {
    pending,
    running,
    completed,
    failed,
    skipped,
};

pub const StepKind = union(enum) {
    spinner: spinner_mod.SpinnerConfig,
    bar: progress_bar.ProgressBarConfig,
};

pub const StepConfig = struct {
    name: []const u8,
    kind: StepKind,
};

pub const Widget = union(enum) {
    spinner: *spinner_mod.Spinner,
    bar: *progress_bar.ProgressBar,
};

pub const Step = struct {
    name: []const u8,
    kind: StepKind,
    status: StepStatus = .pending,
    widget: Widget,
};

pub const StepSequenceConfig = struct {
    interval_ms: u32 = 60,
};

pub const StepSequence = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: StepSequenceConfig,
    steps: std.ArrayListUnmanaged(Step),
    current_step: ?usize,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stop_thread: std.atomic.Value(bool),

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: StepSequenceConfig) !StepSequence {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .steps = .empty,
            .current_step = null,
            .mutex = .init,
            .thread = null,
            .stop_thread = std.atomic.Value(bool).init(false),
        };
    }

    pub fn deinit(self: *StepSequence) void {
        self.stopRenderThread();
        for (self.steps.items) |step| {
            switch (step.widget) {
                .spinner => |sp| {
                    sp.deinit();
                    self.allocator.destroy(sp);
                },
                .bar => |bar| {
                    bar.deinit();
                    self.allocator.destroy(bar);
                },
            }
        }
        self.steps.deinit(self.allocator);
    }

    pub fn addStep(self: *StepSequence, config: StepConfig) !usize {
        var widget: Widget = undefined;
        switch (config.kind) {
            .spinner => |sp_config| {
                const sp_ptr = try self.allocator.create(spinner_mod.Spinner);
                errdefer self.allocator.destroy(sp_ptr);
                sp_ptr.* = try spinner_mod.Spinner.init(self.allocator, self.io, sp_config);
                sp_ptr.setDrawOnUpdate(false);
                widget = .{ .spinner = sp_ptr };
            },
            .bar => |bar_config| {
                const bar_ptr = try self.allocator.create(progress_bar.ProgressBar);
                errdefer self.allocator.destroy(bar_ptr);
                bar_ptr.* = try progress_bar.ProgressBar.init(self.allocator, self.io, bar_config);
                bar_ptr.setDrawOnUpdate(false);
                widget = .{ .bar = bar_ptr };
            },
        }
        try self.steps.append(self.allocator, .{
            .name = config.name,
            .kind = config.kind,
            .widget = widget,
        });
        return self.steps.items.len - 1;
    }

    pub fn startStep(self: *StepSequence, index: usize) !void {
        self.lock();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .pending) return;
        step.status = .running;
        self.current_step = index;
        switch (step.widget) {
            .spinner => |sp| sp.start() catch {},
            .bar => |bar| bar.start() catch {},
        }
        self.spawnRenderThread();
    }

    pub fn completeStep(self: *StepSequence, index: usize, config: progress_bar.FinishConfig) void {
        self.lock();
        var to_join: ?std.Thread = null;
        defer if (to_join) |t| t.join();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .running) return;
        step.status = .completed;
        switch (step.widget) {
            .spinner => |sp| sp.finishNow(),
            .bar => |bar| bar.finishNow(),
        }
        if (self.current_step == index) {
            self.current_step = null;
            to_join = self.beginStopRenderThread();
        }
        terminal.eraseLine(self.io);
        var writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  \x1b[32m\u{2713}\x1b[0m ") catch {};
        writer.writeAll(step.name) catch {};
        if (config.final_text) |ft| {
            writer.writeAll("  ") catch {};
            writer.writeAll(ft) catch {};
        }
        if (config.newline) writer.writeAll("\n") catch {};
        writer.flush() catch {};
    }

    pub fn failStep(self: *StepSequence, index: usize, message: ?[]const u8) void {
        self.lock();
        var to_join: ?std.Thread = null;
        defer if (to_join) |t| t.join();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .running) return;
        step.status = .failed;
        if (self.current_step == index) {
            self.current_step = null;
            to_join = self.beginStopRenderThread();
        }
        terminal.eraseLine(self.io);
        var writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  \x1b[31m\u{2717}\x1b[0m ") catch {};
        writer.writeAll(step.name) catch {};
        if (message) |m| {
            writer.writeAll("  ") catch {};
            writer.writeAll(m) catch {};
        }
        writer.writeAll("\n") catch {};
        writer.flush() catch {};
    }

    pub fn skipStep(self: *StepSequence, index: usize) void {
        self.lock();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .pending) return;
        step.status = .skipped;
        terminal.eraseLine(self.io);
        var writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  \x1b[33m\u{25CB}\x1b[0m ") catch {};
        writer.writeAll(step.name) catch {};
        writer.writeAll("\n") catch {};
        writer.flush() catch {};
    }

    pub fn runAll(self: *StepSequence, context: ?*anyopaque, runner: *const fn (?*anyopaque, []const u8) void) void {
        var i: usize = 0;
        while (i < self.steps.items.len) : (i += 1) {
            if (self.steps.items[i].status != .pending) continue;
            self.startStep(i) catch continue;
            runner(context, self.steps.items[i].name);
            if (self.steps.items[i].status == .running) {
                self.completeStep(i, .{});
            }
        }
        self.stopRenderThread();
    }

    pub fn statusOf(self: *StepSequence, index: usize) StepStatus {
        return self.steps.items[index].status;
    }

    pub fn barOf(self: *StepSequence, index: usize) *progress_bar.ProgressBar {
        return switch (self.steps.items[index].widget) {
            .bar => |bar| bar,
            .spinner => unreachable,
        };
    }

    pub fn spinnerOf(self: *StepSequence, index: usize) *spinner_mod.Spinner {
        return switch (self.steps.items[index].widget) {
            .bar => unreachable,
            .spinner => |sp| sp,
        };
    }

    pub fn printSummary(self: *StepSequence) void {
        var writer = terminal.stdoutWriter(self.io);
        writer.writeAll("\n") catch {};
        for (self.steps.items) |step| {
            const icon: []const u8 = switch (step.status) {
                .completed => "\x1b[32m\u{2713}\x1b[0m",
                .failed => "\x1b[31m\u{2717}\x1b[0m",
                .skipped => "\x1b[33m\u{25CB}\x1b[0m",
                .running => "\x1b[36m\u{25CF}\x1b[0m",
                .pending => "\x1b[90m\u{25CB}\x1b[0m",
            };
            writer.print("  {s} {s}\n", .{ icon, step.name }) catch {};
        }
    }

    fn lock(self: *StepSequence) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *StepSequence) void {
        self.mutex.unlock(self.io);
    }

    fn renderLoop(self: *StepSequence) void {
        while (!self.stop_thread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.interval_ms);
            self.lock();
            if (self.current_step) |i| {
                const step = &self.steps.items[i];
                if (step.status == .running) {
                    switch (step.widget) {
                        .spinner => |sp| {
                            sp.tickFrame();
                            sp.redrawLine();
                        },
                        .bar => |bar| bar.redrawLine(),
                    }
                }
            }
            self.unlock();
        }
    }

    fn spawnRenderThread(self: *StepSequence) void {
        if (self.thread == null) {
            self.stop_thread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    fn beginStopRenderThread(self: *StepSequence) ?std.Thread {
        self.stop_thread.store(true, .release);
        if (self.thread) |t| {
            self.thread = null;
            return t;
        }
        return null;
    }

    fn stopRenderThread(self: *StepSequence) void {
        if (self.beginStopRenderThread()) |t| {
            t.join();
        }
    }
};