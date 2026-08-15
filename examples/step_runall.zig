const std = @import("std");
const loaders = @import("loaders");

fn runStep(context: ?*anyopaque, step_name: []const u8) void {
    _ = context;
    _ = step_name;
    var g: std.Io.Threaded = .init_single_threaded;
    const io = g.io();
    var i: u32 = 0;
    while (i < 20) : (i += 1) {
        loaders.sleepMs(io, 40);
    }
}

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var seq = try loaders.StepSequence.init(allocator, io, .{});
    defer seq.deinit();

    _ = try seq.addStep(.{
        .name = "Install dependencies",
        .kind = .{ .spinner = .{
            .frames = &.{ ".", "..", "..." },
            .template = "{frame} {text}",
            .text = "Installing",
        } },
    });
    _ = try seq.addStep(.{
        .name = "Build project",
        .kind = .{ .spinner = .{
            .frames = &.{ "|", "/", "-", "\\" },
            .template = "{frame} {text}",
            .text = "Building",
        } },
    });
    _ = try seq.addStep(.{
        .name = "Run tests",
        .kind = .{ .bar = .{
            .total = 100,
            .style = .{ .filled = "#", .empty = "-" },
            .template = "Testing: {bar} {percent}%",
        } },
    });
    _ = try seq.addStep(.{
        .name = "Deploy",
        .kind = .{ .spinner = .{
            .frames = &.{ "|", "/", "-", "\\" },
            .template = "{frame} {text}",
            .text = "Deploying",
        } },
    });

    seq.runAll(null, runStep);
    seq.printSummary();
    loaders.showCursor(io);
}