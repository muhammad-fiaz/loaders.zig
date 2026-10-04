const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;

pub const TerminalSize = struct {
    rows: u16,
    cols: u16,
};

var initialized = std.atomic.Value(bool).init(false);

pub fn ensureInitialized(io: std.Io) void {
    if (initialized.swap(true, .acquire)) return;
    if (builtin.os.tag == .windows) {
        const file = std.Io.File.stdout();
        file.enableAnsiEscapeCodes(io) catch {};
        var setCp = windows.CONSOLE.USER_IO.SET_CP(.Output, 65001);
        _ = setCp.operate(io, file) catch {};
    }
}

pub fn sleepMs(io: std.Io, ms: u64) void {
    io.sleep(.fromMilliseconds(@intCast(ms)), .awake) catch {};
}

pub fn timestampMs(io: std.Io) i64 {
    return std.Io.Timestamp.now(io, .awake).toMilliseconds();
}

pub fn getSize(io: std.Io) TerminalSize {
    if (builtin.os.tag == .windows) {
        return getSizeWindows(io);
    } else {
        return getSizeUnix();
    }
}

fn getSizeWindows(io: std.Io) TerminalSize {
    const file = std.Io.File.stdout();
    var getConsoleInfo = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
    switch (getConsoleInfo.operate(io, file) catch {
        return .{ .rows = 24, .cols = 80 };
    }) {
        .SUCCESS => {
            return .{
                .rows = @intCast(getConsoleInfo.Data.dwWindowSize.Y),
                .cols = @intCast(getConsoleInfo.Data.dwWindowSize.X),
            };
        },
        else => return .{ .rows = 24, .cols = 80 },
    }
}

fn getSizeUnix() TerminalSize {
    var wsz: std.posix.winsize = undefined;
    const file = std.Io.File.stdout();
    const rc = std.posix.system.ioctl(file.handle, std.posix.T.IOCGWINSZ, &wsz);
    if (rc < 0) {
        return .{ .rows = 24, .cols = 80 };
    }
    return .{ .rows = wsz.row, .cols = wsz.col };
}

pub fn hideCursor(io: std.Io) void {
    writeAnsi(io, "\x1b[?25l");
}

pub fn showCursor(io: std.Io) void {
    writeAnsi(io, "\x1b[?25h");
}

pub fn moveUp(io: std.Io, lines: u16) void {
    if (lines == 0) return;
    if (builtin.os.tag == .windows) {
        const file = std.Io.File.stdout();
        var csbi = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
        switch (csbi.operate(io, file) catch return) {
            .SUCCESS => {},
            else => return,
        }
        const pos = windows.COORD{
            .X = csbi.Data.dwCursorPosition.X,
            .Y = csbi.Data.dwCursorPosition.Y - @as(i16, @intCast(lines)),
        };
        var setPos = windows.CONSOLE.USER_IO.SET_CURSOR_POSITION(pos);
        _ = setPos.operate(io, file) catch return;
    } else {
        var buf: [16]u8 = undefined;
        const n: u16 = @intCast(lines);
        const s = std.fmt.bufPrint(&buf, "\x1b[{d}A", .{n}) catch return;
        writeAnsi(io, s);
    }
}

pub fn moveDown(io: std.Io, lines: u16) void {
    if (lines == 0) return;
    if (builtin.os.tag == .windows) {
        const file = std.Io.File.stdout();
        var csbi = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
        switch (csbi.operate(io, file) catch return) {
            .SUCCESS => {},
            else => return,
        }
        const pos = windows.COORD{
            .X = csbi.Data.dwCursorPosition.X,
            .Y = csbi.Data.dwCursorPosition.Y + @as(i16, @intCast(lines)),
        };
        var setPos = windows.CONSOLE.USER_IO.SET_CURSOR_POSITION(pos);
        _ = setPos.operate(io, file) catch return;
    } else {
        var buf: [16]u8 = undefined;
        const n: u16 = @intCast(lines);
        const s = std.fmt.bufPrint(&buf, "\x1b[{d}B", .{n}) catch return;
        writeAnsi(io, s);
    }
}

