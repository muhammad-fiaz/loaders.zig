//! batch.zig — Grouped batch progress bar for multi-task workflows.
//!
//! `BatchBar` manages a list of named tasks, each with its own completion
//! counter. It renders an overview line plus per-task bars.
//!
//! Usage:
//!
//!   var bb = BatchBar.init(io, .{ .title = "Build Pipeline" });
//!   const t1 = bb.addTask("Compile", 100);
//!   const t2 = bb.addTask("Link", 50);
//!   bb.setTaskCompleted(t1, 30);
//!   bb.render();
//!   bb.setTaskDone(t1);
//!   bb.setTaskFailed(t2);
//!   bb.done();

const std = @import("std");
const color_mod = @import("color.zig");
const style_mod = @import("style.zig");
const terminal = @import("terminal.zig");
const utils = @import("utils.zig");

pub const Color = color_mod.Color;
pub const Colorizer = color_mod.Colorizer;
pub const BarStyle = style_mod.BarStyle;

/// Maximum number of tasks in a BatchBar.
pub const max_tasks = 32;

/// State of a single batch task.
pub const TaskState = enum {
    pending,
    running,
    done,
    failed,
    warn,
    info,
};

/// A single task tracked by BatchBar.
pub const BatchTask = struct {
    name: [128:0]u8 = @splat(0),
    name_len: usize = 0,
    total: usize = 0,
    completed: std.atomic.Value(usize),
    state: TaskState = .pending,
    style: BarStyle = BarStyle.slim,
    icon: ?[]const u8 = null,
    success_icon: ?[]const u8 = null,
    failure_icon: ?[]const u8 = null,
    warning_icon: ?[]const u8 = null,
    info_icon: ?[]const u8 = null,
    color: Color = .default,
    bg_color: Color = .default,
    label_color: Color = .default,
    label_bg_color: Color = .default,
    fill_color: Color = .default,
    fill_bg_color: Color = .default,
    empty_color: Color = .default,
    empty_bg_color: Color = .default,
    /// Number of empty padding lines printed above this task line.
    padding_lines_above: usize = 0,
    /// Number of empty padding lines printed below this task line.
    padding_lines_below: usize = 0,

    pub fn getName(t: *const BatchTask) []const u8 {
        return t.name[0..t.name_len];
    }
};

/// Options for `BatchBar`.
pub const BatchOptions = struct {
    /// Title printed above all task bars.
    title: []const u8 = "",
    /// Title color.
    title_color: Color = .bright_white,
    /// Bar width for each task bar (0 = auto).
    width: u16 = 0,
    /// Default style for task bars.
    style: BarStyle = BarStyle.slim,
    /// Whether to show percentage per task.
    show_percent: bool = true,
    /// Whether to show count per task.
    show_count: bool = false,
    /// Output file (null = stderr).
    file: ?std.Io.File = null,
    /// Terminal info override.
    term: ?terminal.TermInfo = null,
    /// Color override.
    color_enabled: ?bool = null,
    /// Hide cursor during rendering.
    hide_cursor: bool = true,
    /// Optional running icon prefix.
    icon: ?[]const u8 = null,
    /// Optional custom success icon.
    success_icon: ?[]const u8 = null,
    /// Optional custom failure icon.
    failure_icon: ?[]const u8 = null,
    /// Optional custom warning icon.
    warning_icon: ?[]const u8 = null,
    /// Optional custom info icon.
    info_icon: ?[]const u8 = null,
    /// Maximum visual column width for task name (0 = no limit). Truncates if exceeded.
    max_name_width: usize = 0,
    /// Spacing gap after icons (defaults to " ").
    icon_gap: []const u8 = " ",
    /// Spacing gap after task label/name (defaults to " ").
    label_gap: []const u8 = " ",
    /// Spacing gap after task state icon (defaults to " ").
    state_gap: []const u8 = " ",
    /// Number of empty lines to print between individual tasks.
    spacing_lines: usize = 0,
};

