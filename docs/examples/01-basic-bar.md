---
description: Minimal progress bar example with loaders.zig. Create a 50-step bar with percentage display in under 20 lines.
head:
  - - meta
    - name: keywords
      content: loaders.zig basic progress bar, zig progress bar example, minimal loading bar
  - - meta
    - property: og:title
      content: Basic Bar Example — loaders.zig
  - - meta
    - property: og:description
      content: Minimal progress bar example with loaders.zig. Create a 50-step bar with percentage display.
---

# Basic Bar

Minimal 50-step progress bar with percentage display.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const total: usize = 50;

    var bar = loaders.ProgressBar.init(io, .{
        .label = "Processing",
        .total = total,
        .show_percent = true,
    });
    defer bar.done();

    for (0..total) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(40), .awake);
    }
}
```

## Run

```bash
zig build run-01_basic_bar
```

## Output

```
Processing [██████████████████████████████████████████████████] 100%
```

The bar animates from 0% to 100%, overwriting the same line on each frame.
