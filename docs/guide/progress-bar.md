# Progress Bars Guide

This article provides a deep dive into using, configuring, and updating single progress bars with `loaders.Bar`.

---

## 1. Initialisation and Lifecycle

A progress bar is created using `loaders.Bar.init(io, opts)`. The returned struct contains internal states (timers, atomic completed counters, term constraints). It is safe to stack-allocate or heap-allocate this structure.

When the rendering loop finishes, you **must** call `bar.done()` to clean up terminal cursor states and write the final carriage return newline:

```zig
var bar = loaders.Bar.init(io, .{
    .label = "Processing",
    .total = 100,
});
defer bar.done();
```

---

## 2. Incrementing Completed States

`loaders.Bar` supports highly flexible thread-safe updates:

- **`bar.setCompleted(n)`**: Explicitly sets completed count to a specific value.
- **`bar.increment()`**: Increments the completed count by 1.
- **`bar.incrementBy(n)`**: Increments the completed count by `n`.

All mutation methods perform atomic updates (`.release`), making it completely safe to call them from parallel worker threads or background tasks while a main thread triggers `bar.render()`.

---

## 3. Indeterminate Progress

If you are performing work where the total count is unknown (e.g. streaming an unknown number of chunks over a TCP socket), set `.total = 0`:

```zig
var bar = loaders.Bar.init(io, .{
    .label = "Downloading stream",
    .total = 0, // Indeterminate progress
});
```

In indeterminate mode, the bar renders as a bouncing tip or simple active spinner that slides back and forth, indicating that the program is active and processing without showing arbitrary percentages.

---

## 4. Automatic Column Sizing and Resizing Responsiveness

By default, `.width = 0`. This instructs `loaders.zig` to check the terminal column width dynamically (using POSIX `ioctl` or Windows `GetConsoleScreenBufferInfo`). 

The library re-queries the terminal columns dynamically on every single frame rendering. If a user resizes their terminal window mid-run, the bar dynamically and smoothly resizes itself in real-time to fit the new boundaries without any screen overflow.

---

## 5. Advanced Customizations: Local Date, Time, and Decorators

`loaders.zig` provides advanced options for prepending dates, times, and custom decorators around your progress lines:

- **`custom_start`**: A string printed at the absolute beginning of the line (e.g. `"🚀 "`).
- **`custom_end`**: A string printed at the absolute end of the line (e.g. `" [Task: A]"`).
- **`show_date`**: Prepends the current calendar date (`[YYYY-MM-DD]`).
- **`show_time`**: Prepends the current calendar time (`[HH:MM:SS]`).
- **`timezone_offset_sec`**: Shifts the UTC clock time to your local timezone (e.g. `19800` shifts UTC by +5:30 to match IST local time).

### Example Configuration

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .label = "Processing Task",
    .show_percent = true,
    .show_elapsed = true,
    .custom_start = "🚀 ",
    .custom_end = " [Thread: #1]",
    .show_date = true,
    .show_time = true,
    .timezone_offset_sec = 19800, // shifts clock by +5:30
    .width = 0, // auto-responsive resizing
});
```

This renders as:
`🚀 [2026-05-26 17:19:41] Processing Task [██████████] 100% 100/100 00:09 [Thread: #1]`

