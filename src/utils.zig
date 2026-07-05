//! utils.zig — Pure helper functions for the loaders.zig library.
//!
//! These functions have zero side-effects and require no I/O instance.
//! They are the innermost layer that everything else builds on.

const std = @import("std");

/// Repeat a single ASCII character `n` times into `buf`.
/// `buf` must have at least `n` bytes of space.
/// Returns the slice that was written.
pub fn repeatChar(buf: []u8, char: u8, n: usize) []u8 {
    const len = @min(n, buf.len);
    @memset(buf[0..len], char);
    return buf[0..len];
}

/// Clamp `value` to [min_val, max_val].
pub fn clamp(comptime T: type, value: T, min_val: T, max_val: T) T {
    return @max(min_val, @min(max_val, value));
}

/// Given a `current` and `total`, compute the 0.0–1.0 progress fraction.
/// Returns 0 if `total == 0`.
pub fn fraction(current: usize, total: usize) f64 {
    if (total == 0) return 0.0;
    return @as(f64, @floatFromInt(current)) / @as(f64, @floatFromInt(total));
}

/// Truncate a UTF-8 string to at most `max_chars` *display columns* (ASCII
/// only: one byte == one column). Appends "…" if truncated.
/// `buf` must be large enough for the output (max_chars + 3 bytes for "…").
pub fn truncate(buf: []u8, s: []const u8, max_chars: usize) []const u8 {
    if (s.len <= max_chars) return s;
    const limit = @min(max_chars, buf.len -| 3);
    @memcpy(buf[0..limit], s[0..limit]);
    buf[limit] = 0xe2; // UTF-8 "…" (U+2026)
    buf[limit + 1] = 0x80;
    buf[limit + 2] = 0xa6;
    return buf[0 .. limit + 3];
}

/// Safely truncate a UTF-8 string to a maximum number of visual columns.
/// Appends a "…" if truncated.
pub fn truncateUtf8(buf: []u8, s: []const u8, max_cols: usize) []const u8 {
    var width: usize = 0;
    var i: usize = 0;
    var utf8 = std.unicode.Utf8View.init(s) catch return s;
    var iter = utf8.iterator();
    while (iter.nextCodepoint()) |cp| {
        var cp_w: usize = 1;
        if (cp == 0xFE0F or cp == 0xFE0E) {
            cp_w = 0;
        } else if (cp >= 0x0300 and cp <= 0x036F) {
            cp_w = 0;
        } else if (cp >= 0x2000) {
            cp_w = 2;
        }
        if (width + cp_w > max_cols) {
            if (i + 3 <= buf.len) {
                @memcpy(buf[0..i], s[0..i]);
                buf[i] = 0xe2;
                buf[i + 1] = 0x80;
                buf[i + 2] = 0xa6;
                return buf[0 .. i + 3];
            } else {
                return s[0..i];
            }
        }
        width += cp_w;
        i += std.unicode.utf8CodepointSequenceLength(cp) catch 1;
    }
    return s;
}

/// Format `bytes` as a human-readable size (B, KiB, MiB, GiB, TiB).
/// Writes the result into `buf` and returns the slice.
pub fn formatBytes(buf: []u8, bytes: u64) []const u8 {
    const kib: u64 = 1024;
    const mib: u64 = kib * 1024;
    const gib: u64 = mib * 1024;
    const tib: u64 = gib * 1024;
    if (bytes >= tib) {
        return std.fmt.bufPrint(buf, "{d:.2} TiB", .{@as(f64, @floatFromInt(bytes)) / @as(f64, @floatFromInt(tib))}) catch buf[0..0];
    } else if (bytes >= gib) {
        return std.fmt.bufPrint(buf, "{d:.2} GiB", .{@as(f64, @floatFromInt(bytes)) / @as(f64, @floatFromInt(gib))}) catch buf[0..0];
    } else if (bytes >= mib) {
        return std.fmt.bufPrint(buf, "{d:.2} MiB", .{@as(f64, @floatFromInt(bytes)) / @as(f64, @floatFromInt(mib))}) catch buf[0..0];
    } else if (bytes >= kib) {
        return std.fmt.bufPrint(buf, "{d:.2} KiB", .{@as(f64, @floatFromInt(bytes)) / @as(f64, @floatFromInt(kib))}) catch buf[0..0];
    } else {
        return std.fmt.bufPrint(buf, "{d} B", .{bytes}) catch buf[0..0];
    }
}

