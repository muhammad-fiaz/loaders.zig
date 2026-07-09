---
description: Browse all built-in visual presets for progress bars and spinners. 18 bar styles and 33 spinner animations ready to use.
head:
  - - meta
    - name: keywords
      content: loaders.zig themes, zig bar presets, spinner presets, block bar, dots spinner, moon spinner
  - - meta
    - property: og:title
      content: Built-in Themes Gallery — loaders.zig
  - - meta
    - property: og:description
      content: Browse all built-in visual presets for progress bars and spinners.
---

# Built-in Themes Gallery

`loaders.zig` includes multiple pre-designed high-quality visual themes out of the box in `loaders.BarStyle` and `loaders.SpinnerStyle`.

---

## 1. Progress Bar Styles (`BarStyle`)

### `BarStyle.block` (Default)
Standard solid block visual style. Premium, bold, and clean:
- **Left/Right Brackets**: `[` and `]`
- **Fill**: `█`
- **Empty**: `░`

```zig
var bar = loaders.Bar.init(io, .{ .style = loaders.BarStyle.block });
```

---

### `BarStyle.shaded`
Uses shaded Unicode blocks for a lighter, textured visual feel:
- **Left/Right Brackets**: `[` and `]`
- **Fill**: `▓`
- **Tip**: `▒`
- **Empty**: `░`

```zig
var bar = loaders.Bar.init(io, .{ .style = loaders.BarStyle.shaded });
```

---

### `BarStyle.ascii`
Fully compatible retro ASCII layout. Great for legacy shells or stdout redirection:
- **Left/Right Brackets**: `[` and `]`
- **Fill**: `#`
- **Empty**: ` ` (space)

```zig
var bar = loaders.Bar.init(io, .{ .style = loaders.BarStyle.ascii });
```

---

### `BarStyle.minimal`
An elegant minimalist look with a leading arrow tip and zero brackets:
- **Left/Right Brackets**: none
- **Fill**: `─`
- **Tip**: `▶`
- **Empty**: `─`
- **Color**: Cyan fill on bright-black empty line

```zig
var bar = loaders.Bar.init(io, .{ .style = loaders.BarStyle.minimal });
```

---

## 2. Gradient Presets (`Gradient`)

Ten built-in gradient presets for rainbow, fire, ocean, and other colorful effects:

| Preset | Description |
|--------|-------------|
| `Gradient.rainbow` | Full rainbow spectrum (red → yellow → green → cyan → blue → magenta) |
| `Gradient.fire` | Warm fire tones (dark red → orange → yellow → white) |
| `Gradient.ocean` | Cool ocean blues (dark blue → teal → cyan → white) |
| `Gradient.sunset` | Sunset warmth (purple → red → orange → yellow) |
| `Gradient.neon` | Bright neon (magenta → cyan → green → yellow) |
| `Gradient.forest` | Forest greens (dark green → green → lime → yellow) |
| `Gradient.ice` | Icy blues (blue → cyan → white) |
| `Gradient.pastel` | Soft pastel rainbow |
| `Gradient.monochrome` | Black to white grayscale |
| `Gradient.rainbow_reversed` | Reversed rainbow (magenta → blue → cyan → green → yellow → red) |

### Usage

```zig
// Gradient on filled portion
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .fill_gradient = loaders.Gradient.rainbow,
});

// Gradient on spinner glyph
const sp = try loaders.Spinner.start(io, .{
    .text = "Processing...",
    .style = .{
        .gradient = loaders.Gradient.fire,
    },
});
```

---

## 3. Spinner Style Presets (`SpinnerStyle`)

### `SpinnerStyle.dots`
The standard fast dot-cycle spinner. Very responsive:
- **Frames**: `⠋`, `⠙`, `⠹`, `⠸`, `⠼`, `⠴`, `⠦`, `⠧`, `⠇`, `⠏`
- **Speed**: 80 ms
- **Color**: Cyan

---

### `SpinnerStyle.moon`
Smooth phase cycling of moon emojis:
- **Frames**: `🌑`, `🌒`, `🌓`, `🌔`, `🌕`, `🌖`, `🌗`, `🌘`
- **Speed**: 80 ms

---

### `SpinnerStyle.clock`
Fluid clock rotation:
- **Frames**: `🕛`, `🕐`, `🕑`, `🕒`, `🕓` ...
- **Speed**: 100 ms
