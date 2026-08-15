---
title: ProgressBar API
description: ProgressBar API reference — config, methods, callbacks, and thread modes.
---

# Progress Bar

```zig
const bar = try loaders.ProgressBar.init(allocator, io, config);
```

## Config

```zig
pub const ProgressBarConfig = struct {
    total: u64,                         // required
    current: u64 = 0,
    min_progress: u64 = 0,
    width: u32 = 40,
    style: CustomBarStyle = .{},
    template: []const u8 = "{bar} {percent}%",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,          // ANSI string or color.toFg()
    text_style: FontStyle = .{},
    formatters: FormatterSet = .{},
    thread_mode: ThreadMode = .none,    // .none | .auto | .external
    interval_ms: u32 = 16,
    direction: Direction = .incremental,
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    on_pause: ?Callback = null,
    on_resume: ?Callback = null,
    ctx: ?*anyopaque = null,            // passed to callbacks
};
```

### CustomBarStyle

```zig
pub const CustomBarStyle = struct {
    filled: []const u8 = "#",
    empty: []const u8 = "-",
    head: []const u8 = ">",
    left_bracket: []const u8 = "[",
    right_bracket: []const u8 = "]",
    partial_fill: ?[]const []const u8 = null,  // per-char partial fills
};
```

### Callback

```zig
pub const Callback = *const fn (ctx: ?*anyopaque) void;
```

## State

```zig
pub const ProgressState = struct {
    progress: u64,
    total: u64,
    percent: f64,
    elapsed_ns: u64,
    eta_ns: u64,
    speed: f64,
    status: Status,   // pending | running | paused | finished | failed
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) InitError!ProgressBar` | Create; `error.MissingFormatter` if the template needs a missing formatter. |
| `deinit()` | Stop the render thread (if any). |
| `start() !void` | Start the clock; no-op if already running. |
| `tick()` | Increment progress by 1 (clamped at `total`); auto-starts if pending. |
| `setProgress(value)` | Set absolute progress; auto-starts if pending. |
| `pause()` | Pause the clock. |
| `continue_()` | Resume the clock. |
| `forceRedraw()` | Force an immediate redraw. |
| `finish(FinishConfig)` | Finish with `{ clear, final_text, newline }`. |
| `fail(message)` | Mark failed and render the message. |
| `setText(text)` / `setPrefix(prefix)` / `setSuffix(suffix)` | Update text parts. |
| `setColor(?[]const u8)` | Update color at runtime. |
| `setStyle(CustomBarStyle)` | Swap characters at runtime. |
| `setTemplate(template) !void` | Swap template at runtime (validated). |
| `state() ProgressState` | Snapshot of progress/total/percent/elapsed/eta/speed/status. |
| `getStatus() Status` | Current status. |
| `getCurrent() u64` | Current progress value. |
| `setDrawOnUpdate(bool)` | Disable auto-redraw (render only on demand). |
| `redrawLine()` | Redraw the current line unconditionally. |
| `finishNow()` | Finish without redraw or newline. |

## Example

```zig
var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 100,
    .style = .{ .filled = "#", .empty = "-" },
    .template = "{bar} {percent}%",
    .text = "Processing",
    .color = loaders.fg(.{ .ansi4 = .green }),
});
defer bar.deinit();

bar.setProgress(50);
loaders.sleepMs(io, 30);
bar.finish(.{ .newline = true });
```