/// Format an elapsed duration in seconds to a human-readable MM:SS or H:MM:SS.
pub fn formatEta(buf: []u8, seconds: u64) []const u8 {
    const h = seconds / 3600;
    const m = (seconds % 3600) / 60;
    const s = seconds % 60;
    if (h > 0) {
        return std.fmt.bufPrint(buf, "{d}:{d:0>2}:{d:0>2}", .{ h, m, s }) catch buf[0..0];
    } else {
        return std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}", .{ m, s }) catch buf[0..0];
    }
}

/// Linearly interpolate between `a` and `b` by factor `t` (0.0–1.0).
pub fn lerp(a: f64, b: f64, t: f64) f64 {
    return a + (b - a) * t;
}

/// Exponential moving average rate smoother.
/// `prev_rate` is the previous smoothed rate, `new_rate` is the newly observed rate.
/// `alpha` controls responsiveness: 0.0 = never update, 1.0 = always use latest.
/// Typical value: 0.1–0.3 for smooth display.
pub fn smoothRate(prev_rate: f64, new_rate: f64, alpha: f64) f64 {
    if (prev_rate <= 0.0) return new_rate;
    return alpha * new_rate + (1.0 - alpha) * prev_rate;
}

/// Format a rate value for display, with optional bytes-per-second formatting.
/// Returns a slice into `buf`.
pub fn formatRate(buf: []u8, rate: f64, unit_is_bytes: bool) []const u8 {
    if (unit_is_bytes) {
        var rbuf: [32]u8 = undefined;
        const r_u = @as(u64, @intFromFloat(@max(0.0, rate)));
        const bytes_str = formatBytes(&rbuf, r_u);
        return std.fmt.bufPrint(buf, "{s}/s", .{bytes_str}) catch buf[0..0];
    } else {
        return std.fmt.bufPrint(buf, "{d:.1}/s", .{rate}) catch buf[0..0];
    }
}

/// Format a count as "current/total" with optional unit suffix.
/// E.g. formatCount(buf, 3, 10, "files") => "3/10 files"
pub fn formatCount(buf: []u8, current: usize, total: usize, unit: []const u8) []const u8 {
    if (unit.len > 0) {
        return std.fmt.bufPrint(buf, "{d}/{d} {s}", .{ current, total, unit }) catch buf[0..0];
    }
    return std.fmt.bufPrint(buf, "{d}/{d}", .{ current, total }) catch buf[0..0];
}

/// Format a percentage string aligned to 3 digits (e.g. " 42%", "100%").
pub fn formatPercent(buf: []u8, frac: f64) []const u8 {
    const pct = @min(100.0, @max(0.0, frac * 100.0));
    return std.fmt.bufPrint(buf, "{d:3.0}%", .{pct}) catch buf[0..0];
}

pub const DateTime = struct {
    year: u16,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

/// Convert a Unix timestamp (seconds since 1970-01-01 00:00:00 UTC) to dynamic
/// calendar Year, Month, Day, Hour, Minute, and Second (Howard Hinnant's algorithm).
pub fn unixToDateTime(seconds: i64) DateTime {
    const SECONDS_PER_DAY: i64 = 86400;

    var remaining_sec = seconds;
    var days = @divTrunc(remaining_sec, SECONDS_PER_DAY);
    remaining_sec = @mod(remaining_sec, SECONDS_PER_DAY);
    if (remaining_sec < 0) {
        remaining_sec += SECONDS_PER_DAY;
        days -= 1;
    }

    const hour = @as(u8, @intCast(@divTrunc(remaining_sec, 3600)));
    remaining_sec = @mod(remaining_sec, 3600);
    const minute = @as(u8, @intCast(@divTrunc(remaining_sec, 60)));
    const second = @as(u8, @intCast(@mod(remaining_sec, 60)));

    const z = days + 719468;
    const era = @divTrunc((if (z >= 0) z else z - 146096), 146097);
    const doe = @as(u64, @intCast(z - era * 146097));
    const yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    const y = @as(i64, @intCast(yoe)) + era * 400;
    const doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    const mp = (5 * doy + 2) / 153;
    const d = doy - (153 * mp + 2) / 5 + 1;
    const m = if (mp < 10) mp + 3 else mp - 9;
    const year = @as(u16, @intCast(y + (if (m <= 2) @as(i64, 1) else 0)));

    return .{
        .year = year,
        .month = @as(u8, @intCast(m)),
        .day = @as(u8, @intCast(d)),
        .hour = hour,
        .minute = minute,
        .second = second,
    };
}

pub fn stringDisplayWidth(s: []const u8) usize {
    if (s.len == 0) return 0;
    var width: usize = 0;
    var utf8 = std.unicode.Utf8View.init(s) catch return s.len;
    var iter = utf8.iterator();
    while (iter.nextCodepoint()) |cp| {
        // Variation selectors (non-spacing)
        if (cp == 0xFE0F or cp == 0xFE0E) {
            continue;
        }
        // Combining diacritical marks (non-spacing)
        if (cp >= 0x0300 and cp <= 0x036F) {
            continue;
        }
        // Wide characters and emojis
        if (cp >= 0x2000) {
            width += 2;
        } else {
            width += 1;
        }
    }
    return width;
}

/// Format `seconds` as a human-readable date `YYYY-MM-DD`.
/// Writes into `buf` and returns the slice.
pub fn formatDate(buf: []u8, seconds: i64) []const u8 {
    const dt = unixToDateTime(seconds);
    return std.fmt.bufPrint(buf, "{d:0>4}-{d:0>2}-{d:0>2}", .{ dt.year, dt.month, dt.day }) catch buf[0..0];
}

/// Format `seconds` as a human-readable time `HH:MM:SS`.
/// Writes into `buf` and returns the slice.
pub fn formatTime(buf: []u8, seconds: i64) []const u8 {
    const dt = unixToDateTime(seconds);
    return std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}:{d:0>2}", .{ dt.hour, dt.minute, dt.second }) catch buf[0..0];
}

