---
title: Spinner Examples
description: Spinner examples — frames, messages, Braille, and infinite spinners.
---

# Spinner Examples

## basic_spinner

Minimal spinner with `{frame} {text}`:

```bash
zig build run-basic_spinner
```

```zig
var sp = try loaders.Spinner.init(allocator, io, .{
    .frames = &.{ "|", "/", "-", "\\" },
    .template = "{frame} {text}",
    .text = "Loading",
});
```

## dynamic_spinner_messages

`setText` / `setColor` mid-run:

```bash
zig build run-dynamic_spinner_messages
```

## spinner_looping_messages

Cycle through a list of messages:

```bash
zig build run-spinner_looping_messages
```

## spinner_conditional_messages

Change text based on elapsed time or phase:

```bash
zig build run-spinner_conditional_messages
```

## infinite_spinner

Auto-threaded spinner that runs until `stop`:

```bash
zig build run-infinite_spinner
```

```zig
var sp = try loaders.Spinner.init(allocator, io, .{
    .frames = &.{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    .thread_mode = .auto,
});
defer sp.deinit();
try sp.start();
// ... long-running work ...
sp.stop(.{ .final_text = "Complete", .newline = true });
```

## spinner_braille

Braille dot spinner frames:

```bash
zig build run-spinner_braille
```

```zig
.frames = &.{ "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
```
