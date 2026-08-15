const std = @import("std");
const loaders = @import("loaders");

const WorkItem = struct {
    name: []const u8,
    work: u64,
};

fn worker(item: WorkItem, ctx: ?*anyopaque) void {
    const bar: *loaders.ProgressBar = @ptrCast(@alignCast(ctx orelse return));
    var i: u64 = 0;
    while (i < item.work) : (i += 1) {
        bar.setPrefix(item.name);
        bar.setText(switch (i % 3) {
            0 => "compressing",
            1 => "hashing",
            else => "writing",
        });
        loaders.sleepMs(g_threaded.io(), 5);
    }
}

var g_threaded: std.Io.Threaded = .init_single_threaded;
pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    const items = [_]WorkItem{
        .{ .name = "assets", .work = 20 },
        .{ .name = "src", .work = 30 },
        .{ .name = "docs", .work = 15 },
        .{ .name = "tests", .work = 25 },
    };

    var batch = try loaders.BatchRunner.init(allocator, io, .{
        .mode = .sequential,
        .show_overall_bar = true,
        .overall_bar_config = .{
            .total = 4,
            .style = .{ .filled = "#", .empty = "-" },
            .template = "Overall: {bar} {count} | {text}",
            .text = "starting",
        },
        .per_item_bar_config = .{
            .total = 1,
            .style = .{ .filled = "=", .empty = " " },
            .template = "  {prefix}: {bar} {percent}%",
        },
    });
    defer batch.deinit();

    try batch.run(WorkItem, &items, worker);
    loaders.showCursor(io);
}
