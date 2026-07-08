---
description: Deep dive into using, configuring, and updating single progress bars with loaders.Bar. Covers lifecycle, increment methods, indeterminate mode, auto-sizing, and decorators.
head:
  - - meta
    - name: keywords
      content: loaders.zig progress bar, zig progress bar, determinate progress, indeterminate progress, zig loading bar
  - - meta
    - property: og:title
      content: Progress Bars Guide — loaders.zig
  - - meta
    - property: og:description
      content: Deep dive into using, configuring, and updating single progress bars with loaders.Bar.
---

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
- **`color`**: Colors the entire progress bar line (e.g. `.yellow`). Specific overrides like `fill_color` or `label_color` take precedence.

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
    .color = .cyan, // colors the entire progress bar line cyan
    .width = 0, // auto-responsive resizing
});
```

This renders as:
`🚀 [2026-05-26 17:19:41] Processing Task [██████████] 100% 100/100 00:09 [Thread: #1]`

---

## 6. Custom Icons and Completion Statuses

You can configure optional running icons and dynamic completion status icons on progress bars:

- **`icon`**: Running icon prefix (e.g. `"🚀"`) printed at the beginning of the line.
- **`success_icon`**: Custom status icon on success (defaults to `"✓"`).
- **`failure_icon`**: Custom status icon on failure (defaults to `"✗"`).
- **`warning_icon`**: Custom status icon on warning (defaults to `"⚠"`).
- **`info_icon`**: Custom status icon on info (defaults to `"ℹ"`).

### Completion Status Methods

Instead of standard `done()`, you can call dynamic completion methods when your progress bar reaches the end:

- **`bar.succeed(msg)`**: Renders success status, stops the bar, and updates the message to `msg`.
- **`bar.fail(msg)`**: Renders failure status, stops the bar, and updates the message.
- **`bar.warn(msg)`**: Renders warning status, stops the bar, and updates the message.
- **`bar.info(msg)`**: Renders info status, stops the bar, and updates the message.

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .icon = "🚀",
    .success_icon = "✨",
});

// perform work
bar.succeed("Deployment complete!");
```

---

## 7. Dynamic Message Cycling (Humor Messages / Loading Loops)

You can pass a list of messages to the progress bar options to automatically cycle through them at a set interval during active loading:

- **`messages`**: Slice of string messages (e.g. `&[_][]const u8 { "Feeding hamsters...", "Reticulating splines..." }`).
- **`icon_messages`**: Slice of `Message` structures with custom per-message text and icons (e.g. `&[_]loaders.Message { .{ .text = "Feeding hamsters...", .icon = "🐹" } }`).
- **`message_interval_ms`**: Duration in milliseconds to show each message (defaults to `1500`).

```zig
const humor_msgs = [_]loaders.Message{
    .{ .text = "Feeding hamsters...", .icon = "🐹" },
    .{ .text = "Brewing coffee...", .icon = "☕" },
};

var bar = loaders.Bar.init(io, .{
    .total = 100,
    .label = "Processing",
    .icon_messages = &humor_msgs,
    .message_interval_ms = 400,
});
```

---

## 8. Progress and Completion Callbacks

`loaders.Bar` supports registering callback functions to execute custom logic on progress updates and bar completion:

- **`on_progress`**: Fired whenever `completed` is updated (via `setCompleted`, `increment`, `incrementBy`). Function signature: `fn(bar: *loaders.Bar, completed: usize, total: usize) void`.
- **`on_complete`**: Fired exactly once when `completed` reaches or exceeds `total`, or when a stop method (`done`, `succeed`, `fail`, etc.) is called. Function signature: `fn(bar: *loaders.Bar) void`.
- **`on_success`**: Fired when `succeed()` is called. Function signature: `fn(bar: *loaders.Bar) void`.
- **`on_failure`**: Fired when `fail()` is called. Function signature: `fn(bar: *loaders.Bar) void`.
- **`on_warn`**: Fired when `warn()` is called. Function signature: `fn(bar: *loaders.Bar) void`.
- **`on_info`**: Fired when `info()` is called. Function signature: `fn(bar: *loaders.Bar) void`.

### Example

```zig
const cb_struct = struct {
    pub fn onProgress(bar: *loaders.Bar, completed: usize, total: usize) void {
        // Custom progress reporting logic
    }
    pub fn onComplete(bar: *loaders.Bar) void {
        std.debug.print("Task finished callback triggered!\n", .{});
    }
    pub fn onSuccess(bar: *loaders.Bar) void {
        std.debug.print("Task succeeded!\n", .{});
    }
    pub fn onFailure(bar: *loaders.Bar) void {
        std.debug.print("Task failed!\n", .{});
    }
};

