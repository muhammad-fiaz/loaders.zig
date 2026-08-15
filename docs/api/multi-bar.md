---
title: MultiBar API
description: MultiBar API reference — render multiple progress bars and spinners.
---

# Multi Bar

`MultiBar` renders multiple progress bars and spinners together, either sequentially or in parallel.

```zig
const mb = try loaders.MultiBar.init(allocator, io, config);
```

## Config

```zig
pub const MultiBarConfig = struct {
    mode: Mode = .parallel,   // .parallel | .sequential
    interval_ms: u32 = 30,
    hide_bar_when_complete: bool = false,  // hide finished/failed trackers
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) !MultiBar` | Create. |
| `deinit()` | Stop the render thread (if any). |
| `addBar(ProgressBarConfig) !usize` | Add a bar; returns its index. |
| `addSpinner(SpinnerConfig) !usize` | Add a spinner; returns its index. |
| `getBar(index) *ProgressBar` | Access a bar by index. |
| `getSpinner(index) *Spinner` | Access a spinner by index. |
| `count() usize` | Number of trackers. |
| `run() !void` | Start rendering all trackers. |
| `finishAll(FinishConfig)` | Finish every tracker. |

## Example

```zig
var mb = try loaders.MultiBar.init(allocator, io, .{
    .mode = .parallel,
});
defer mb.deinit();

_ = try mb.addBar(.{
    .total = 100,
    .style = .{ .filled = "#", .empty = "-" },
    .template = "Task A: {bar} {percent}%",
});
_ = try mb.addBar(.{
    .total = 100,
    .style = .{ .filled = "=", .empty = " " },
    .template = "Task B: {bar} {percent}%",
});
_ = try mb.addSpinner(.{
    .frames = &.{ "|", "/", "-", "\\" },
    .template = "{frame} {text}",
    .text = "Side task",
});

try mb.run();

const a = mb.getBar(0);
const b = mb.getBar(1);
// ... update a / b / spinner ...

mb.finishAll(.{ .newline = true });
```