/// Format `seconds` as 12-hour AM/PM time format.
/// Writes into `buf` and returns the slice.
pub fn formatTime12h(buf: []u8, seconds: i64) []const u8 {
    const dt = unixToDateTime(seconds);
    const am_pm = if (dt.hour >= 12) "PM" else "AM";
    const hour12 = if (dt.hour == 0) @as(u8, 12) else (if (dt.hour > 12) dt.hour - 12 else dt.hour);
    return std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}:{d:0>2} {s}", .{ hour12, dt.minute, dt.second, am_pm }) catch buf[0..0];
}

/// Format `seconds` as `YYYY-MM-DD HH:MM:SS`.
/// Writes into `buf` and returns the slice.
pub fn formatDateTime(buf: []u8, seconds: i64) []const u8 {
    const dt = unixToDateTime(seconds);
    return std.fmt.bufPrint(buf, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}", .{
        dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
    }) catch buf[0..0];
}

test "repeatChar" {
    var buf: [16]u8 = undefined;
    const s = repeatChar(&buf, '#', 5);
    try std.testing.expectEqualSlices(u8, "#####", s);
}

test "clamp" {
    try std.testing.expectEqual(@as(usize, 0), clamp(usize, 0, 0, 10));
    try std.testing.expectEqual(@as(usize, 10), clamp(usize, 10, 0, 10));
    try std.testing.expectEqual(@as(usize, 5), clamp(usize, 5, 0, 10));
    try std.testing.expectEqual(@as(usize, 10), clamp(usize, 20, 0, 10));
}

test "fraction" {
    try std.testing.expectApproxEqAbs(0.5, fraction(5, 10), 1e-10);
    try std.testing.expectApproxEqAbs(0.0, fraction(0, 0), 1e-10);
    try std.testing.expectApproxEqAbs(1.0, fraction(10, 10), 1e-10);
}

test "formatBytes" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "512 B", formatBytes(&buf, 512));
    try std.testing.expectEqualSlices(u8, "1.00 KiB", formatBytes(&buf, 1024));
    try std.testing.expectEqualSlices(u8, "1.00 MiB", formatBytes(&buf, 1024 * 1024));
    try std.testing.expectEqualSlices(u8, "1.00 GiB", formatBytes(&buf, 1024 * 1024 * 1024));
}

test "formatEta" {
    var buf: [16]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "01:05", formatEta(&buf, 65));
    try std.testing.expectEqualSlices(u8, "1:00:00", formatEta(&buf, 3600));
}

test "truncate" {
    var buf: [32]u8 = undefined;
    const short = truncate(&buf, "hello", 10);
    try std.testing.expectEqualSlices(u8, "hello", short);
    const long = truncate(&buf, "hello world!", 5);
    try std.testing.expect(long.len == 8); // 5 + 3
}

