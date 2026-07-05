//! update_checker.zig — Optional GitHub release update checker for loaders.zig.
//!
//! Parses and compares semantic versions using `std.SemanticVersion.parse`
//! so that pre-release tags and build metadata are handled correctly per
//! the Semantic Versioning 2.0.0 specification.
//!
//! Usage:
//!
//!   const io  = init.io;  // or std.Options.debug_threaded_io.?.io()
//!   var  gpa  = std.heap.GeneralPurposeAllocator(.{}){};
//!   defer _ = gpa.deinit();
//!
//!   if (try loaders.UpdateChecker.check(gpa.allocator(), io)) |result| {
//!       defer gpa.allocator().free(result.latest_raw);
//!       if (result.update_available) {
//!           std.debug.print(
//!               "Update available: v{s}  (running v{s})\n",
//!               .{ result.latest_raw, loaders.version },
//!           );
//!       }
//!   }
//!
//! Network or parse errors are absorbed and return `null` — the library
//! never crashes due to an unavailable update server.

const std = @import("std");
const version_mod = @import("version.zig");

/// Result returned by a successful `check` call.
pub const UpdateResult = struct {
    /// Raw version string from GitHub (e.g. "0.1.0"). Caller must free.
    latest_raw: []const u8,
    /// Parsed semantic version of the latest release.
    latest: std.SemanticVersion,
    /// Parsed semantic version of the running library.
    current: std.SemanticVersion,
    /// True when `latest` is strictly greater than `current`.
    update_available: bool,
    /// The ordering relationship: `.lt` = current older, `.eq` = same, `.gt` = current newer.
    order: std.math.Order,
};

/// Maximum response body size accepted from the GitHub API (64 KiB).
const max_body_bytes: usize = 65536;

/// Check GitHub Releases for a newer version of loaders.zig.
///
/// Parameters:
///   - `allocator`: used for the HTTP client and the returned `latest_raw` string.
///   - `io`:        the `std.Io` instance for network operations.
///
/// Returns `null` on any network or parse failure. On success the caller is
/// responsible for calling `allocator.free(result.latest_raw)`.
pub fn check(allocator: std.mem.Allocator, io: std.Io) !?UpdateResult {
    // Parse the current version at call time (not comptime) to avoid issues
    // with error handling in comptime context.
    const current_ver = std.SemanticVersion.parse(version_mod.version) catch |err| {
        std.log.debug("update_checker: cannot parse current version '{s}': {}", .{ version_mod.version, err });
        return null;
    };

    // Fixed buffer for the response body — GitHub API payloads are small.
    var body_buf: [max_body_bytes]u8 = undefined;
    var body_writer = std.Io.Writer.fixed(&body_buf);

    // Build and run the HTTP client.
    var client = std.http.Client{ .allocator = allocator, .io = io };
    defer client.deinit();

    const fetch_result = client.fetch(.{
        .location = .{ .url = version_mod.releases_api_url },
        .extra_headers = &.{
            .{ .name = "User-Agent", .value = "loaders.zig/" ++ version_mod.version },
            .{ .name = "Accept", .value = "application/vnd.github.v3+json" },
        },
        .response_writer = &body_writer,
    }) catch |err| {
        std.log.debug("update_checker: HTTP fetch failed: {}", .{err});
        return null;
    };

    if (fetch_result.status != .ok) {
        std.log.debug("update_checker: unexpected HTTP status {}", .{fetch_result.status});
        return null;
    }

    const body = body_writer.buffered();

    // Lightweight scan for "tag_name" in the JSON response.
    // We deliberately avoid a full JSON parser to keep this dependency-free.
    const raw_tag = extractTagName(body) orelse {
        std.log.debug("update_checker: 'tag_name' field not found in response", .{});
        return null;
    };

    // GitHub tags may be prefixed with 'v' (e.g. "v0.1.0").
    const tag_clean = if (raw_tag.len > 0 and raw_tag[0] == 'v') raw_tag[1..] else raw_tag;

    const latest_ver = std.SemanticVersion.parse(tag_clean) catch |err| {
        std.log.debug("update_checker: cannot parse latest version '{s}': {}", .{ tag_clean, err });
        return null;
    };

    const ord = current_ver.order(latest_ver);

    // Duplicate the raw string so the caller can free it independently.
    const latest_owned = try allocator.dupe(u8, tag_clean);

    return UpdateResult{
        .latest_raw = latest_owned,
        .latest = latest_ver,
        .current = current_ver,
        .update_available = ord == .lt,
        .order = ord,
    };
}

/// Lightweight JSON field extractor for `"tag_name": "..."`.
/// Returns a slice into `body` (no allocation).
fn extractTagName(body: []const u8) ?[]const u8 {
    const key = "\"tag_name\"";
    const key_pos = indexOfSlice(body, key) orelse return null;
    const after_key = body[key_pos + key.len ..];
    const colon_pos = indexOfScalar(after_key, ':') orelse return null;
    const after_colon = trimLeft(after_key[colon_pos + 1 ..], " \t\r\n");
    if (after_colon.len == 0 or after_colon[0] != '"') return null;
    const value_start = after_colon[1..];
    const value_end = indexOfScalar(value_start, '"') orelse return null;
    return value_start[0..value_end];
}

inline fn indexOfSlice(haystack: []const u8, needle: []const u8) ?usize {
    return std.mem.indexOf(u8, haystack, needle);
}

inline fn indexOfScalar(haystack: []const u8, needle: u8) ?usize {
    return std.mem.indexOfScalar(u8, haystack, needle);
}

inline fn trimLeft(s: []const u8, chars: []const u8) []const u8 {
    return std.mem.trimStart(u8, s, chars);
}

test "extractTagName basic" {
    const json =
        \\{"tag_name":"v0.2.0","name":"Release 0.2.0"}
    ;
    const tag = extractTagName(json);
    try std.testing.expect(tag != null);
    try std.testing.expectEqualSlices(u8, "v0.2.0", tag.?);
}

test "extractTagName with spaces" {
    const json =
        \\{ "tag_name" : "1.0.0-alpha" , "draft": false }
    ;
    const tag = extractTagName(json);
    try std.testing.expect(tag != null);
    try std.testing.expectEqualSlices(u8, "1.0.0-alpha", tag.?);
}

test "extractTagName missing" {
    const json =
        \\{"name":"no-tag-here"}
    ;
    try std.testing.expect(extractTagName(json) == null);
}

test "SemanticVersion comparison" {
    const current = try std.SemanticVersion.parse("0.0.2");
    const newer = try std.SemanticVersion.parse("0.1.0");
    const older = try std.SemanticVersion.parse("0.0.1");

    try std.testing.expect(current.order(newer) == .lt); // update available
    try std.testing.expect(current.order(older) == .gt); // current is newer
    try std.testing.expect(current.order(current) == .eq); // same
}

test "version_mod.version parses as SemanticVersion" {
    _ = try std.SemanticVersion.parse(version_mod.version);
}
