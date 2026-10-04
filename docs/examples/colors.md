---
title: Color Examples
description: Color examples using tint.zig — RGB, HEX, 256-color, HSL, and gradients.
---

# Color Examples

loaders.zig uses [tint.zig](https://github.com/muhammad-fiaz/tint.zig) for color support. Colors are `Color` values that render to owned `Sequence` escape sequences (Zig 0.17.0 API).

## custom_colors_rgb

RGB colors using `loaders.makeRgb(r, g, b)`:

```bash
zig build run-custom_colors_rgb
```

```zig
const orange = loaders.makeRgb(255, 165, 0);
.bar.setColor(orange.fg());
```

## custom_colors_hex

Hex colors using `loaders.makeHex(0xRRGGBB)`:

```bash
zig build run-custom_colors_hex
```

```zig
const green = loaders.makeHex(0x22C55E); // #22C55E
.bar.setColor(green.fg());
```

## custom_colors_dynamic_gradient

Gradient computed per update with tint.zig Color:

```bash
zig build run-custom_colors_dynamic_gradient
```

```zig
const colors = [_]loaders.Color{
    loaders.makeRgb(255, 0, 0),    // red
    loaders.makeRgb(255, 128, 0),  // orange
    loaders.makeRgb(255, 255, 0),  // yellow
    loaders.makeRgb(0, 255, 0),    // green
    loaders.makeRgb(0, 0, 255),    // blue
    loaders.makeRgb(128, 0, 255),  // purple
};
bar.setColor(colors[idx].fg());
```

## Color Types

| Function | Description |
|----------|-------------|
| `loaders.makeRgb(r, g, b)` | RGB color (0-255 each). |
| `loaders.makeHex(0xRRGGBB)` | Hex color from integer. |
| `loaders.makeAnsi256(index)` | 256-color palette. |
| `loaders.makeHsl(h, s, l)` | HSL color. |
| `loaders.makeHsv(h, s, v)` | HSV color. |
| `loaders.makeCmyk(c, m, y, k)` | CMYK color. |
| `loaders.makeKelvin(t)` | Color temperature in Kelvin. |
| `loaders.makeNamed("red")` | CSS named color via `tint.color.parse`. |

## Getting ANSI Sequences

| Method | Description |
|--------|-------------|
| `color.fg()` | Foreground `Sequence` (`\x1b[38;2;R;G;Bm`). Use `.slice()` for `[]const u8`. |
| `color.bg()` | Background `Sequence` (`\x1b[48;2;R;G;Bm`). Use `.slice()` for `[]const u8`. |
| `loaders.fg(color)` | Same as `color.fg()`. |
| `loaders.bg(color)` | Same as `color.bg()`. |

> [!TIP]
> Named colors live in `loaders.tint.color` (for example `loaders.tint.color.red`) and `loaders.makeNamed("red")` parses CSS names at runtime.
