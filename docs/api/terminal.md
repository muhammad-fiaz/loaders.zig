---
title: Terminal Helpers
description: Terminal control — cursor, colors, sleep, and writer functions.
---

# Terminal Helpers

`loaders.zig` exports a set of terminal utilities from `src/terminal.zig`.

## Writing Output

```zig
pub fn stdoutWriter(io: std.Io) *std.Io.Writer
```

Returns a **pointer** to the shared stdout writer. Use it after a bar/spinner has finished to print plain lines:

```zig
const w = loaders.stdoutWriter(io);
w.writeAll("all done!\n") catch {};
```

> [!IMPORTANT]
> Do **not** copy the writer or its `.interface` field — the internal `std.Io.File.Writer` recovers its parent struct via `@fieldParentPtr`, so copies break pointer identity and crash. Always use the returned pointer directly.

## Sleep & Time

| Function | Description |
|----------|-------------|
| `loaders.sleepMs(io, ms)` | Sleep the current thread for `ms` milliseconds. |
| `loaders.timestampMs(io) i64` | Current monotonic timestamp in milliseconds. |

## Cursor & Line Control

| Function | Description |
|----------|-------------|
| `loaders.hideCursor(io)` | Hide the terminal cursor (restore with `showCursor`). |
| `loaders.showCursor(io)` | Show the terminal cursor. |
| `loaders.moveUp(io, lines)` | Move cursor up `lines`. |
| `loaders.moveDown(io, lines)` | Move cursor down `lines`. |
| `loaders.moveRight(io, cols)` | Move cursor right `cols`. |
| `loaders.moveLeft(io, cols)` | Move cursor left `cols`. |
| `loaders.eraseLine(io)` | Erase the current line. |

## Terminal Info

| Function | Description |
|----------|-------------|
| `loaders.getTerminalSize() TerminalSize` | Current size; `TerminalSize = struct { rows: u16, cols: u16 }`. |
| `loaders.ensureTerminal()` | Enables VT processing and UTF-8 output on Windows (called automatically on first use). |

## FontStyle

```zig
pub const FontStyle = struct {
    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    underline: bool = false,
    blink: bool = false,
    reverse: bool = false,
    strikethrough: bool = false,
    concealed: bool = false,

    pub fn toAnsi(self: FontStyle, buf: []u8) []const u8;
};
```

Apply text styles via the `text_style` config field:

```zig
.text_style = .{ .bold = true, .underline = true },
```

## Example

```zig
loaders.hideCursor(io);
defer loaders.showCursor(io);

var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 100,
});
defer bar.deinit();

var i: u64 = 0;
while (i <= 100) : (i += 1) {
    bar.setProgress(i);
    loaders.sleepMs(io, 10);
}
bar.finish(.{});

const w = loaders.stdoutWriter(io);
w.writeAll("finished\n") catch {};
```