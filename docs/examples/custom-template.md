---
description: Dynamic label changes across 5 phases with custom bar style in loaders.zig. Shows label mutation at runtime.
head:
  - - meta
    - name: keywords
      content: loaders.zig dynamic label, zig progress bar phases, custom bar template
  - - meta
    - property: og:title
      content: Custom Template Example — loaders.zig
  - - meta
    - property: og:description
      content: Dynamic label changes across 5 phases with custom bar style.
---

# Custom Template

Bar label changes dynamically across 5 phases: Planning → Analyzing → Downloading → Installing → Verifying.

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const total_steps = 100;

    const custom_bar_style = loaders.BarStyle{
        .left_bracket = "▶ [",
        .right_bracket = "]",
        .fill = "=",
        .tip = ">",
        .empty = " ",
        .fill_fg = .cyan,
    };

    var bar = loaders.Bar.init(io, .{
        .total = total_steps,
        .style = custom_bar_style,
        .show_percent = true,
        .show_count = true,
    });
    defer bar.done();

    const phases = [_][]const u8{
        "Planning",
        "Analyzing",
        "Downloading",
        "Installing",
        "Verifying",
    };

    for (0..total_steps) |i| {
        bar.setCompleted(i + 1);
        const phase_idx = @min(i / (total_steps / 5), 4);
        bar.opts.label = phases[phase_idx];
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
```

## Run

```bash
zig build run-custom_template
```

## Output

```
▶ [Verifying  ] [=========================>     ]  72% 72/100
```

The label updates automatically as progress crosses each 20% threshold.
