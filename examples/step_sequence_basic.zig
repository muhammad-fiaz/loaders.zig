const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    var seq = try loaders.StepSequence.init(allocator, io, .{});
    defer seq.deinit();

    const install = try seq.addStep(.{
        .name = "Install dependencies",
        .kind = .{ .spinner = .{
            .frames = &.{ ".", "..", "..." },
            .template = "{frame} Installing...",
        } },
    });
    const build = try seq.addStep(.{
        .name = "Build project",
        .kind = .{ .spinner = .{
            .frames = &.{ "|", "/", "-", "\\" },
            .template = "{frame} Building...",
        } },
    });
    const test_step = try seq.addStep(.{
        .name = "Run tests",
        .kind = .{ .bar = .{
            .total = 100,
            .style = .{ .filled = "#", .empty = "-" },
            .template = "Testing: {bar} {percent}%",
        } },
    });
    const deploy = try seq.addStep(.{
        .name = "Deploy",
        .kind = .{ .spinner = .{
            .frames = &.{ "|", "/", "-", "\\" },
            .template = "{frame} Deploying...",
        } },
    });

    try seq.startStep(install);
    var i: u32 = 0;
    while (i < 20) : (i += 1) {
        loaders.sleepMs(io, 60);
    }
    seq.completeStep(install, .{});

    try seq.startStep(build);
    i = 0;
    while (i < 30) : (i += 1) {
        loaders.sleepMs(io, 60);
    }
    seq.completeStep(build, .{ .final_text = "3.2s" });

    try seq.startStep(test_step);
    const bar = seq.barOf(test_step);
    i = 0;
    while (i <= 100) : (i += 10) {
        bar.setProgress(i);
        loaders.sleepMs(io, 40);
    }
    seq.completeStep(test_step, .{});

    try seq.startStep(deploy);
    i = 0;
    while (i < 15) : (i += 1) {
        loaders.sleepMs(io, 60);
    }
    seq.completeStep(deploy, .{});

    seq.printSummary();
    loaders.showCursor(io);
}