---
title: Spinner API
description: Spinner API reference — config, frames, templates, and thread modes.
---

# Spinner

```zig
const sp = try loaders.Spinner.init(allocator, io, config);
```

## Config

```zig
pub const SpinnerConfig = struct {
    frames: []const []const u8,         // required, e.g. &.{ "|", "/", "-", "\\" }
    template: []const u8 = "{frame} {text}",
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    color: ?[]const u8 = null,          // raw ANSI escape sequence
    text_style: FontStyle = .{},
    formatters: FormatterSet = .{},
    interval_ms: u32 = 80,
    thread_mode: ThreadMode = .none,    // .none | .auto | .external
    show_spinner: bool = true,          // hide the frame character when false
    on_tick: ?Callback = null,
    on_finish: ?Callback = null,
    ctx: ?*anyopaque = null,
};
```

## State

```zig
pub const SpinnerState = struct {
    frame_index: u64,
    frame: []const u8,                  // current frame string
    elapsed_ns: u64,
    status: Status,
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) InitError!Spinner` | Create; `error.MissingFormatter` on invalid template. |
| `deinit()` | Stop the render thread (if any). |
| `start() !void` | Start the clock and (in `.auto`) the render thread. |
| `tickFrame()` | Advance to the next frame; auto-starts if pending. |
| `setProgress(value)` | Set absolute frame index. |
| `getCurrent() u64` | Current frame index. |
| `forceRedraw()` | Force an immediate redraw. |
| `pause()` / `continue_()` | Pause / resume the clock. |
| `stop(FinishConfig)` | Finish with `{ clear, final_text, newline }`. |
| `fail(message)` | Mark failed and render the message. |
| `setText(text)` | Update text at runtime. |
| `setColor(?[]const u8)` | Update color at runtime. |
| `setFrames(frames)` | Swap frame sequences at runtime. |
| `setTemplate(template) !void` | Swap template at runtime (validated). |
| `state() SpinnerState` | Snapshot of frame index, frame, elapsed, status. |
| `getStatus() Status` | Current status. |
| `setDrawOnUpdate(bool)` | Disable auto-redraw. |
| `redrawLine()` | Redraw unconditionally. |
| `finishNow()` | Finish without redraw or newline. |

## Example

```zig
var sp = try loaders.Spinner.init(allocator, io, .{
    .frames = &.{ "|", "/", "-", "\\" },
    .template = "{frame} {text}",
    .text = "Loading",
});
defer sp.deinit();

try sp.start();
loaders.sleepMs(io, 2000);
sp.stop(.{ .final_text = "Done!", .newline = true });
```