pub fn moveRight(io: std.Io, cols: u16) void {
    if (cols == 0) return;
    if (builtin.os.tag == .windows) {
        const file = std.Io.File.stdout();
        var csbi = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
        switch (csbi.operate(io, file) catch return) {
            .SUCCESS => {},
            else => return,
        }
        const pos = windows.COORD{
            .X = csbi.Data.dwCursorPosition.X + @as(i16, @intCast(cols)),
            .Y = csbi.Data.dwCursorPosition.Y,
        };
        var setPos = windows.CONSOLE.USER_IO.SET_CURSOR_POSITION(pos);
        _ = setPos.operate(io, file) catch return;
    } else {
        var buf: [16]u8 = undefined;
        const n: u16 = @intCast(cols);
        const s = std.fmt.bufPrint(&buf, "\x1b[{d}C", .{n}) catch return;
        writeAnsi(io, s);
    }
}

pub fn moveLeft(io: std.Io, cols: u16) void {
    if (cols == 0) return;
    if (builtin.os.tag == .windows) {
        const file = std.Io.File.stdout();
        var csbi = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
        switch (csbi.operate(io, file) catch return) {
            .SUCCESS => {},
            else => return,
        }
        const pos = windows.COORD{
            .X = csbi.Data.dwCursorPosition.X - @as(i16, @intCast(cols)),
            .Y = csbi.Data.dwCursorPosition.Y,
        };
        var setPos = windows.CONSOLE.USER_IO.SET_CURSOR_POSITION(pos);
        _ = setPos.operate(io, file) catch return;
    } else {
        var buf: [16]u8 = undefined;
        const n: u16 = @intCast(cols);
        const s = std.fmt.bufPrint(&buf, "\x1b[{d}D", .{n}) catch return;
        writeAnsi(io, s);
    }
}

pub fn eraseLine(io: std.Io) void {
    writeAnsi(io, "\r\x1b[K");
}

var gStdoutWriter: ?std.Io.File.Writer = null;
var gStdoutInitialized = std.atomic.Value(bool).init(false);

/// Returns a writer attached to standard output using streaming mode
/// (required for terminals which are unseekable).
/// The writer is shared: all widgets must use the same `io` value.
/// Do not copy the returned pointer's target; use the pointer directly.
pub fn stdoutWriter(io: std.Io) *std.Io.Writer {
    ensureInitialized(io);
    if (!gStdoutInitialized.load(.acquire)) {
        gStdoutWriter = std.Io.File.stdout().writerStreaming(io, &.{});
        gStdoutInitialized.store(true, .release);
    }
    const fw: *std.Io.File.Writer = &gStdoutWriter.?;
    fw.io = io;
    return &fw.interface;
}

fn writeAnsi(io: std.Io, data: []const u8) void {
    const stdout = stdoutWriter(io);
    stdout.writeAll(data) catch {};
}

pub fn displayWidth(s: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        const cp = std.unicode.utf8Decode(s[i..]) catch {
            i += 1;
            width += 1;
            continue;
        };
        i += std.unicode.utf8CodepointSequenceLength(cp) catch 1;
        width += codepointWidth(cp);
    }
    return width;
}

fn codepointWidth(cp: u21) usize {
    if (cp < 0x20 or (cp >= 0x7f and cp < 0xa0)) return 1;
    if ((cp >= 0x0300 and cp <= 0x036f) or
        (cp >= 0x1ab0 and cp <= 0x1aff) or
        (cp >= 0x1dc0 and cp <= 0x1dff) or
        (cp >= 0x20d0 and cp <= 0x20ff) or
        (cp >= 0xfe20 and cp <= 0xfe2f)) return 0;
    if ((cp >= 0x1100 and cp <= 0x115f) or
        (cp >= 0x2e80 and cp <= 0xa4cf) or
        (cp >= 0xac00 and cp <= 0xd7a3) or
        (cp >= 0xf900 and cp <= 0xfaff) or
        (cp >= 0xfe30 and cp <= 0xfe4f) or
        (cp >= 0xff00 and cp <= 0xff60) or
        (cp >= 0xffe0 and cp <= 0xffe6) or
        (cp >= 0x1f300 and cp <= 0x1faff) or
        (cp >= 0x20000 and cp <= 0x3fffd)) return 2;
    return 1;
}
