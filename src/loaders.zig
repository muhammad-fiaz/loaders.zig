//! loaders.zig — Root module for the loaders.zig library.
//!
//! Import this file to get access to all public types:
//!
//!   const loaders = @import("loaders");
//!
//!   // Progress bar
//!   var bar = loaders.Bar.init(io, .{ .total = 100 });
//!   defer bar.done();
//!
//!   // Spinner
//!   const sp = try loaders.Spinner.start(io, .{ .text = "Loading…" });
//!   defer sp.stop(io);
//!
//!   // Multiple bars (fixed in-place rendering)
//!   var multi = loaders.MultiBar.init(io, .stderr(), null, .{});
//!   const b1 = multi.addBar(.{ .label = "A", .total = 50 });
//!   const b2 = multi.addBar(.{ .label = "B", .total = 80 });
//!   defer multi.done();
//!
//!   // Version
//!   std.debug.print("loaders.zig v{s}\n", .{loaders.version});

// Utility helpers
pub const utils = @import("utils.zig");

// Color and ANSI escape sequences
pub const color = @import("color.zig");
pub const Color = color.Color;
pub const Attribute = color.Attribute;
pub const Colorizer = color.Colorizer;

// Terminal detection
pub const terminal = @import("terminal.zig");
pub const TermInfo = terminal.TermInfo;

// Visual styles
pub const style = @import("style.zig");
pub const BarStyle = style.BarStyle;
pub const SpinnerStyle = style.SpinnerStyle;

// Progress bar
pub const bar = @import("bar.zig");
pub const Bar = bar.Bar;
pub const BarOptions = bar.Options;

// Spinner
pub const spinner = @import("spinner.zig");
pub const Spinner = spinner.Spinner;
pub const SpinnerOptions = spinner.Options;

// Multi-bar / multi-spinner
pub const multi = @import("multi.zig");
pub const MultiBar = multi.MultiBar;
pub const MultiBarOptions = multi.MultiBarOptions;
pub const MultiSpinner = multi.MultiSpinner;
pub const SpinnerItem = multi.SpinnerItem;

// Version information
pub const version_info = @import("version.zig");
pub const version: []const u8 = version_info.version;

// Update checker (optional — requires network access at runtime)
pub const UpdateChecker = @import("update_checker.zig");

// Tests (pulls in tests from all sub-modules)
test {
    _ = @import("utils.zig");
    _ = @import("color.zig");
    _ = @import("terminal.zig");
    _ = @import("style.zig");
    _ = @import("bar.zig");
    _ = @import("spinner.zig");
    _ = @import("multi.zig");
    _ = @import("version.zig");
}