test "unixToDateTime and date/time formatting" {
    const dt0 = unixToDateTime(0);
    try std.testing.expectEqual(@as(u16, 1970), dt0.year);
    try std.testing.expectEqual(@as(u8, 1), dt0.month);
    try std.testing.expectEqual(@as(u8, 1), dt0.day);
    try std.testing.expectEqual(@as(u8, 0), dt0.hour);
    try std.testing.expectEqual(@as(u8, 0), dt0.minute);
    try std.testing.expectEqual(@as(u8, 0), dt0.second);

    const dt1 = unixToDateTime(1774573735);
    try std.testing.expectEqual(@as(u16, 2026), dt1.year);
    try std.testing.expectEqual(@as(u8, 3), dt1.month);
    try std.testing.expectEqual(@as(u8, 27), dt1.day);
    try std.testing.expectEqual(@as(u8, 1), dt1.hour);
    try std.testing.expectEqual(@as(u8, 8), dt1.minute);
    try std.testing.expectEqual(@as(u8, 55), dt1.second);

    var dbuf: [32]u8 = undefined;
    var tbuf: [32]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "1970-01-01", formatDate(&dbuf, 0));
    try std.testing.expectEqualSlices(u8, "00:00:00", formatTime(&tbuf, 0));

    try std.testing.expectEqualSlices(u8, "2026-03-27", formatDate(&dbuf, 1774573735));
    try std.testing.expectEqualSlices(u8, "01:08:55", formatTime(&tbuf, 1774573735));
}

test "smoothRate" {
    // Cold start: prev=0, returns new
    try std.testing.expectApproxEqAbs(10.0, smoothRate(0.0, 10.0, 0.3), 1e-10);
    // With existing: blends toward new value
    const blended = smoothRate(10.0, 20.0, 0.3);
    try std.testing.expect(blended > 10.0 and blended < 20.0);
    // alpha=1.0: always use new value
    try std.testing.expectApproxEqAbs(20.0, smoothRate(10.0, 20.0, 1.0), 1e-10);
    // alpha=0.0: always keep old value
    try std.testing.expectApproxEqAbs(10.0, smoothRate(10.0, 20.0, 0.0), 1e-10);
}

test "formatRate bytes" {
    var buf: [64]u8 = undefined;
    const r = formatRate(&buf, 1024.0, true);
    try std.testing.expectEqualSlices(u8, "1.00 KiB/s", r);
}

test "formatRate items" {
    var buf: [64]u8 = undefined;
    const r = formatRate(&buf, 5.5, false);
    try std.testing.expectEqualSlices(u8, "5.5/s", r);
}

test "formatCount with unit" {
    var buf: [64]u8 = undefined;
    const s = formatCount(&buf, 3, 10, "files");
    try std.testing.expectEqualSlices(u8, "3/10 files", s);
}

test "formatCount without unit" {
    var buf: [64]u8 = undefined;
    const s = formatCount(&buf, 7, 100, "");
    try std.testing.expectEqualSlices(u8, "7/100", s);
}

test "formatPercent" {
    var buf: [16]u8 = undefined;
    try std.testing.expectEqualSlices(u8, " 50%", formatPercent(&buf, 0.5));
    try std.testing.expectEqualSlices(u8, "100%", formatPercent(&buf, 1.0));
    try std.testing.expectEqualSlices(u8, "  0%", formatPercent(&buf, 0.0));
}

test "formatDateTime" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "1970-01-01 00:00:00", formatDateTime(&buf, 0));
}

test "lerp" {
    try std.testing.expectApproxEqAbs(5.0, lerp(0.0, 10.0, 0.5), 1e-10);
    try std.testing.expectApproxEqAbs(0.0, lerp(0.0, 10.0, 0.0), 1e-10);
    try std.testing.expectApproxEqAbs(10.0, lerp(0.0, 10.0, 1.0), 1e-10);
}

test "stringDisplayWidth" {
    try std.testing.expectEqual(@as(usize, 5), stringDisplayWidth("hello"));
    try std.testing.expectEqual(@as(usize, 2), stringDisplayWidth("🚀"));
    try std.testing.expectEqual(@as(usize, 2), stringDisplayWidth("⚙️"));
    try std.testing.expectEqual(@as(usize, 7), stringDisplayWidth("🚀 tick"));
}

test "formatTime12h" {
    var buf: [32]u8 = undefined;
    // 0 seconds => 12:00:00 AM
    try std.testing.expectEqualSlices(u8, "12:00:00 AM", formatTime12h(&buf, 0));
    // 13 hours = 46800 seconds => 01:00:00 PM
    try std.testing.expectEqualSlices(u8, "01:00:00 PM", formatTime12h(&buf, 46800));
}

test "truncateUtf8" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "hello", truncateUtf8(&buf, "hello", 10));
    try std.testing.expectEqualSlices(u8, "hel…", truncateUtf8(&buf, "hello", 3));
    try std.testing.expectEqualSlices(u8, "🚀 w…", truncateUtf8(&buf, "🚀 world", 4));
    try std.testing.expectEqualSlices(u8, "🚀…", truncateUtf8(&buf, "🚀 world", 2));
}
