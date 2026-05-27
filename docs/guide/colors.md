# Color Support Guide

`loaders.zig` includes a comprehensive terminal color system supporting basic, extended, and true colors.

---

## 1. Defining Colors (`loaders.Color`)

The `loaders.Color` union lets you style your progress indicators with three tiers of terminal color support:

### Tier 1: Standard 16-Color ANSI
Standard system terminal colors (supported by almost all shells):
- **Basic**: `.black`, `.red`, `.green`, `.yellow`, `.blue`, `.magenta`, `.cyan`, `.white`
- **Bright**: `.bright_black`, `.bright_red`, `.bright_green`, `.bright_yellow`, `.bright_blue`, `.bright_magenta`, `.bright_cyan`, `.bright_white`

```zig
const red_bar = loaders.BarStyle{
    .fill_fg = .red,
    .empty_fg = .bright_black,
};
```

---

### Tier 2: 256-Color Palette
Map custom 8-bit color indexes:

```zig
const custom_color = loaders.BarStyle{
    .fill_fg = .{ .color256 = 196 }, // Bold red-orange
};
```

---

### Tier 3: 24-Bit True Color (RGB)
Direct RGB configuration. Supported by modern shell emulators (iTerm2, Windows Terminal, Alacritty, kitty):

```zig
const premium_gradient = loaders.BarStyle{
    .fill_fg = .{ .rgb = .{ .r = 0, .g = 255, .b = 128 } }, // Spring green
};
```

---

## 2. Text Attributes (`loaders.Attribute`)

Apply basic text modifications via the `.attrs` array slice:

- **`.bold`**: Emphasized bold text.
- **`.dim`**: Low intensity.
- **`.italic`**: Slanted text.
- **`.underline`**: Underlined.
- **`.blink`**: Flashing.
- **`.reverse`**: Inverse colors.

```zig
const bold_bar = loaders.BarStyle{
    .fill_fg = .yellow,
    .attrs = &.{.bold, .underline},
};
```

---

## 3. Automatic Color Suppression

To prevent garbling terminal outputs, `loaders.zig` automatically checks standard environments and disables all ANSI escape sequences if:
- Output is redirected (e.g. `cmd > log.txt`).
- `NO_COLOR` is present in the environment block.
- Terminal identifies as dumb (`TERM=dumb`).
- Operating inside standard CI environment pipelines with no terminal color parameters.
