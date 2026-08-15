---
title: Progress Bar Examples
description: Progress bar examples — styles, thread modes, Unicode, countdown, and variants.
---

# Progress Bar Examples

## basic_bar

Minimal bar with the default template `{bar} {percent}%`:

```bash
zig build run-basic_bar
```

## custom_ascii_bar

ASCII fill/empty/head characters:

```bash
zig build run-custom_ascii_bar
```

```zig
.style = .{ .filled = "#", .empty = "-", .head = ">" },
```

## custom_bracket_bar

Custom brackets and head:

```bash
zig build run-custom_bracket_bar
```

```zig
.style = .{ .left_bracket = "<", .right_bracket = ">", .head = "*" },
```

## block_bar

Block characters with partial fills (`▏▎▍▌▋▊▉`) via `loaders.BlockProgressBar`:

```bash
zig build run-block_bar
```

## indeterminate

Sliding segment for unknown progress via `loaders.Indeterminate`:

```bash
zig build run-indeterminate
```

## indeterminate_timeout

Indeterminate bar with timeout auto-stop:

```bash
zig build run-indeterminate_timeout
```

## manual_tick

Manual rendering — `thread_mode = .none` with explicit `tick()` calls:

```bash
zig build run-manual_tick
```

## auto_thread

Background-thread rendering — `thread_mode = .auto`:

```bash
zig build run-auto_thread
```

## external_thread

Updates from an external thread — `thread_mode = .external`:

```bash
zig build run-external_thread
```

## starting_value

Start at a `current` value and run in `direction = .decremental`:

```bash
zig build run-starting_value
```

## progress_bar_unicode

Unicode block characters with color:

```bash
zig build run-progress_bar_unicode
```

```zig
.style = .{ .filled = "█", .empty = "░", .head = "█" },
.color = loaders.fg(.{ .ansi4 = .cyan }),
```

## progress_bar_countdown

Countdown bar with decremental direction:

```bash
zig build run-progress_bar_countdown
```

## progress_bar_countdown_eta

Countdown with ETA and speed formatters:

```bash
zig build run-progress_bar_countdown_eta
```

```zig
.template = "{bar} {percent}% | Elapsed: {elapsed} ETA: {eta} | {speed}",
.formatters = .{
    .elapsed = formatElapsed,
    .eta = formatEta,
    .speed = formatSpeed,
},
```