var bar = loaders.Bar.init(io, .{
    .total = 100,
    .on_progress = cb_struct.onProgress,
    .on_complete = cb_struct.onComplete,
    .on_success = cb_struct.onSuccess,
    .on_failure = cb_struct.onFailure,
});
```

---

## 9. 12-Hour Time and Visual Width Truncation Controls

To prevent screen overflow or text wrapping when labels, messages, or suffixes are exceptionally long, `loaders.Bar` offers explicit width truncation controls:

- **`time_format_12h`**: When `true`, formats date/time prefixes using a 12-hour AM/PM format (e.g. `[2026-05-26 05:19:41 PM]`).
- **`max_label_width`**: Sets the maximum number of visual terminal columns occupied by the label. Excess characters are safely truncated and appended with `…`.
- **`max_message_width`**: Sets the maximum number of visual terminal columns occupied by the active message.
- **`max_suffix_width`**: Sets the maximum number of visual terminal columns occupied by the suffix.

### Example
```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .label = "Super Long Label That Might Overflow The Screen",
    .max_label_width = 15, // Truncated to 15 columns: "Super Long Labe…"
    .message = "Initialising and downloading dependencies from local cache server...",
    .max_message_width = 25, // Truncated to 25 columns: "Initialising and downloa..."
    .show_time = true,
    .time_format_12h = true, // Outputs AM/PM format
});
```

---

## 10. Customizable Spacing Gaps and Padding

To prevent overlapping on wide-glyph emoji renderings or customize layout, you can override default spacing gaps and add padding lines:

### Spacing Gaps

- **`icon_gap`**: Spacing printed after prefix/status icons (defaults to `" "`).
- **`label_gap`**: Spacing printed after the label (defaults to `" "`).
- **`datetime_gap`**: Spacing printed after the date/time prefix brackets (defaults to `" "`).

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .icon = "🛡️",
    .icon_gap = "   ", // explicit wide gap after shield emoji
    .label = "Processing",
    .label_gap = "  ",
});
```

### Padding Lines

Add empty lines above or below the bar for visual spacing in multi-bar layouts:

- **`padding_lines_above`**: Number of empty lines printed above the bar (defaults to `0`).
- **`padding_lines_below`**: Number of empty lines printed below the bar (defaults to `0`).

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .label = "Task A",
    .padding_lines_above = 1, // one blank line above
    .padding_lines_below = 1, // one blank line below
});
```

---

## 11. Gradients and Completion Colors

### Gradient Rendering

Progress bars support gradient-based color rendering where each filled or empty character gets a smoothly interpolated color from a gradient palette. This creates visually stunning rainbow, fire, ocean, and other gradient effects.

**Using gradients via `BarOptions` shorthands:**

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .fill_gradient = loaders.Gradient.rainbow,  // Rainbow gradient on filled portion
    .empty_gradient = loaders.Gradient.ocean,    // Ocean gradient on empty portion
});
```

**Using gradients via `BarStyle`:**

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .style = .{
        .fill_gradient = loaders.Gradient.fire,
        .empty_gradient = loaders.Gradient.ice,
    },
});
```

### Built-in Gradient Presets

| Preset | Description |
|--------|-------------|
| `Gradient.rainbow` | Full rainbow spectrum (red → yellow → green → cyan → blue → magenta) |
| `Gradient.fire` | Warm fire tones (dark red → orange → yellow → white) |
| `Gradient.ocean` | Cool ocean blues (dark blue → teal → cyan → white) |
| `Gradient.sunset` | Sunset warmth (purple → red → orange → yellow) |
| `Gradient.neon` | Bright neon (magenta → cyan → green → yellow) |
| `Gradient.forest` | Forest greens (dark green → green → lime → yellow) |
| `Gradient.ice` | Icy blues (blue → cyan → white) |
| `Gradient.pastel` | Soft pastel rainbow |
| `Gradient.monochrome` | Black to white grayscale |
| `Gradient.rainbow_reversed` | Reversed rainbow (magenta → blue → cyan → green → yellow → red) |

### Custom Gradients

You can create custom gradients with any number of color stops:

```zig
const my_gradient = loaders.Gradient{
    .colors = &.{ .red, .yellow, .green },
};

var bar = loaders.Bar.init(io, .{
    .total = 100,
    .fill_gradient = &my_gradient,
});
```

The `Gradient.at(t)` method accepts a `f64` from `0.0` to `1.0` and returns the interpolated `Color` at that position.

### Completion Colors (`complete_fg`)

When a progress bar reaches 100% or is stopped via `succeed()`/`fail()`/etc., you can display the filled portion in a different color:

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .complete_color = .green,  // Shorthand: fills entire bar green on completion
});

// Or via style:
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .style = .{
        .complete_fg = .bright_green,
    },
});
```

When `complete_fg` is set, the entire filled portion renders in that color once the bar is complete (100% or stopped). This works alongside gradients — if `fill_gradient` is also set, the gradient takes precedence during progress, and `complete_fg` takes over on completion.



