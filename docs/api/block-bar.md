---
title: BlockProgressBar API
description: BlockProgressBar API reference — Unicode block elements with partial fills.
---

# Block Bar

A `BlockProgressBar` is a `ProgressBar` with block characters (`█`) and partial fills (`▏▎▍▌▋▊▉`) for smooth sub-character progress.

```zig
const bar = try loaders.BlockProgressBar.init(allocator, io, config);
```

## Config

```zig
pub const BlockBarConfig = struct {
    total: u64,                         // required
    current: u64 = 0,
    minProgress: u64 = 0,
    width: u32 = 40,
    style: BlockBarStyle = .{},
    template: []const u8 = "{bar} {percent}%",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?Sequence = null,
    textStyle: FontStyle = .{},
    formatters: FormatterSet = .{},
    threadMode: ThreadMode = .none,
    intervalMs: u32 = 16,
    direction: Direction = .incremental,
    onTick: ?Callback = null,
    onFinish: ?Callback = null,
    onPause: ?Callback = null,
    onUnpause: ?Callback = null,
    ctx: ?*anyopaque = null,
};
```

### BlockBarStyle

```zig
pub const BlockBarStyle = struct {
    filled: []const u8 = "█",
    empty: []const u8 = " ",
    leftBracket: []const u8 = "",
    rightBracket: []const u8 = "",
};
```

Partial fills are always the block-partial set `▏▎▍▌▋▊▉`.

## Methods

Same as [ProgressBar](/api/progress-bar) minus `setStyle`:

`init`, `deinit`, `start`, `tick`, `setProgress`, `pause`, `unpause`, `forceRedraw`, `finish(FinishConfig)`, `fail(message)`, `setText`, `setPrefix`, `setSuffix`, `setColor`, `setTemplate`, `state() BlockState`, `getStatus`, `getCurrent`.

## Example

```zig
var bar = try loaders.BlockProgressBar.init(allocator, io, .{
    .total = 100,
    .width = 30,
    .template = "{bar} {percent}%",
    .text = "Uploading",
});
defer bar.deinit();

var i: u64 = 0;
while (i <= 100) : (i += 1) {
    bar.setProgress(i);
    loaders.sleepMs(io, 30);
}
bar.finish(.{ .newline = true });
```