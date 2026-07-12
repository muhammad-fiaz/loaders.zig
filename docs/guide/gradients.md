---
description: Gradient color guide for loaders.zig v0.0.3 — multi-color gradients for progress bars and spinners with rainbow, fire, ocean, sunset, and custom presets.
head:
  - - meta
    - name: keywords
      content: loaders.zig gradient, progress bar gradient, multi-color loading, rainbow progress bar
  - - meta
    - property: og:title
      content: Gradient Colors — loaders.zig
  - - meta
    - property: og:description
      content: Multi-color gradient support for progress bars and spinners.
---

# Gradient Colors

`loaders.zig` v0.0.3 introduces gradient-based multi-color rendering for progress bars and spinners. Gradients interpolate between color stops to create smooth color transitions across the bar fill or spinner animation frames.

## Quick Start

```zig
var bar = loaders.ProgressBar.init(io, .{
    .label = "Downloading",
    .total = 100,
    .style = .{
        .fill_gradient = loaders.Gradient.rainbow,
    },
});
```

## Built-in Gradient Presets

| Preset | Colors | Description |
|--------|--------|-------------|
| `Gradient.rainbow` | Red → Yellow → Green → Cyan → Blue → Magenta → Red | Full spectrum cycle |
| `Gradient.fire` | Dark red → Orange → Yellow → White | Warm fire effect |
| `Gradient.ocean` | Deep blue → Teal → Cyan → Light blue | Cool ocean tones |
| `Gradient.sunset` | Purple → Magenta → Orange → Yellow | Warm sunset colors |
| `Gradient.neon` | Magenta → Cyan → Green → Yellow | Bright neon glow |
| `Gradient.forest` | Dark green → Green → Lime → Yellow-green | Natural forest tones |
| `Gradient.ice` | White → Light blue → Blue → Deep blue | Icy cool gradient |
| `Gradient.pastel` | Soft pink → Peach → Yellow → Mint → Sky → Lavender | Soft pastel colors |
| `Gradient.monochrome` | Dark gray → Light gray | Simple gray scale |
| `Gradient.rainbow_reversed` | Red → Magenta → Blue → Cyan → Green → Yellow → Red | Reversed rainbow |

## Custom Gradients

Create your own gradient by defining color stops:

```zig
const my_gradient = loaders.Gradient{
    .colors = &.{
        .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },    // Red
        .{ .rgb = .{ .r = 0, .g = 255, .b = 0 } },    // Green
        .{ .rgb = .{ .r = 0, .g = 0, .b = 255 } },    // Blue
    },
};

var bar = loaders.ProgressBar.init(io, .{
    .label = "Custom",
    .total = 100,
    .style = .{
        .fill_gradient = my_gradient,
    },
});
```

### Reversed Gradient

Set `.reversed = true` to flip the gradient direction:

```zig
const reversed = loaders.Gradient{
    .colors = &loaders.Gradient.rainbow.colors,
    .reversed = true,
};
```

## Gradient on Spinners

Spinners cycle through gradient colors on each animation frame:

```zig
var sp = try loaders.Spinner.start(io, .{
    .text = "Loading...",
    .style = .{
        .frames = &.{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        .gradient = loaders.Gradient.rainbow,
    },
});
```

## Gradient with Custom Fills

Combine gradients with custom fill characters for unique effects:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .label = "Fire",
    .total = 100,
    .style = .{
        .fill = "▓",
        .empty = "░",
        .tip = "▒",
        .fill_gradient = loaders.Gradient.fire,
    },
});
```

## Gradient on Empty Portion

Apply a gradient to the unfilled portion:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .label = "Dual Gradient",
    .total = 100,
    .style = .{
        .fill_gradient = loaders.Gradient.rainbow,
        .empty_gradient = loaders.Gradient.monochrome,
    },
});
```

## Gradient in Templates

Use gradient bars in custom format templates:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .template = "{label} [{bar}] {percent}",
    .style = .{
        .fill_gradient = loaders.Gradient.ocean,
    },
});
```

## How It Works

Gradients use linear RGB interpolation. Each color stop defines a point in the gradient, and the color at any position is computed by interpolating between the two nearest stops.

The `Gradient.at(t)` function returns the interpolated color at position `t` (0.0 to 1.0). For progress bars, `t` maps to the cell position across the bar width. For spinners, `t` cycles through the gradient on each frame.

## Performance

Gradient rendering uses the same ANSI escape sequence mechanism as solid colors. Each cell in the gradient gets its own color code, which means slightly more output bytes per frame. For most use cases this is negligible. If you need maximum performance, use solid colors instead.
