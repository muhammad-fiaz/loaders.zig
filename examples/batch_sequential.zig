const std = @import("std");
const loaders = @import("loaders");

const DownloadItem = struct {
    url: []const u8,
    size: u64,
};

fn downloadWorker(item: DownloadItem, ctx: ?*anyopaque) void {
    _ = ctx;
    var i: u64 = 0;
    while (i < item.size / 10) : (i += 1) {
        loaders.sleepMs(g_threaded.io(), 1);
    }
}

var g_threaded: std.Io.Threaded = .init_single_threaded;
pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    const items = [_]DownloadItem{
        .{ .url = "file1.zip", .size = 1000 },
        .{ .url = "file2.zip", .size = 2000 },
        .{ .url = "file3.zip", .size = 500 },
        .{ .url = "file4.zip", .size = 4000 },
        .{ .url = "file5.zip", .size = 750 },
    };

    var batch = try loaders.BatchRunner.init(allocator, io, .{
        .mode = .sequential,
        .show_overall_bar = true,
        .overall_bar_config = .{
            .total = 5,
            .style = .{ .filled = "#", .empty = "-" },
            .template = "Overall: {bar} {count}",
        },
    });
    defer batch.deinit();

    try batch.run(DownloadItem, &items, downloadWorker);
    loaders.showCursor(io);
}
