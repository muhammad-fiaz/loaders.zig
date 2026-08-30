---
title: Getting Started
description: Install loaders.zig and create your first progress bar or spinner in minutes.
---

# Getting Started

## Prerequisites

- **Zig 0.16.0** or newer
- Windows, Linux, or macOS terminal

## Installation

### Stable Release (Production)

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.5.tar.gz
```

### Nightly (Latest Main Branch)

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
```

Then wire the dependency into your `build.zig`:

```zig
const loaders = b.dependency("loaders", .{});
exe.root_module.addImport("loaders", loaders.module("loaders"));
```

## Your First Progress Bar

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{bar} {percent}%",
        .text = "Processing",
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 30);
    }
    bar.finish(.{ .newline = true });
}
```

## Your First Spinner

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

## Core Concepts

### Thread Modes

Every widget accepts a `thread_mode`:

| Mode | Description |
|------|-------------|
| `.none` | **Manual.** You drive rendering by calling `setProgress` / `tick` / `tickFrame`. |
| `.auto` | **Background thread.** A render thread redraws the widget at `interval_ms` until it finishes. |
| `.external` | **Caller-driven.** You update from an external thread; the widget renders on each update. |

### Auto-Start

Bars and spinners left in the `.pending` state start automatically on the first update:

```zig
bar.setProgress(10);   // starts the clock if pending
bar.tick();            // also auto-starts
sp.tickFrame();        // also auto-starts
```

### Finish Config

`finish` / `stop` / `completeStep` accept a `FinishConfig`:

```zig
pub const FinishConfig = struct {
    clear: bool = false,          // erase the last rendered line
    final_text: ?[]const u8 = null, // replace the widget with this text
    newline: bool = true,         // move to a new line after finishing
};
```

### Writing Output After a Widget

After a bar/spinner has finished, use `loaders.stdoutWriter(io)` to write plain lines:

```zig
const w = loaders.stdoutWriter(io);
w.writeAll("all done!\n") catch {};
```

> [!IMPORTANT]
> `stdoutWriter` returns a **pointer** to the shared stdout writer. Do not copy `*std.Io.Writer` values or `.interface` fields — the internal writer relies on pointer identity (see [Terminal Helpers](/api/terminal)).

### Colors

Colors use tint.zig — pass `color.toFg()` or use the convenience functions:

```zig
.color = loaders.fg(.{ .ansi4 = .green })           // ANSI 4-bit green
.color = loaders.makeRgb(34, 197, 94).toFg()        // RGB (TrueColor)
.color = loaders.makeHex(0x22C55E).toFg()           // HEX color
.color = loaders.makeAnsi256(129).toFg()            // ANSI 256-color
.color = loaders.fg(.{ .named = .red })             // CSS named color
.color = null                                        // no color
```

Update colors at runtime with `bar.setColor(...)` / `sp.setColor(...)`.

> [!CAUTION]
> On Windows, Unicode characters (Braille, emoji) require UTF-8 console encoding. loaders.zig enables this automatically.

## Next Steps

- Explore the [examples](/examples/) to see every feature in action.
- Read the [API reference](/api/) for the full surface.