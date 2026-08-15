---
title: Multi & Batch Examples
description: MultiBar and BatchRunner examples — parallel and sequential processing.
---

# Multi & Batch Examples

## multi_bar_sequential

`MultiBar` in sequential mode — trackers render one after another:

```bash
zig build run-multi_bar_sequential
```

## multi_bar_parallel

`MultiBar` in parallel mode — all trackers render at once:

```bash
zig build run-multi_bar_parallel
```

## batch_sequential

`BatchRunner` over a slice with an overall bar:

```bash
zig build run-batch_sequential
```

```zig
var batch = try loaders.BatchRunner.init(allocator, io, .{
    .mode = .sequential,
    .show_overall_bar = true,
});
defer batch.deinit();

const items = [_]u32{ 1, 2, 3, 4, 5 };
try batch.run(u32, &items, processItem);
```

## batch_parallel_downloads

Parallel workers (`max_workers`) with per-item + overall bars. The worker drives per-item progress incrementally via `itemBar()`:

```bash
zig build run-batch_parallel_downloads
```

```zig
const WorkerCtx = struct {
    batch: *loaders.BatchRunner,
};

fn downloadWorker(item: DownloadItem, ctx: ?*anyopaque) void {
    const c: *WorkerCtx = @ptrCast(@alignCast(ctx orelse return));
    const bar = c.batch.itemBar() orelse return;
    const total = item.size;
    var downloaded: u64 = 0;
    while (downloaded < total) : (downloaded += 1) {
        bar.setProgress(downloaded);
        loaders.sleepMs(g_threaded.io(), 2);
    }
    bar.setProgress(total);
}

// In main():
var batch = try loaders.BatchRunner.init(allocator, io, .{
    .mode = .parallel,
    .max_workers = 4,
    .show_overall_bar = true,
    .overall_bar_config = .{
        .total = 8,
        .style = .{ .filled = "=", .empty = " " },
        .template = "Downloading: {bar} {count}",
    },
    .per_item_bar_config = .{
        .total = 200,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "  Current item: {bar} {percent}%",
    },
});
defer batch.deinit();

var ctx = WorkerCtx{ .batch = &batch };
batch.config.ctx = @ptrCast(&ctx);
try batch.run(DownloadItem, &items, downloadWorker);
```

> [!NOTE]
> In parallel mode, the runner resets the per-item bar to 0% when dispatching a new item, but does **not** set it to 100% — the worker is responsible for driving progress via `batch.itemBar()`.

## batch_dynamic_messages

Workers update the item bar's text as they process:

```bash
zig build run-batch_dynamic_messages
```

> [!TIP]
> Worker functions receive `config.ctx` and need their own `io`. Use a module-level `var g_threaded: std.Io.Threaded = .init_single_threaded;` and `g_threaded.io()` inside workers.
