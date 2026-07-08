---
description: Complete collection of runnable examples for loaders.zig. Progress bars, spinners, multi-progress, styling, and advanced techniques with full source code and sample output.
head:
  - - meta
    - name: keywords
      content: loaders.zig examples, zig progress bar example, zig spinner example, zig loading animation example, zig cli examples
  - - meta
    - property: og:title
      content: Examples — loaders.zig
  - - meta
    - property: og:description
      content: Complete collection of runnable examples for loaders.zig with full source code and sample output.
---

# Examples

Every example is a standalone program in the `examples/` directory. Run any example with:

```bash
zig build run-<name>
```

Or build all examples at once:

```bash
zig build examples
```

---

## Progress Bars

| Example | Description | Run |
|---------|-------------|-----|
| [Basic Bar](01-basic-bar) | Minimal 50-step progress bar with percentage | `zig build run-01_basic_bar` |
| [Basic Bar (100)](basic-bar) | Standard and unicode-styled 100-step bars | `zig build run-basic_bar` |
| [Styled Bar](02-styled-bar) | Side-by-side comparison of 7 bar styles | `zig build run-02_styled_bar` |
| [Custom Style](custom-style) | Custom `BarStyle` with `=` fill, `>` tip, green color | `zig build run-custom_style` |
| [Themed Bar](themed-bar) | Gallery of 9 built-in bar themes | `zig build run-themed_bar` |
| [Gradient Demo](gradient-demo) | Multi-color gradient progress bars and spinners | `zig build run-gradient_demo` |
| [ETA and Rate](eta-and-rate) | Dynamic ETA, rate, count, and elapsed time | `zig build run-eta_and_rate` |
| [Download Simulation](download-simulation) | 50 MB download with byte rate and ETA | `zig build run-download_simulation` |
| [Rate Smoothing](rate-smoothing) | Byte throughput and EMA rate smoothing | `zig build run-rate_smoothing` |
| [Advanced Options](advanced-options) | Decorators, timestamps, colors, responsive width | `zig build run-advanced_options` |
| [Custom Template](custom-template) | Dynamic label changes across 5 phases | `zig build run-custom_template` |
| [Nested Bars](nested-bars) | Outer/inner batch progress with MultiBar | `zig build run-nested_bars` |

## Spinners

| Example | Description | Run |
|---------|-------------|-----|
| [Spinner](spinner) | Dots, line, and moon spinners with text updates | `zig build run-spinner` |
| [Multi Spinner](multi-spinner) | 5 concurrent spinners with staggered finish states | `zig build run-multi_spinner` |

## Multi-Progress

| Example | Description | Run |
|---------|-------------|-----|
| [Multi Progress](multi-progress) | 4 concurrent bars with different styles | `zig build run-multi_progress` |

## Utilities

| Example | Description | Run |
|---------|-------------|-----|
| [Iterator Wrap](iterator-wrap) | Progress bar wrapper for iterators and callbacks | `zig build run-iterator_wrap` |
| [Animations](animations) | Showcase all 33 spinner and 18 bar presets | `zig build run-animations` |
| [Color Demo](color-demo) | Tiered ANSI, 256-color, and RGB colors | `zig build run-color_demo` |
| [Icon Demo](icon-demo) | Custom running prefix and completion icons | `zig build run-icon_demo` |
| [Multi-Message Progressbar](multi-message-progressbar) | Dynamic loading messages cycling and loop | `zig build run-multi_message_progressbar` |
