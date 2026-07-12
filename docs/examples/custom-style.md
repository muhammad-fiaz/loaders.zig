---
description: Custom BarStyle with green fill, arrow tip, and bold attributes in loaders.zig.
head:
  - - meta
    - name: keywords
      content: loaders.zig custom style, zig bar customization, custom progress bar
  - - meta
    - property: og:title
      content: Custom Style Example — loaders.zig
  - - meta
    - property: og:description
      content: Custom BarStyle with green fill, arrow tip, and bold attributes.
---

# Custom Style

Custom `BarStyle` with `=` fill, `>` tip, green color, and bold attribute.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const custom_bar_style = loaders.BarStyle{
        .left_bracket = "[",
        .right_bracket = "]",
        .fill = "=",
        .tip = ">",
        .empty = "-",
        .fill_fg = .green,
        .empty_fg = .bright_black,
        .attrs = &.{.bold},
    };

    var bar = loaders.ProgressBar.init(io, .{
        .label = "Customizing",
        .total = 200,
        .style = custom_bar_style,
        .show_percent = true,
        .show_elapsed = true,
        .show_count = true,
    });
    defer bar.done();

    for (0..200) |_| {
        bar.increment();
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(15), .awake);
    }
}
```

## Run

```bash
zig build run-custom_style
```

## Output

```
Customizing [=========================>--------------]  60% 120/200 00:03
```
