---
title: Indeterminate API
description: Indeterminate API reference — sliding segment for unknown progress.
---

# Indeterminate

An `Indeterminate` renders a sliding segment across the track — use it when total progress is unknown.

```zig
const ind = try loaders.Indeterminate.init(allocator, io, config);
```

## Config

```zig
pub const IndeterminateConfig = struct {
    segment_width: u32 = 10,
    width: u32 = 40,
    style: IndeterminateStyle = .{},
    template: []const u8 = "{bar}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,
    text_style: FontStyle = .{},
    formatters: FormatterSet = .{},
    interval_ms: u32 = 80,
    thread_mode: ThreadMode = .none,
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    ctx: ?*anyopaque = null,
};
```

### IndeterminateStyle

```zig
pub const IndeterminateStyle = struct {
    filled: []const u8 = ".",
    head: []const u8 = ">",
    left_bracket: []const u8 = "[",
    right_bracket: []const u8 = "]",
};
```

## State

```zig
pub const IndeterminateState = struct {
    position: u32,      // current segment position
    elapsed_ns: u64,
    status: Status,
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) InitError!Indeterminate` | Create. |
| `deinit()` | Stop the render thread (if any). |
| `start() !void` | Start the clock and (in `.auto`) the render thread. |
| `tickFrame()` | Move the segment; auto-starts if pending. |
| `forceRedraw()` | Force an immediate redraw. |
| `pause()` / `continue_()` | Pause / resume the clock. |
| `stop(FinishConfig)` | Finish with `{ clear, final_text, newline }`. |
| `fail(message)` | Mark failed. |
| `setText(text)` / `setColor(?[]const u8)` / `setTemplate(template) !void` | Runtime updates. |
| `state() IndeterminateState` | Snapshot of position, elapsed, status. |
| `getStatus() Status` | Current status. |
| `setDrawOnUpdate(bool)` / `redrawLine()` / `finishNow()` | Low-level rendering control. |

## Example

```zig
var ind = try loaders.Indeterminate.init(allocator, io, .{
    .template = "{bar} {text}",
    .text = "Working...",
    .thread_mode = .auto,
});
defer ind.deinit();

loaders.sleepMs(io, 5000);
ind.stop(.{ .newline = true });
```