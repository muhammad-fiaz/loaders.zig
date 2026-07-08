---
description: Color reference for loaders.zig v0.0.3 — ANSI 16-color, 256-color palette, true-color RGB, hex string parsing, and NO_COLOR support.
head:
  - - meta
    - name: keywords
      content: loaders.zig colors, zig terminal colors, ANSI colors, true color, 256 color, hex color, RGB color
  - - meta
    - property: og:title
      content: Colors — loaders.zig
  - - meta
    - property: og:description
      content: Complete reference for all color modes in loaders.zig v0.0.3
---

# Colors

`loaders.zig` exposes a rich, three-tier color system through the `Color` union type.  
When a terminal does not support color, or when the `NO_COLOR` environment variable is set, all color codes are automatically suppressed.

---

## The `Color` Type

```zig
pub const Color = union(enum) {
    black, red, green, yellow, blue, magenta, cyan, white,
    bright_black, bright_red, bright_green, bright_yellow,
    bright_blue, bright_magenta, bright_cyan, bright_white,
    ansi256: u8,
    rgb: struct { r: u8, g: u8, b: u8 },
    default,
};
```

---

## Tier 1 — Standard 16-Color Names

Pass color names directly as field literals:

```zig
.label_color = .bright_cyan,
.fill_color  = .green,
.empty_color = .bright_black,
```

All 16 names:

| Dark | Bright |
|------|--------|
| `.black` | `.bright_black` |
| `.red` | `.bright_red` |
| `.green` | `.bright_green` |
| `.yellow` | `.bright_yellow` |
| `.blue` | `.bright_blue` |
| `.magenta` | `.bright_magenta` |
| `.cyan` | `.bright_cyan` |
| `.white` | `.bright_white` |

---

## Tier 2 — 256-Color Palette

Use `Color.fromAnsi256(index)` to select from the 256-color xterm palette (index 0–255):

```zig
.fill_color = loaders.Color.fromAnsi256(202), // vivid orange
.fill_color = loaders.Color.fromAnsi256(51),  // bright cyan
```

Or use the union literal directly:

```zig
.fill_color = .{ .ansi256 = 200 },
```

---

## Tier 3 — True-Color RGB (24-bit)

### `Color.fromRgb(r, g, b)`

Pass exact R, G, B byte values:

```zig
.fill_color = loaders.Color.fromRgb(255, 136, 0),   // vivid orange
.fill_color = loaders.Color.fromRgb(0, 200, 180),   // teal
.fill_color = loaders.Color.fromRgb(160, 32, 240),  // violet
```

### `Color.fromHex(hex)`

Parse a CSS-style hex string at runtime — no allocation required:

```zig
.fill_color = loaders.Color.fromHex("#FF8800"),  // 6-digit with #
.fill_color = loaders.Color.fromHex("00FFAA"),   // 6-digit no #
.fill_color = loaders.Color.fromHex("#F80"),     // 3-digit shorthand
```

Returns `.default` on parse failure — the bar renders without that color.

---

## Applying Colors

Colors can be applied at two levels:

### 1. Bar-level shorthands (recommended)

```zig
var bar = loaders.Bar.init(io, .{
    .total       = 100,
    .fill_color  = loaders.Color.fromHex("#00FFAA"),
    .empty_color = .bright_black,
    .label_color = .bright_white,
    .percent_color = .yellow,
    .bracket_color = .bright_black,
});
```

### 2. Whole-Line Coloring
You can color the entire progress bar line (including label, counts, elapsed, brackets, percentage, suffix, etc.) with a single color option:

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .color = .cyan, // Colors the entire progress bar line cyan
});
```
Sub-component colors (like `.label_color`, `.fill_color`, `.bracket_color`) still act as overrides.

### 3. Full `BarStyle` struct

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .style = .{
        .fill    = "▓",
        .empty   = "░",
        .fill_fg = loaders.Color.fromRgb(0, 200, 100),
        .fill_bg = .default,
        .empty_fg = .bright_black,
    },
});
```

---

## Spinner Colors

```zig
const sp = try loaders.Spinner.start(io, .{
    .text         = "Working...",
    .text_color   = .bright_white,
    .spinner_color = loaders.Color.fromHex("#FF8800"),
    .style        = loaders.SpinnerStyle.dots,
});
```

You can also color the entire spinner line using the `.color` option:

```zig
const sp = try loaders.Spinner.start(io, .{
    .text  = "Working...",
    .color = .cyan, // Colors the whole spinner line
});
```

---

## Multi-Spinner Item Colors

`SpinnerItem` in `MultiSpinner` supports:
- `color`: Global color for the entire spinner item line.
- `text_color`: Specific text color override.
- `spinner_color`: Specific spinner glyph color override.

```zig
const item = ms.addItem("Compiling assets", .aesthetic);
item.color = .magenta;
item.text_color = .bright_white;
item.spinner_color = .bright_red;
```

---

## Batch Task Colors

`BatchTask` in `BatchBar` supports styling overrides per-task:
- `color`: Global color for the entire task progress bar line.
- `label_color`: Custom color for the task name/label.
- `fill_color`: Custom filled bar color.
- `empty_color`: Custom empty bar color.

```zig
const compile = bb.addTask("Compile", 100);
bb.tasks[compile].color = .cyan;
bb.tasks[compile].label_color = .bright_yellow;
bb.tasks[compile].fill_color = .green;
```

---

## Background Colors

`loaders.zig` supports setting background colors for both whole lines and specific sub-components (such as fills, empties, text, and labels). Simply pass the desired `Color` to the corresponding `_bg_color` configuration option:

- `bg_color`: The background color for the entire line (re-applied automatically across resets).
- `text_bg_color`: Background color for the text label.
- `spinner_bg_color`: Background color override for the spinner or status glyph.
- `label_bg_color`: Background color override for the progress bar label.
- `bracket_bg_color`: Background color override for the progress bar brackets.
- `percent_bg_color`: Background color override for the percentage indicator.
- `fill_bg_color`: Background color override for the filled progress bar blocks.
- `empty_bg_color`: Background color override for the empty progress bar blocks.

Example:
```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .bg_color = .bright_black, // Highlight the whole line background
    .fill_color = .green,
    .fill_bg_color = .bright_green,
});
```

---

## Completion & Status Color Fallbacks

Upon completion or when finalized with a specific status, loaders automatically fall back to styling the entire line with the corresponding status color (unless an explicit `.color` override was configured):

- **Success / Done (`succeed()`, `done()`, state `.done`)**: Fallback to **green** for the whole line.
- **Failure (`fail()`, state `.failed`)**: Fallback to **red** for the whole line.
- **Warning (state `.warn` / `.warning`)**: Fallback to **yellow** (amber) for the whole line.
- **Info (state `.info`)**: Fallback to **cyan** for the whole line.

---

## NO_COLOR Support

When the `NO_COLOR` environment variable is set (any value), all ANSI color codes are suppressed. Progress bars and spinners still render in plain text.

```zig
const environ = init.environ;
const color_on = loaders.terminal.shouldEnableColor(
    loaders.terminal.query(.stderr(), io),
    environ,
);
var bar = loaders.Bar.init(io, .{
    .color_enabled = color_on,
    ...
});
```

---

## Helper: `writeColored`

Write a single colored string directly to any `std.Io.Writer`:

```zig
try loaders.writeColored(
    &writer,
    colorizer,
    "Hello, world!",
    loaders.Color.fromHex("#FF8800"),
    .default,        // background
    &.{ .bold },     // ANSI attributes
);
```
