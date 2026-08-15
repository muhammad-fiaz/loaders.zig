---
title: BatchRunner API
description: BatchRunner API reference — process items with per-item and overall progress bars.
---

# Batch Runner

`BatchRunner` processes a slice of items while rendering a per-item bar and (optionally) an overall bar.

```zig
const batch = try loaders.BatchRunner.init(allocator, io, config);
```

## Config

```zig
pub const BatchConfig = struct {
    mode: Mode = .sequential,           // .sequential | .parallel
    show_overall_bar: bool = true,
    overall_bar_config: ?ProgressBarConfig = null,  // total is forced to items.len
    per_item_bar_config: ?ProgressBarConfig = null,
    max_workers: u32 = 4,
    interval_ms: u32 = 30,
    ctx: ?*anyopaque = null,
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) !BatchRunner` | Create. |
| `deinit()` | Clean up bars and threads. |
| `run(comptime Item: type, items: []const Item, worker) !void` | Process all items. |
| `itemBar() ?*ProgressBar` | Get the per-item bar (for worker-driven progress). |
| `overallBar() ?*ProgressBar` | Get the overall bar. |

### Worker signature

```zig
worker: *const fn (Item, ?*anyopaque) void
```

The second argument is `config.ctx`. Inside the worker, use the module-level `io` for sleeping:

```zig
var g_threaded: std.Io.Threaded = .init_single_threaded;

fn processItem(item: u32, ctx: ?*anyopaque) void {
    _ = ctx;
    terminal.sleepMs(g_threaded.io(), 50);
    _ = item;
}
```

> [!TIP]
> `overall_bar_config.total` is ignored — the overall bar always tracks `items.len`.

## Sequential Mode

In sequential mode, the runner automatically manages the per-item bar:
- Resets to 0% before each worker call
- Sets to 100% after the worker returns

```zig
var batch = try loaders.BatchRunner.init(allocator, io, .{
    .mode = .sequential,
    .show_overall_bar = true,
    .overall_bar_config = .{
        .style = .{ .filled = "#", .empty = "-" },
        .template = "Overall: {bar} {count}",
    },
});
defer batch.deinit();

const items = [_]u32{ 1, 2, 3, 4, 5 };
try batch.run(u32, &items, processItem);
```

## Parallel Mode

In parallel mode, multiple workers run simultaneously. The runner resets the per-item bar to 0% when dispatching a new item, but **does not** set it to 100% — the worker is responsible for driving progress incrementally via `itemBar()`.

```zig
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

### Worker-driven progress example

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
```

> [!NOTE]
> In parallel mode, all workers share a single `item_bar`. The bar shows the progress of whichever worker last updated it. When a new item starts, the bar resets to 0%.
