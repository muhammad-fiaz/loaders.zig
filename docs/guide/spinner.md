---
description: Start, update, and manage thread-safe terminal spinners with loaders.Spinner. Background-threaded animation with finish states (succeed, fail, warn, info).
head:
  - - meta
    - name: keywords
      content: loaders.zig spinner, zig spinner, terminal spinner, background thread, async loading
  - - meta
    - property: og:title
      content: Spinners Guide — loaders.zig
  - - meta
    - property: og:description
      content: Start, update, and manage thread-safe terminal spinners with loaders.Spinner.
---

# Terminal Spinners Guide

This article explains how to start, update, and manage thread-safe terminal spinners.

---

## 1. Thread-Safe Architecture

Command-line programs often execute heavy synchronous operations (e.g. DNS resolution, disk writes, compression). If you try to update an animated loader in the same main loop, the animation will freeze during the heavy operation.

`loaders.Spinner` resolves this by spawning a lightweight **background render thread** when you call `start`. This thread runs a loop that periodically refreshes the spinner frame at the preset interval (e.g. every 80ms) and updates the message.

---

## 2. Basic Usage

```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Uploading data...",
    .style = loaders.SpinnerStyle.dots,
});
// perform work
try io.sleep(std.Io.Duration.fromSeconds(2), .awake);
```

---

## 3. Updating Text Mid-Run

Updating the spinner text is completely thread-safe and can be done from any thread at any time:

```zig
sp.setText("Connecting to server...");
// ...
sp.setText("Uploading database table A...");
// ...
sp.setText("Uploading database table B...");
```

---

## 4. Setting Finish States

When your work is done, you can stop the spinner and print a final status indicator in place of the spinner animation:

- **`sp.succeed(io, text)`**: Prints a green checkmark (✓) and your text, stops the animation, and destroys the spinner.
- **`sp.fail(io, text)`**: Prints a red crossmark (✗), ideal for failures.
- **`sp.warn(io, text)`**: Prints a yellow warning symbol (⚠).
- **`sp.info(io, text)`**: Prints a cyan info symbol (ℹ).
- **`sp.stop(io)`**: Erases the spinner line entirely from the terminal screen.

```zig
if (success) {
    sp.succeed(io, "All files uploaded successfully!");
} else {
    sp.fail(io, "Connection timeout: upload failed.");
}
```

Calling these methods automatically stops the render thread, cleans up memory, and frees the spinner pointer. No manual `stop` is needed if you call a status indicator method.

### Safe Resource Cleanup

Since status methods automatically clean up and destroy the spinner instance, using `defer sp.stop(io);` will cause a **double-free** on success. Instead, use the idiomatic Zig `errdefer` pattern to guarantee memory cleanup only on early error returns:

```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Processing...",
});
errdefer sp.stop(io);

// perform operations that might return an error
try performUnsafeOperation();

sp.succeed(io, "Completed!");
```

### Custom Prefix and Status Icons

You can configure a running prefix icon, custom color, and override the completion status symbols:

- **`color`**: Colors the entire spinner line (e.g. `.cyan`). Specific overrides like `text_color` or `spinner_color` take precedence.
- **`icon`**: Optional running icon (e.g. `"🔧"`) displayed before the spinner animation.
- **`success_icon`**: Custom symbol on success (e.g. `"🎉"`, defaults to `"✓"`).
- **`failure_icon`**: Custom symbol on failure (e.g. `"💥"`, defaults to `"✗"`).
- **`warning_icon`**: Custom symbol on warning (e.g. `"⚠️"`, defaults to `"⚠"`).
- **`info_icon`**: Custom symbol on info (e.g. `"📢"`, defaults to `"ℹ"`).

```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Initializing core system...",
    .icon = "🔧",
    .success_icon = "🎉",
    .color = .cyan, // colors the entire spinner line cyan
});
errdefer sp.stop(io);

// perform work
sp.succeed(io, "Initialization complete!");
```

### Dynamic Message Cycling (Humor Messages / Loading Loops)

You can pass a list of messages to the spinner options to automatically cycle through them at a set interval during active loading:

- **`messages`**: Slice of string messages (e.g. `&[_][]const u8 { "Feeding hamsters...", "Reticulating splines..." }`).
- **`icon_messages`**: Slice of `Message` structures with custom per-message text and icons (e.g. `&[_]loaders.Message { .{ .text = "Feeding hamsters...", .icon = "🐹" } }`).
- **`message_interval_ms`**: Duration in milliseconds to show each message (defaults to `1500`).

```zig
const spinner_msgs = [_]loaders.Message{
    .{ .text = "Searching for wifi...", .icon = "📡" },
    .{ .text = "Loading more RAM...", .icon = "💾" },
    .{ .text = "Asking the rubber duck...", .icon = "🦆" },
};

const sp = try loaders.Spinner.start(io, .{
    .style = loaders.SpinnerStyle.progress_pie,
    .icon_messages = &spinner_msgs,
    .message_interval_ms = 800,
});
```

### Sizing Limits and 12-Hour Time Format

To keep terminal layouts clean, you can constrain text and suffix widths and format dates in 12-hour format:

- **`time_format_12h`**: When `true`, formats date/time prefixes using a 12-hour AM/PM format (e.g. `[2026-05-26 05:19:41 PM]`).
- **`max_text_width`**: Restricts the visual column width of the active spinner text. Excess characters are truncated with a trailing `…`.
- **`max_suffix_width`**: Restricts the visual column width of the suffix.

### Example
```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Loading some extremely long resources that might stretch the terminal layout",
    .max_text_width = 30, // Truncates display to 30 columns: "Loading some extremely long res…"
    .show_time = true,
    .time_format_12h = true, // Outputs in 12-hour AM/PM format
});
```

### Customizable Spacing Gaps

Overriding standard space separators helps tailor alignments and accommodate wide-glyph emojis:

- **`icon_gap`**: String printed after prefix icons (defaults to `" "`).
- **`text_gap`**: String printed after the active spinner frame/status icon (defaults to `" "`).
- **`datetime_gap`**: String printed after date/time prefix brackets (defaults to `" "`).

```zig
const sp = try loaders.Spinner.start(io, .{
    .icon = "🛡️",
    .icon_gap = "  ",
    .text = "Initializing core module...",
    .text_gap = "   ", // wider spacing before status glyphs
});
```