/// A grouped multi-task progress renderer.
pub const BatchBar = struct {
    io: std.Io,
    opts: BatchOptions,
    tasks: [max_tasks]BatchTask,
    count: usize,
    colorizer: Colorizer,
    term: terminal.TermInfo,
    file: std.Io.File,
    first_render: bool,
    write_buf: [8192]u8,
    done_flag: bool,

    /// Initialize a BatchBar.
    pub fn init(io: std.Io, opts: BatchOptions) BatchBar {
        terminal.setupTerminal();
        const file = opts.file orelse std.Io.File.stderr();
        const ti = opts.term orelse terminal.query(file, io);
        const color_on = opts.color_enabled orelse ti.ansi_supported;

        return .{
            .io = io,
            .opts = opts,
            .tasks = undefined,
            .count = 0,
            .colorizer = .{
                .enabled = color_on,
                .ansi_enabled = ti.ansi_supported,
                .cr_enabled = ti.is_tty,
            },
            .term = ti,
            .file = file,
            .first_render = true,
            .write_buf = undefined,
            .done_flag = false,
        };
    }

    /// Add a task with a name and total steps. Returns its task index.
    pub fn addTask(bb: *BatchBar, name: []const u8, total: usize) usize {
        const i = bb.count;
        std.debug.assert(i < max_tasks);
        bb.tasks[i] = BatchTask{
            .total = total,
            .completed = std.atomic.Value(usize).init(0),
            .state = .pending,
            .style = bb.opts.style,
            .icon = null,
            .success_icon = null,
            .failure_icon = null,
            .warning_icon = null,
            .info_icon = null,
            .color = .default,
            .label_color = .default,
            .fill_color = .default,
            .empty_color = .default,
        };
        const len = @min(name.len, 127);
        @memcpy(bb.tasks[i].name[0..len], name[0..len]);
        bb.tasks[i].name[len] = 0;
        bb.tasks[i].name_len = len;
        bb.count += 1;
        return i;
    }

    /// Set the completed count for a task (thread-safe).
    pub fn setTaskCompleted(bb: *BatchBar, idx: usize, n: usize) void {
        std.debug.assert(idx < bb.count);
        bb.tasks[idx].completed.store(n, .release);
        if (bb.tasks[idx].state == .pending) {
            bb.tasks[idx].state = .running;
        }
    }

    /// Increment a task's completed count by 1 (thread-safe).
    pub fn incrementTask(bb: *BatchBar, idx: usize) void {
        std.debug.assert(idx < bb.count);
        _ = bb.tasks[idx].completed.fetchAdd(1, .release);
        if (bb.tasks[idx].state == .pending) {
            bb.tasks[idx].state = .running;
        }
    }

    /// Mark a task as successfully done.
    pub fn setTaskDone(bb: *BatchBar, idx: usize) void {
        std.debug.assert(idx < bb.count);
        const t = &bb.tasks[idx];
        t.completed.store(t.total, .release);
        t.state = .done;
    }

    /// Mark a task as failed.
    pub fn setTaskFailed(bb: *BatchBar, idx: usize) void {
        std.debug.assert(idx < bb.count);
        bb.tasks[idx].state = .failed;
    }

    /// Mark a task as completed with warning.
    pub fn setTaskWarning(bb: *BatchBar, idx: usize) void {
        std.debug.assert(idx < bb.count);
        bb.tasks[idx].state = .warn;
    }

    /// Mark a task as completed with info.
    pub fn setTaskInfo(bb: *BatchBar, idx: usize) void {
        std.debug.assert(idx < bb.count);
        bb.tasks[idx].state = .info;
    }

    /// Render all task bars in-place.
    pub fn render(bb: *BatchBar) void {
        bb.renderInner() catch {};
    }

    fn renderInner(bb: *BatchBar) !void {
        if (!bb.term.is_tty and !bb.done_flag) {
            return;
        }
        if (bb.term.is_tty) {
            bb.term = terminal.query(bb.file, bb.io);
        }
        var fw: std.Io.File.Writer = .init(bb.file, bb.io, &bb.write_buf);
        const w = &fw.interface;

        const title_lines: usize = if (bb.opts.title.len > 0) 1 else 0;
        var total_lines = title_lines;
        for (bb.tasks[0..bb.count]) |*t| {
            total_lines += t.padding_lines_above + 1 + t.padding_lines_below;
        }
        if (bb.count > 1) {
            total_lines += (bb.count - 1) * bb.opts.spacing_lines;
        }

        if (!bb.first_render) {
            try bb.colorizer.cursorUp(w, total_lines);
        } else if (bb.opts.hide_cursor) {
            try bb.colorizer.hideCursor(w);
        }
        bb.first_render = false;

        // Title
        if (bb.opts.title.len > 0) {
            try bb.colorizer.clearLine(w);
            try color_mod.writeColored(w, bb.colorizer, bb.opts.title, bb.opts.title_color, .default, &.{.bold});
            try w.writeByte('\n');
        }

        for (bb.tasks[0..bb.count], 0..) |*t, idx| {
            if (idx > 0) {
                var s: usize = 0;
                while (s < bb.opts.spacing_lines) : (s += 1) {
                    try bb.colorizer.clearLine(w);
                    try w.writeByte('\n');
                }
            }

            var i: usize = 0;
            while (i < t.padding_lines_above) : (i += 1) {
                if (t.bg_color != .default) {
                    try bb.colorizer.begin(w, .default, t.bg_color, &.{});
                }
                try bb.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (t.bg_color != .default) {
                    try bb.colorizer.reset(w);
                }
            }

            const state_col: color_mod.Color = switch (t.state) {
                .done => .green,
                .failed => .red,
                .warn => .yellow,
                .info => .cyan,
                else => .default,
            };

            const line_color = if (t.color != .default)
                t.color
            else if (state_col != .default)
                state_col
            else
                .default;

            if (line_color != .default or t.bg_color != .default) {
                try bb.colorizer.begin(w, line_color, t.bg_color, &.{});
            }
            try bb.colorizer.clearLine(w);
            try bb.renderTask(w, t);
            if (line_color != .default or t.bg_color != .default) {
                try bb.colorizer.reset(w);
            }
            try w.writeByte('\n');

            i = 0;
            while (i < t.padding_lines_below) : (i += 1) {
                if (t.bg_color != .default) {
                    try bb.colorizer.begin(w, .default, t.bg_color, &.{});
                }
                try bb.colorizer.clearLine(w);
                try w.writeByte('\n');
                if (t.bg_color != .default) {
                    try bb.colorizer.reset(w);
                }
            }
        }

        try fw.flush();
    }

    fn renderTask(bb: *BatchBar, w: *std.Io.Writer, t: *const BatchTask) !void {
        const completed = t.completed.load(.acquire);
        const total = t.total;
        const s = t.style;
        const c = bb.colorizer;

        const state_col: color_mod.Color = switch (t.state) {
            .done => .green,
            .failed => .red,
            .warn => .yellow,
            .info => .cyan,
            else => .default,
        };

        const line_color = if (t.color != .default)
            t.color
        else if (state_col != .default)
            state_col
        else
            .default;
        const line_bg_color = t.bg_color;

        if (line_color != .default or line_bg_color != .default) {
            try c.begin(w, line_color, line_bg_color, &.{});
        }

        // Custom running icon prefix (without line background color to avoid emoji highlighting)
        if (t.icon orelse bb.opts.icon) |icon| {
            if (icon.len > 0) {
                if (line_color != .default or line_bg_color != .default) {
                    try c.reset(w);
                }
                try w.writeAll(icon);
                try w.writeAll(bb.opts.icon_gap);
                if (line_color != .default or line_bg_color != .default) {
                    try c.begin(w, line_color, line_bg_color, &.{});
                }
            }
        }

        // State glyph
        switch (t.state) {
            .pending => try color_mod.writeColored(w, c, "○", .bright_black, .default, &.{}),
            .running => try color_mod.writeColored(w, c, "●", .cyan, .default, &.{}),
            .done => {
                const sym = t.success_icon orelse bb.opts.success_icon orelse "✓";
                try color_mod.writeColored(w, c, sym, .green, .default, &.{.bold});
            },
            .failed => {
                const sym = t.failure_icon orelse bb.opts.failure_icon orelse "✗";
                try color_mod.writeColored(w, c, sym, .red, .default, &.{.bold});
            },
            .warn => {
                const sym = t.warning_icon orelse bb.opts.warning_icon orelse "⚠";
                try color_mod.writeColored(w, c, sym, .yellow, .default, &.{.bold});
            },
            .info => {
                const sym = t.info_icon orelse bb.opts.info_icon orelse "ℹ";
                try color_mod.writeColored(w, c, sym, .cyan, .default, &.{.bold});
            },
        }

        try w.writeAll(bb.opts.state_gap);

        if (line_color != .default or line_bg_color != .default) {
            try c.begin(w, line_color, line_bg_color, &.{});
        }

        // Name
        const name_slice = t.getName();
        var n_buf: [256]u8 = undefined;
        const name_str = if (bb.opts.max_name_width > 0)
            utils.truncateUtf8(&n_buf, name_slice, bb.opts.max_name_width)
        else
            name_slice;

        if (t.label_color != .default or t.label_bg_color != .default) {
            try color_mod.writeColored(w, c, name_str, t.label_color, t.label_bg_color, &.{});
            try w.writeAll(bb.opts.label_gap);
            if (line_color != .default or line_bg_color != .default) {
                try c.begin(w, line_color, line_bg_color, &.{});
            }
        } else {
            try w.writeAll(name_str);
            try w.writeAll(bb.opts.label_gap);
        }

        // Left bracket
        try w.writeAll(s.left_bracket);

        // Bar fill
        const visual_name_len = utils.stringDisplayWidth(name_str);
        const effective_width: usize = if (bb.opts.width > 0)
            @as(usize, bb.opts.width)
        else
            @max(10, @as(usize, bb.term.cols) / 2 -| visual_name_len -| 20);

        const fill_fg_col = if (t.fill_color != .default) t.fill_color else s.fill_fg;
        const fill_bg_col = if (t.fill_bg_color != .default) t.fill_bg_color else s.fill_bg;
        const empty_fg_col = if (t.empty_color != .default) t.empty_color else s.empty_fg;
        const empty_bg_col = if (t.empty_bg_color != .default) t.empty_bg_color else s.empty_bg;
        const is_task_complete = t.state == .done or t.state == .failed;
        const use_complete = is_task_complete and s.complete_fg != .default;

        if (total == 0) {
            var i: usize = 0;
            while (i < effective_width) : (i += 1) {
                try c.begin(w, empty_fg_col, empty_bg_col, &.{});
                try w.writeAll(s.empty);
                try c.reset(w);
            }
        } else {
            const frac = utils.fraction(completed, total);
            const filled = @as(usize, @intFromFloat(@as(f64, @floatFromInt(effective_width)) * frac));
            const filled_c = @min(filled, effective_width);
            const empty = effective_width - filled_c;

            if (filled_c > 0) {
                if (use_complete) {
                    try c.begin(w, s.complete_fg, fill_bg_col, s.attrs);
                    if (s.tip.len > 0 and filled_c < effective_width) {
                        var i: usize = 0;
                        while (i < filled_c -| 1) : (i += 1) try w.writeAll(s.fill);
                        try w.writeAll(s.tip);
                    } else {
                        var i: usize = 0;
                        while (i < filled_c) : (i += 1) try w.writeAll(s.fill);
                    }
                    try c.reset(w);
                } else if (s.fill_gradient) |grad| {
                    if (s.tip.len > 0 and filled_c < effective_width) {
                        var i: usize = 0;
                        while (i < filled_c -| 1) : (i += 1) {
                            const t_val = if (effective_width > 1) @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(effective_width - 1)) else 0.0;
                            try c.begin(w, grad.at(t_val), fill_bg_col, s.attrs);
                            try w.writeAll(s.fill);
                            try c.reset(w);
                        }
                        const tip_t = if (effective_width > 1) @as(f64, @floatFromInt(filled_c -| 1)) / @as(f64, @floatFromInt(effective_width - 1)) else 1.0;
                        try c.begin(w, grad.at(tip_t), fill_bg_col, s.attrs);
                        try w.writeAll(s.tip);
                        try c.reset(w);
                    } else {
                        var i: usize = 0;
                        while (i < filled_c) : (i += 1) {
                            const t_val = if (effective_width > 1) @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(effective_width - 1)) else 0.0;
                            try c.begin(w, grad.at(t_val), fill_bg_col, s.attrs);
                            try w.writeAll(s.fill);
                            try c.reset(w);
                        }
                    }
                } else {
                    try c.begin(w, fill_fg_col, fill_bg_col, s.attrs);
                    if (s.tip.len > 0 and filled_c < effective_width) {
                        var i: usize = 0;
                        while (i < filled_c -| 1) : (i += 1) try w.writeAll(s.fill);
                        try w.writeAll(s.tip);
                    } else {
                        var i: usize = 0;
                        while (i < filled_c) : (i += 1) try w.writeAll(s.fill);
                    }
                    try c.reset(w);
                }
            }
            if (empty > 0) {
                if (s.empty_gradient) |grad| {
                    var i: usize = 0;
                    while (i < empty) : (i += 1) {
                        const offset = filled_c + i;
                        const t_val = if (effective_width > 1) @as(f64, @floatFromInt(offset)) / @as(f64, @floatFromInt(effective_width - 1)) else 0.0;
                        try c.begin(w, grad.at(t_val), empty_bg_col, &.{});
                        try w.writeAll(s.empty);
                        try c.reset(w);
                    }
                } else {
                    try c.begin(w, empty_fg_col, empty_bg_col, &.{});
                    var i: usize = 0;
                    while (i < empty) : (i += 1) try w.writeAll(s.empty);
                    try c.reset(w);
                }
            }
        }

        if (line_color != .default or line_bg_color != .default) {
            try c.begin(w, line_color, line_bg_color, &.{});
        }

        // Right bracket
        try w.writeAll(s.right_bracket);

        // Percentage
        if (bb.opts.show_percent and total > 0) {
            const frac = utils.fraction(completed, total);
            var buf: [8]u8 = undefined;
            try w.print(" {s}", .{utils.formatPercent(&buf, frac)});
        }

        // Count
        if (bb.opts.show_count and total > 0) {
            try w.print(" {d}/{d}", .{ completed, total });
        }

        if (line_color != .default or line_bg_color != .default) {
            try c.reset(w);
        }
    }

    /// Finish all tasks and restore cursor.
    pub fn done(bb: *BatchBar) void {
        bb.done_flag = true;
        bb.render();
        var fw: std.Io.File.Writer = .init(bb.file, bb.io, &bb.write_buf);
        if (bb.opts.hide_cursor) {
            bb.colorizer.showCursor(&fw.interface) catch {};
            fw.flush() catch {};
        }
    }

    /// Count how many tasks are in a given state.
    pub fn countByState(bb: *const BatchBar, state: TaskState) usize {
        var n: usize = 0;
        for (bb.tasks[0..bb.count]) |*t| {
            if (t.state == state) n += 1;
        }
        return n;
    }

    /// Returns true when all tasks are in `done` or `failed` state.
    pub fn allFinished(bb: *const BatchBar) bool {
        for (bb.tasks[0..bb.count]) |*t| {
            if (t.state == .pending or t.state == .running) return false;
        }
        return true;
    }
};

