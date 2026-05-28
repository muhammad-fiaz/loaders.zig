---
description: Four concurrent progress bars with different styles, dynamic messages, and staggered completion using loaders.zig MultiBar.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi progress, zig concurrent progress bars, multi bar example
  - - meta
    - property: og:title
      content: Multi Progress Example — loaders.zig
  - - meta
    - property: og:description
      content: Four concurrent progress bars with different styles and dynamic messages.
---

# Multi Progress

4 concurrent progress bars with different styles, dynamic messages, and staggered completion.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null, .{
        .hide_cursor = true,
        .complete_message = "All tasks complete!",
    });

    const b1 = mb.addBar(.{
        .label = "Download",
        .total = 100,
        .show_percent = true,
        .show_rate = true,
        .unit_is_bytes = true,
        .style = loaders.BarStyle.cyan,
        .label_color = .cyan,
        .complete_message = "Downloaded",
    });
    const b2 = mb.addBar(.{
        .label = "Extract ",
        .total = 80,
        .show_percent = true,
        .show_elapsed = true,
        .style = loaders.BarStyle.green,
        .label_color = .green,
        .complete_message = "Extracted",
    });
    const b3 = mb.addBar(.{
        .label = "Install  ",
        .total = 60,
        .show_percent = true,
        .show_eta = true,
        .style = loaders.BarStyle.gradient,
        .label_color = .yellow,
        .percent_color = .yellow,
        .complete_message = "Installed",
    });
    const b4 = mb.addBar(.{
        .label = "Verify   ",
        .total = 40,
        .show_percent = true,
        .show_count = true,
        .style = loaders.BarStyle.neon,
        .bracket_color = .magenta,
        .complete_message = "Verified",
    });

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        b1.setCompleted(i + 1);
        if (i < 80) b2.setCompleted(i + 1);
        if (i < 60) b3.setCompleted(i + 1);
        if (i < 40) b4.setCompleted(i + 1);

        if (i < 50) {
            b1.setMessage("downloading...");
        } else {
            b1.setMessage("almost done");
        }

        mb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
    }

    mb.done();
}
```

## Run

```bash
zig build run-multi_progress
```

## Output

```
Download [██████████████████████████████████████████████████] 100% 1.0MiB/s Downloaded
Extract  [████████████████████████████████████████████████░░] 100% 00:08 Extracted
Install  [██████████████████████████████████████████████████] 100% ETA 00:00 Installed
Verify   [██████████████████████████████████████████████████] 100% 40/40 Verified
All tasks complete!
```

Bars complete at different rates (100, 80, 60, 40 steps). Dynamic message switches at 50%.
