---
title: Color Examples
description: Color examples — tint.zig RGB, HEX, 256-color, and gradients.
---

# Color Examples

loaders.zig uses [tint.zig](https://github.com/muhammad-fiaz/tint.zig) for color support. Colors are `Color` objects that generate ANSI escape sequences.

## custom_colors_rgb

RGB colors using `loaders.makeRgb(r, g, b)`:

```bash
zig build run-custom_colors_rgb
```

```zig
const orange = loaders.makeRgb(255, 165, 0);
.bar.setColor(orange.toFg());
```

## custom_colors_hex

Hex colors using `loaders.makeHex(0xRRGGBB)`:

```bash
zig build run-custom_colors_hex
```

```zig
const green = loaders.makeHex(0x22C55E); // #22C55E
.bar.setColor(green.toFg());
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
bar.setColor(colors[idx].toFg());
```

## Color Types

| Function | Description |
|----------|-------------|
| `loaders.makeRgb(r, g, b)` | RGB color (0-255 each). |
| `loaders.makeHex(0xRRGGBB)` | Hex color from integer. |
| `loaders.makeAnsi256(index)` | 256-color palette. |
| `loaders.makeHsl(h, s, l)` | HSL color. |
| `loaders.makeNamed("red")` | CSS named color. |

## Getting ANSI Strings

| Method | Description |
|--------|-------------|
| `color.toFg()` | Foreground escape string (`\x1b[38;2;R;G;Bm`). |
| `color.toBg()` | Background escape string (`\x1b[48;2;R;G;Bm`). |

> [!TIP]
> You can still use raw ANSI strings: `.color = "\x1b[32m"` for green 4-bit.