test "BatchBar init and addTask" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
    });
    const t1 = bb.addTask("Compile", 100);
    const t2 = bb.addTask("Link", 50);
    try std.testing.expectEqual(@as(usize, 0), t1);
    try std.testing.expectEqual(@as(usize, 1), t2);
    try std.testing.expectEqual(@as(usize, 2), bb.count);
}

test "BatchBar setTaskCompleted and state transitions" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
    });
    const idx = bb.addTask("Work", 10);
    try std.testing.expectEqual(TaskState.pending, bb.tasks[idx].state);
    bb.setTaskCompleted(idx, 5);
    try std.testing.expectEqual(@as(usize, 5), bb.tasks[idx].completed.load(.acquire));
    try std.testing.expectEqual(TaskState.running, bb.tasks[idx].state);
    bb.setTaskDone(idx);
    try std.testing.expectEqual(TaskState.done, bb.tasks[idx].state);
    try std.testing.expectEqual(@as(usize, 10), bb.tasks[idx].completed.load(.acquire));
}

test "BatchBar setTaskFailed" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
    });
    const idx = bb.addTask("Risky Task", 20);
    bb.setTaskCompleted(idx, 10);
    bb.setTaskFailed(idx);
    try std.testing.expectEqual(TaskState.failed, bb.tasks[idx].state);
}

