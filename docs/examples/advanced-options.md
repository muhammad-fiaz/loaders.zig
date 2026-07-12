---
description: Advanced progress customization with decorators, timestamps, colored labels, responsive width, and dynamic messages in loaders.zig.
head:
  - - meta
    - name: keywords
      content: loaders.zig advanced options, zig progress bar decorators, colored progress bar, zig timestamps
  - - meta
    - property: og:title
      content: Advanced Options Example — loaders.zig
  - - meta
    - property: og:description
      content: Advanced progress customization with decorators, timestamps, and colored labels.
---

# Advanced Options

Custom decorators, timestamps, colored labels, responsive width, and dynamic messages.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const total_steps = 100;

    var bar = loaders.ProgressBar.init(io, .{
        .total = total_steps,
        .label = "Processing",
        .color = .bright_cyan,
        .show_percent = true,
        .show_count = true,
        .show_elapsed = true,
        .show_eta = true,
        .show_rate = true,
        .message = "initializing...",
        .complete_message = "Done! All steps complete.",

        .custom_start = "🚀 ",
        .custom_end = " [Task #1]",

        .show_date = false,
        .show_time = true,
        .timezone_offset_sec = 19800,

        .width = 0,
        .style = loaders.BarStyle.gradient,
    });
    defer bar.done();

    for (0..total_steps) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(80), .awake);
    }
}
```

## Run

```bash
zig build run-advanced_options
```

## Output

```
🚀 [17:19:41] Processing [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100% 100/100 00:08 12.5/s initializing... [Task #1]
🚀 [17:19:41] Processing [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100% 100/100 00:08 12.5/s Done! All steps complete. [Task #1]
```

Key features demonstrated:
- `custom_start` / `custom_end` — line decorators
- `show_time` + `timezone_offset_sec` — local time prefix
- `color` — colors the entire progress bar line
- `message` / `complete_message` — dynamic text before/after completion
- `width = 0` — auto-resizes to terminal width
