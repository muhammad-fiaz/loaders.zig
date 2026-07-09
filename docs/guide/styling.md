---
description: Design, configure, and apply custom styling to progress indicators. BarStyle and SpinnerStyle customization with brackets, fills, tips, and colors.
head:
  - - meta
    - name: keywords
      content: loaders.zig styling, zig progress bar style, bar style, spinner style, custom loading animation
  - - meta
    - property: og:title
      content: Styling Guide — loaders.zig
  - - meta
    - property: og:description
      content: Design, configure, and apply custom styling to progress indicators.
---

# Styling and Layouts Guide

This article documents how to design, configure, and apply custom styling to your progress indicators.

---

## 1. Customising Progress Bars (`BarStyle`)

`loaders.BarStyle` is a pure struct that controls every visual attribute of a progress bar:

```zig
pub const BarStyle = struct {
    /// Left bracket character (default "["). Set to "" for no brackets.
    left_bracket: []const u8 = "[",
    /// Right bracket character (default "]"). Set to "" for no brackets.
    right_bracket: []const u8 = "]",
    /// String repeated for the completed portion (default "█").
    fill: []const u8 = "█",
    /// String repeated for the empty portion (default "░").
    empty: []const u8 = "░",
    /// String placed at the leading edge of the fill (tip) (default "").
    tip: []const u8 = "",
    
    /// Foreground color for filled portion.
    fill_fg: Color = .default,
    /// Background color for filled portion.
    fill_bg: Color = .default,
    /// Foreground color for empty portion.
    empty_fg: Color = .default,
    /// Background color for empty portion.
    empty_bg: Color = .default,
    
    /// Text attributes applied to the entire rendering line.
    attrs: []const Attribute = &.{},
};
```

### Examples of Custom Styles

#### A Minimalist Dot Bar
```zig
const dot_style = loaders.BarStyle{
    .left_bracket = " ",
    .right_bracket = " ",
    .fill = "•",
    .empty = " ",
    .tip = "∘",
    .fill_fg = .cyan,
};
```

#### An Arrow Tip Bar
```zig
const arrow_style = loaders.BarStyle{
    .left_bracket = "(",
    .right_bracket = ")",
    .fill = "=",
    .tip = ">",
    .empty = " ",
    .fill_fg = .green,
    .empty_fg = .bright_black,
};
```

---

## 2. Customising Spinner Animations (`SpinnerStyle`)

You can create entirely custom spinner animations by defining a custom frame list and frame cycling interval:

```zig
const my_spinner = loaders.SpinnerStyle{
    .frames = &.{ "◰", "◳", "◲", "◱" },
    .interval_ms = 120,
    .color = .yellow,
    .attrs = &.{.bold},
};
```

This lets you build beautifully integrated brand-specific CLI animations easily.

---

## 3. Gradient Rendering

Both `BarStyle` and `SpinnerStyle` support gradient-based color rendering, where each character is colored from a smoothly interpolated gradient palette.

### Gradient on Progress Bars

```zig
pub const BarStyle = struct {
    // ... existing fields ...
    /// Optional gradient for the filled portion. When set, overrides fill_fg with per-character interpolated colors.
    fill_gradient: ?*const Gradient = null,
    /// Optional gradient for the empty portion. When set, overrides empty_fg with per-character interpolated colors.
    empty_gradient: ?*const Gradient = null,
    /// Color for the filled portion when bar is complete (100% or stopped). Takes precedence over fill_gradient.
    complete_fg: Color = .default,
};
```

```zig
var bar = loaders.Bar.init(io, .{
    .total = 100,
    .style = .{
        .fill_gradient = loaders.Gradient.rainbow,
        .empty_gradient = loaders.Gradient.ocean,
        .complete_fg = .green,
    },
});
```

### Gradient on Spinners

```zig
pub const SpinnerStyle = struct {
    // ... existing fields ...
    /// Optional gradient for the spinner glyph. Each frame is colored with the gradient interpolated across the frame width.
    gradient: ?Gradient = null,
    /// Color override for the spinner glyph in completed state (succeed/fail/warn/info).
    complete_fg: Color = .default,
};
```

```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Processing...",
    .style = .{
        .gradient = loaders.Gradient.fire,
        .complete_fg = .green,
    },
});
```

### Built-in Gradient Presets

| Preset | Description |
|--------|-------------|
| `Gradient.rainbow` | Full rainbow spectrum |
| `Gradient.fire` | Warm fire tones |
| `Gradient.ocean` | Cool ocean blues |
| `Gradient.sunset` | Sunset warmth |
| `Gradient.neon` | Bright neon |
| `Gradient.forest` | Forest greens |
| `Gradient.ice` | Icy blues |
| `Gradient.pastel` | Soft pastel rainbow |
| `Gradient.monochrome` | Grayscale |
| `Gradient.rainbow_reversed` | Reversed rainbow |

### Custom Gradients

```zig
const my_gradient = loaders.Gradient{
    .colors = &.{ .red, .yellow, .green },
};

var bar = loaders.Bar.init(io, .{
    .total = 100,
    .style = .{
        .fill_gradient = &my_gradient,
    },
});
```