test "BatchBar allFinished" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
    });
    const t1 = bb.addTask("A", 10);
    const t2 = bb.addTask("B", 10);
    try std.testing.expect(!bb.allFinished());
    bb.setTaskDone(t1);
    try std.testing.expect(!bb.allFinished());
    bb.setTaskFailed(t2);
    try std.testing.expect(bb.allFinished());
}

test "BatchBar countByState" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
    });
    _ = bb.addTask("A", 10);
    _ = bb.addTask("B", 10);
    _ = bb.addTask("C", 10);
    try std.testing.expectEqual(@as(usize, 3), bb.countByState(.pending));
    bb.setTaskCompleted(0, 5);
    try std.testing.expectEqual(@as(usize, 2), bb.countByState(.pending));
    try std.testing.expectEqual(@as(usize, 1), bb.countByState(.running));
}

test "BatchTask getName" {
    var t = BatchTask{ .completed = std.atomic.Value(usize).init(0) };
    const name = "Hello Task";
    const len = @min(name.len, 127);
    @memcpy(t.name[0..len], name[0..len]);
    t.name[len] = 0;
    t.name_len = len;
    try std.testing.expectEqualSlices(u8, "Hello Task", t.getName());
}

test "BatchBar custom icons and states" {
    const io = std.Options.debug_io;
    const invalid_file = std.Io.File{
        .handle = if (@import("builtin").os.tag == .windows) std.os.windows.INVALID_HANDLE_VALUE else -1,
        .flags = .{ .nonblocking = false },
    };
    var bb = BatchBar.init(io, .{
        .file = invalid_file,
        .term = terminal.TermInfo.dumb,
        .color_enabled = false,
        .hide_cursor = false,
        .icon = "⚙️",
        .success_icon = "🎉",
        .failure_icon = "💥",
        .warning_icon = "⚠️",
        .info_icon = "📢",
    });
    const t1 = bb.addTask("Task 1", 10);
    const t2 = bb.addTask("Task 2", 10);

    // Verify task-specific override
    bb.tasks[t2].icon = "🚀";
    bb.tasks[t2].success_icon = "✨";

    try std.testing.expectEqualSlices(u8, "⚙️", bb.opts.icon.?);
    try std.testing.expectEqualSlices(u8, "🚀", bb.tasks[t2].icon.?);

    bb.setTaskWarning(t1);
    try std.testing.expectEqual(bb.tasks[t1].state, .warn);

    bb.setTaskInfo(t2);
    try std.testing.expectEqual(bb.tasks[t2].state, .info);
}
