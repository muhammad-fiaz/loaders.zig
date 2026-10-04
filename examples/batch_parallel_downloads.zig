const std = @import("std");
const loaders = @import("loaders");

const DownloadItem = struct {
    url: []const u8,
    size: u64,
};

var gThreaded: std.Io.Threaded = .init_single_threaded;

const WorkerCtx = struct {
    batch: *loaders.BatchRunner,
};

fn downloadWorker(item: DownloadItem, ctx: ?*anyopaque) void {
    const c: *WorkerCtx = @ptrCast(@alignCast(ctx orelse return));
    const bar = c.batch.getItemBar() orelse return;
    const total = item.size;
    var downloaded: u64 = 0;
    while (downloaded < total) : (downloaded += 1) {
        bar.setProgress(downloaded);
        loaders.sleepMs(gThreaded.io(), 2);
    }
    bar.setProgress(total);
}

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    loaders.hideCursor(io);
    const allocator = std.heap.page_allocator;

    const items = [_]DownloadItem{
        .{ .url = "file1.zip", .size = 200 },
        .{ .url = "file2.zip", .size = 100 },
        .{ .url = "file3.zip", .size = 150 },
        .{ .url = "file4.zip", .size = 50 },
        .{ .url = "file5.zip", .size = 180 },
        .{ .url = "file6.zip", .size = 80 },
        .{ .url = "file7.zip", .size = 120 },
        .{ .url = "file8.zip", .size = 60 },
    };

    var batch = try loaders.BatchRunner.init(allocator, io, .{
        .mode = .parallel,
        .maxWorkers = 4,
        .showOverallBar = true,
        .overallBarConfig = .{
            .total = 8,
            .style = .{ .filled = "=", .empty = " " },
            .template = "Downloading: {bar} {count}",
        },
        .perItemBarConfig = .{
            .total = 200,
            .style = .{ .filled = "#", .empty = "-" },
            .template = "  Current item: {bar} {percent}%",
        },
    });
    defer batch.deinit();

    var ctx = WorkerCtx{ .batch = &batch };
    batch.config.ctx = @ptrCast(&ctx);
    try batch.run(DownloadItem, &items, downloadWorker);
    loaders.showCursor(io);
}
