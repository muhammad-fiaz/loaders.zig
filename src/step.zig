const std = @import("std");
const tint = @import("tint");
const progressBar = @import("progress_bar.zig");
const spinnerMod = @import("spinner.zig");
const terminal = @import("terminal.zig");

pub const StepStatus = enum {
    pending,
    running,
    completed,
    failed,
    skipped,
};

pub const StepKind = union(enum) {
    spinner: spinnerMod.SpinnerConfig,
    bar: progressBar.ProgressBarConfig,
};

pub const StepConfig = struct {
    name: []const u8,
    kind: StepKind,
};

pub const Widget = union(enum) {
    spinner: *spinnerMod.Spinner,
    bar: *progressBar.ProgressBar,
};

pub const Step = struct {
    name: []const u8,
    kind: StepKind,
    status: StepStatus = .pending,
    widget: Widget,
};

pub const StepSequenceConfig = struct {
    intervalMs: u32 = 60,
};

pub const StepSequence = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    config: StepSequenceConfig,
    steps: std.ArrayListUnmanaged(Step),
    currentStep: ?usize,
    mutex: std.Io.Mutex,
    thread: ?std.Thread,
    stopThread: std.atomic.Value(bool),

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: StepSequenceConfig) !StepSequence {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .steps = .empty,
            .currentStep = null,
            .mutex = .init,
            .thread = null,
            .stopThread = std.atomic.Value(bool).init(false),
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
            .spinner => |spConfig| {
                const spPtr = try self.allocator.create(spinnerMod.Spinner);
                errdefer self.allocator.destroy(spPtr);
                spPtr.* = try spinnerMod.Spinner.init(self.allocator, self.io, spConfig);
                spPtr.setDrawOnUpdate(false);
                widget = .{ .spinner = spPtr };
            },
            .bar => |barConfig| {
                const barPtr = try self.allocator.create(progressBar.ProgressBar);
                errdefer self.allocator.destroy(barPtr);
                barPtr.* = try progressBar.ProgressBar.init(self.allocator, self.io, barConfig);
                barPtr.setDrawOnUpdate(false);
                widget = .{ .bar = barPtr };
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
        self.currentStep = index;
        switch (step.widget) {
            .spinner => |sp| sp.start() catch {},
            .bar => |bar| bar.start() catch {},
        }
        self.spawnRenderThread();
    }

    pub fn completeStep(self: *StepSequence, index: usize, config: progressBar.FinishConfig) void {
        self.lock();
        var toJoin: ?std.Thread = null;
        defer if (toJoin) |t| t.join();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .running) return;
        step.status = .completed;
        switch (step.widget) {
            .spinner => |sp| sp.finishNow(),
            .bar => |bar| bar.finishNow(),
        }
        if (self.currentStep == index) {
            self.currentStep = null;
            toJoin = self.beginStopRenderThread();
        }
        terminal.eraseLine(self.io);
        const writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  ") catch {};
        writer.writeAll(tint.color.ansi4.green.fg().slice()) catch {};
        writer.writeAll("✓") catch {};
        writer.writeAll(tint.ansi.reset.all) catch {};
        writer.writeAll(" ") catch {};
        writer.writeAll(step.name) catch {};
        if (config.finalText) |ft| {
            writer.writeAll("  ") catch {};
            writer.writeAll(ft) catch {};
        }
        if (config.newline) writer.writeAll("\n") catch {};
        writer.flush() catch {};
    }

    pub fn failStep(self: *StepSequence, index: usize, message: ?[]const u8) void {
        self.lock();
        var toJoin: ?std.Thread = null;
        defer if (toJoin) |t| t.join();
        defer self.unlock();
        const step = &self.steps.items[index];
        if (step.status != .running) return;
        step.status = .failed;
        if (self.currentStep == index) {
            self.currentStep = null;
            toJoin = self.beginStopRenderThread();
        }
        terminal.eraseLine(self.io);
        const writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  ") catch {};
        writer.writeAll(tint.color.ansi4.red.fg().slice()) catch {};
        writer.writeAll("✗") catch {};
        writer.writeAll(tint.ansi.reset.all) catch {};
        writer.writeAll(" ") catch {};
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
        const writer = terminal.stdoutWriter(self.io);
        writer.writeAll("  ") catch {};
        writer.writeAll(tint.color.ansi4.yellow.fg().slice()) catch {};
        writer.writeAll("○") catch {};
        writer.writeAll(tint.ansi.reset.all) catch {};
        writer.writeAll(" ") catch {};
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

    pub fn barOf(self: *StepSequence, index: usize) *progressBar.ProgressBar {
        return switch (self.steps.items[index].widget) {
            .bar => |bar| bar,
            .spinner => unreachable,
        };
    }

    pub fn spinnerOf(self: *StepSequence, index: usize) *spinnerMod.Spinner {
        return switch (self.steps.items[index].widget) {
            .bar => unreachable,
            .spinner => |sp| sp,
        };
    }

    pub fn printSummary(self: *StepSequence) void {
        const writer = terminal.stdoutWriter(self.io);
        writer.writeAll("\n") catch {};
        for (self.steps.items) |step| {
            const seq = switch (step.status) {
                .completed => tint.color.ansi4.green.fg(),
                .failed => tint.color.ansi4.red.fg(),
                .skipped => tint.color.ansi4.yellow.fg(),
                .running => tint.color.ansi4.cyan.fg(),
                .pending => tint.color.ansi4.brightBlack.fg(),
            };
            const glyph: []const u8 = switch (step.status) {
                .completed => "✓",
                .failed => "✗",
                .skipped, .pending => "○",
                .running => "●",
            };
            writer.writeAll("  ") catch {};
            writer.writeAll(seq.slice()) catch {};
            writer.writeAll(glyph) catch {};
            writer.writeAll(tint.ansi.reset.all) catch {};
            writer.print(" {s}\n", .{step.name}) catch {};
        }
    }

    fn lock(self: *StepSequence) void {
        self.mutex.lockUncancelable(self.io);
    }

    fn unlock(self: *StepSequence) void {
        self.mutex.unlock(self.io);
    }

    fn renderLoop(self: *StepSequence) void {
        while (!self.stopThread.load(.acquire)) {
            terminal.sleepMs(self.io, self.config.intervalMs);
            self.lock();
            if (self.currentStep) |i| {
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
            self.stopThread.store(false, .release);
            self.thread = std.Thread.spawn(.{}, renderLoop, .{self}) catch null;
        }
    }

    fn beginStopRenderThread(self: *StepSequence) ?std.Thread {
        self.stopThread.store(true, .release);
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
