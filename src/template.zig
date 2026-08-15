const std = @import("std");

pub const ElapsedFormatter = *const fn (ns: u64, buf: []u8) []const u8;
pub const SpeedFormatter = *const fn (per_sec: f64, buf: []u8) []const u8;

pub const FormatterSet = struct {
    elapsed: ?ElapsedFormatter = null,
    eta: ?ElapsedFormatter = null,
    speed: ?SpeedFormatter = null,
};

pub const Values = struct {
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    bar: ?[]const u8 = null,
    frame: ?[]const u8 = null,
    percent: ?f64 = null,
    count: ?u64 = null,
    total: ?u64 = null,
    elapsed_ns: ?u64 = null,
    eta_ns: ?u64 = null,
    speed: ?f64 = null,
    color: ?[]const u8 = null,
};

pub const InitError = error{ MissingFormatter };

pub const RenderError = error{ MissingFormatter, BufferOverflow };

/// Minimal stack-buffer string accumulator used during rendering.
pub const Accum = struct {
    buf: []u8,
    end: usize = 0,

    pub fn init(buf: []u8) Accum {
        return .{ .buf = buf };
    }

    pub fn write(self: *Accum, s: []const u8) RenderError!void {
        if (self.end + s.len > self.buf.len) return error.BufferOverflow;
        @memcpy(self.buf[self.end .. self.end + s.len], s);
        self.end += s.len;
    }

    pub fn print(self: *Accum, comptime fmt: []const u8, args: anytype) RenderError!void {
        const s = std.fmt.bufPrint(self.buf[self.end..], fmt, args) catch return error.BufferOverflow;
        self.end += s.len;
    }

    pub fn get(self: *const Accum) []const u8 {
        return self.buf[0..self.end];
    }
};

pub fn validate(template: []const u8, formatters: FormatterSet) InitError!void {
    var i: usize = 0;
    while (i < template.len) {
        if (template[i] != '{') {
            i += 1;
            continue;
        }
        const end = std.mem.indexOfScalar(u8, template[i + 1 ..], '}') orelse {
            i += 1;
            continue;
        };
        const name = template[i + 1 .. i + 1 + end];
        if (std.mem.eql(u8, name, "elapsed")) {
            if (formatters.elapsed == null) return error.MissingFormatter;
        } else if (std.mem.eql(u8, name, "eta")) {
            if (formatters.eta == null) return error.MissingFormatter;
        } else if (std.mem.eql(u8, name, "speed")) {
            if (formatters.speed == null) return error.MissingFormatter;
        }
        i += 1 + end + 1;
    }
}

pub fn render(
    buf: []u8,
    scratch: []u8,
    template: []const u8,
    values: Values,
    formatters: FormatterSet,
) RenderError![]const u8 {
    var acc = Accum.init(buf);

    var i: usize = 0;
    while (i < template.len) {
        if (template[i] != '{') {
            try acc.write(template[i .. i + 1]);
            i += 1;
            continue;
        }
        const end = std.mem.indexOfScalar(u8, template[i + 1 ..], '}') orelse {
            try acc.write(template[i..]);
            break;
        };
        const name = template[i + 1 .. i + 1 + end];

        if (std.mem.eql(u8, name, "bar")) {
            try acc.write(values.bar orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "frame")) {
            try acc.write(values.frame orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "percent")) {
            try acc.print("{d:.1}", .{values.percent orelse return error.MissingFormatter});
        } else if (std.mem.eql(u8, name, "count")) {
            try acc.print("{d}/{d}", .{ values.count orelse return error.MissingFormatter, values.total orelse 0 });
        } else if (std.mem.eql(u8, name, "elapsed")) {
            const ns = values.elapsed_ns orelse return error.MissingFormatter;
            const fmt = formatters.elapsed orelse return error.MissingFormatter;
            try acc.write(fmt(ns, scratch));
        } else if (std.mem.eql(u8, name, "eta")) {
            const ns = values.eta_ns orelse return error.MissingFormatter;
            const fmt = formatters.eta orelse return error.MissingFormatter;
            try acc.write(fmt(ns, scratch));
        } else if (std.mem.eql(u8, name, "speed")) {
            const v = values.speed orelse return error.MissingFormatter;
            const fmt = formatters.speed orelse return error.MissingFormatter;
            try acc.write(fmt(v, scratch));
        } else if (std.mem.eql(u8, name, "prefix")) {
            try acc.write(values.prefix orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "suffix")) {
            try acc.write(values.suffix orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "text")) {
            try acc.write(values.text orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "color")) {
            try acc.write(values.color orelse return error.MissingFormatter);
        } else if (std.mem.eql(u8, name, "reset")) {
            try acc.write("\x1b[0m");
        } else {
            try acc.write(template[i .. i + 1 + end + 1]);
        }
        i += 1 + end + 1;
    }

    return acc.get();
}

pub fn formatNs(buf: []u8, ns: u64) []const u8 {
    const total_s = ns / std.time.ns_per_s;
    const h = total_s / 3600;
    const m = (total_s % 3600) / 60;
    const s = total_s % 60;
    if (h > 0) {
        return std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}:{d:0>2}", .{ h, m, s }) catch "";
    }
    return std.fmt.bufPrint(buf, "{d:0>2}:{d:0>2}", .{ m, s }) catch "";
}

pub fn formatRate(buf: []u8, per_sec: f64) []const u8 {
    return std.fmt.bufPrint(buf, "{d:.1}/s", .{per_sec}) catch "";
}

fn elapsedFmt(ns: u64, buf: []u8) []const u8 {
    return formatNs(buf, ns);
}

test "render simple tokens" {
    const values = Values{
        .prefix = "Loading",
        .percent = 42.5,
    };
    var buf: [512]u8 = undefined;
    var scratch: [64]u8 = undefined;
    const out = try render(&buf, &scratch, "{prefix} {percent}", values, .{});
    try std.testing.expectEqualStrings("Loading 42.5", out);
}

test "render count token" {
    const values = Values{
        .count = 50,
        .total = 100,
    };
    var buf: [512]u8 = undefined;
    var scratch: [64]u8 = undefined;
    const out = try render(&buf, &scratch, "{count}", values, .{});
    try std.testing.expectEqualStrings("50/100", out);
}

test "render elapsed via formatter" {
    const values = Values{ .elapsed_ns = 90 * std.time.ns_per_s };
    var buf: [512]u8 = undefined;
    var scratch: [64]u8 = undefined;
    const out = try render(&buf, &scratch, "{elapsed}", values, .{ .elapsed = elapsedFmt });
    try std.testing.expectEqualStrings("01:30", out);
}

test "render unknown token stays literal" {
    var buf: [512]u8 = undefined;
    var scratch: [64]u8 = undefined;
    const out = try render(&buf, &scratch, "{unknown} {percent}", .{ .percent = 1.0 }, .{});
    try std.testing.expectEqualStrings("{unknown} 1.0", out);
}

test "validate rejects missing formatter" {
    try std.testing.expectError(error.MissingFormatter, validate("{elapsed}", .{}));
    try validate("{bar} {percent}%", .{});
}

test "formatNs formats durations" {
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("00:45", formatNs(&buf, 45 * std.time.ns_per_s));
    try std.testing.expectEqualStrings("01:02:03", formatNs(&buf, (1 * 3600 + 2 * 60 + 3) * std.time.ns_per_s));
}

test "formatRate formats speed" {
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("123.4/s", formatRate(&buf, 123.4));
}