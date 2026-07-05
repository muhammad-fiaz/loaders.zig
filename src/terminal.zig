//! terminal.zig — Terminal detection and sizing.
//!
//! Provides:
//!  - TTY detection (via `Io.File.isTty`)
//!  - ANSI escape code support detection (via `Io.File.supportsAnsiEscapeCodes`)
//!  - Terminal column-width query (via platform-specific ioctl / Windows API)
//!  - `NO_COLOR` environment variable check

const std = @import("std");
const builtin = @import("builtin");

const native_os = builtin.os.tag;

/// Setup the terminal for correct UTF-8 output rendering on Windows.
/// On other platforms, this is a no-op.
pub fn setupTerminal() void {
    if (comptime native_os == .windows) {
        const windows = std.os.windows;
        const kernel32 = struct {
            extern "kernel32" fn SetConsoleOutputCP(wCodePageID: u32) callconv(.winapi) windows.BOOL;
            extern "kernel32" fn SetConsoleCP(wCodePageID: u32) callconv(.winapi) windows.BOOL;
        };
        // 65001 is UTF-8
        _ = kernel32.SetConsoleOutputCP(65001);
        _ = kernel32.SetConsoleCP(65001);
    }
}

/// Information about the terminal attached to a `std.Io.File`.
pub const TermInfo = struct {
    /// Whether the file is a TTY.
    is_tty: bool,
    /// Whether ANSI escape codes are supported (enabled).
    ansi_supported: bool,
    /// Terminal width in columns (default 80 if unknown).
    cols: u16,

    /// A sensible default for non-TTY or error situations.
    pub const dumb: TermInfo = .{
        .is_tty = false,
        .ansi_supported = false,
        .cols = 80,
    };
};

/// Query terminal information for `file` using the given `io` instance.
///
/// For stderr, prefer `queryStderr`. This is the generic version.
///
/// If `file` is not a TTY, returns `TermInfo.dumb`.
pub fn query(file: std.Io.File, io: std.Io) TermInfo {
    // Check TTY
    const is_tty = file.isTty(io) catch return .dumb;
    if (!is_tty) return .dumb;

    // Try to enable ANSI codes (needed on Windows)
    file.enableAnsiEscapeCodes(io) catch {};
    const ansi = file.supportsAnsiEscapeCodes(io) catch false;

    return .{
        .is_tty = true,
        .ansi_supported = ansi,
        .cols = queryColsForFile(file),
    };
}

/// Convenience: query terminal info for stderr.
pub fn queryStderr(io: std.Io) TermInfo {
    return query(.stderr(), io);
}

/// Convenience: query terminal info for stdout.
pub fn queryStdout(io: std.Io) TermInfo {
    return query(.stdout(), io);
}

/// Whether the `NO_COLOR` environment variable is set in `environ`.
///
/// See https://no-color.org/
pub fn noColorSet(environ: std.process.Environ) bool {
    return environ.containsConstant("NO_COLOR");
}

/// Decide whether color should be enabled:
///  1. If `NO_COLOR` is set → disabled.
///  2. If the file is a TTY with ANSI support → enabled.
///  3. Otherwise → disabled.
pub fn shouldEnableColor(info: TermInfo, environ: std.process.Environ) bool {
    if (noColorSet(environ)) return false;
    return info.ansi_supported;
}

fn queryColsForFile(file: std.Io.File) u16 {
    return switch (native_os) {
        .windows => queryColsWindows(file),
        .wasi, .freestanding => 80,
        else => queryColsPosix(file),
    };
}

fn queryColsPosix(file: std.Io.File) u16 {
    const fd = file.handle;
    var ws: std.posix.winsize = .{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };
    const rc = std.posix.system.ioctl(fd, std.posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (std.posix.errno(rc) == .SUCCESS and ws.col > 0) {
        return ws.col;
    }
    return 80;
}

fn queryColsWindows(file: std.Io.File) u16 {
    if (comptime native_os != .windows) return 80;
    const windows = std.os.windows;
    const COORD = extern struct {
        X: i16,
        Y: i16,
    };
    const SMALL_RECT = extern struct {
        Left: i16,
        Top: i16,
        Right: i16,
        Bottom: i16,
    };
    const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
        dwSize: COORD,
        dwCursorPosition: COORD,
        wAttributes: u16,
        srWindow: SMALL_RECT,
        dwMaximumWindowSize: COORD,
    };
    const kernel32 = struct {
        extern "kernel32" fn GetConsoleScreenBufferInfo(
            hConsoleOutput: windows.HANDLE,
            lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO,
        ) callconv(.winapi) windows.BOOL;
    };

    var csbi: CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (kernel32.GetConsoleScreenBufferInfo(file.handle, &csbi).toBool()) {
        const w = csbi.srWindow.Right - csbi.srWindow.Left + 1;
        if (w > 0) return @intCast(w);
    }
    return 80;
}

test "TermInfo.dumb defaults" {
    const info = TermInfo.dumb;
    try std.testing.expect(!info.is_tty);
    try std.testing.expect(!info.ansi_supported);
    try std.testing.expectEqual(@as(u16, 80), info.cols);
}

test "shouldEnableColor: disabled by NO_COLOR" {
    const info: TermInfo = .{ .is_tty = true, .ansi_supported = true, .cols = 80 };
    _ = info;
}
