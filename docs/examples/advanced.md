---
title: Advanced Examples
description: Advanced examples — formatters, runtime swaps, callbacks, and state.
---

# Advanced Examples

## template_with_eta_speed

`{elapsed}` / `{eta}` / `{speed}` with custom formatters:

```bash
zig build run-template_with_eta_speed
```

```zig
.formatters = .{
    .elapsed = formatElapsed,
    .eta = formatEta,
    .speed = formatSpeed,
},
```

## runtime_style_swap

Swap bar characters mid-run with `setStyle`:

```bash
zig build run-runtime_style_swap
```

## runtime_frame_swap

Swap spinner frames mid-run with `setFrames`:

```bash
zig build run-runtime_frame_swap
```

## pause_resume

`pause` / `continue_` freezing the clock:

```bash
zig build run-pause_resume
```

## text_updates

Dynamic text updates with `setText` / `setPrefix` / `setSuffix`:

```bash
zig build run-text_updates
```

## dynamic_messages

Text, color, and style changes driven by task phase:

```bash
zig build run-dynamic_messages
```

## infinite_progress_bar

Auto-threaded bar with no known total, stopped via `fail`:

```bash
zig build run-infinite_progress_bar
```

## clear_on_finish

`FinishConfig.clear` erases the bar line; post-run output via `stdoutWriter`:

```bash
zig build run-clear_on_finish
```

```zig
bar.finish(.{ .clear = true, .newline = true });

const w = loaders.stdoutWriter(io);
w.writeAll("completed\n") catch {};
```

## fail_and_status

`fail(message)` and `getStatus` checks:

```bash
zig build run-fail_and_status
```

## callback_hooks

`on_tick` / `on_finish` / `on_pause` / `on_resume` hooks with `ctx`:

```bash
zig build run-callback_hooks
```

```zig
var counts = Counters{};
var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 100,
    .on_tick = onTick,
    .on_finish = onFinish,
    .ctx = &counts,
});
```

## state_accessor

Reading `state()` snapshots (progress, percent, elapsed, eta, speed):

```bash
zig build run-state_accessor
```