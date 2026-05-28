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

## 2. Spinner Style Presets (`SpinnerStyle`)

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
