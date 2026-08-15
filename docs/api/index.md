---
title: API Overview
description: Overview of the loaders.zig public API surface.
---

# API Overview

All public types are re-exported from the root module: `@import("loaders")`.

## Types

| Type | Description |
|------|-------------|
| `ProgressBar` / `ProgressBarConfig` | Animated bar with percent, count, ETA, elapsed, speed. |
| `Spinner` / `SpinnerConfig` | Animated spinner with any frame sequence. |
| `BlockProgressBar` / `BlockBarConfig` | Bar with partial block fills (`▏▎▍▌▋▊▉`). |
| `Indeterminate` / `IndeterminateConfig` | Sliding-segment bar for unknown progress. |
| `MultiBar` / `MultiBarConfig` | Multiple bars/spinners rendered together. |
| `BatchRunner` / `BatchConfig` | Process items with per-item and overall bars. |
| `StepSequence` / `StepSequenceConfig` | Ordered steps, each backed by a bar or spinner. |
| `CustomBarStyle`, `BlockBarStyle`, `IndeterminateStyle` | Character styles. |
| `ProgressState`, `SpinnerState`, `IndeterminateState` | Snapshot state structs. |
| `Status` | `.pending` \| `.running` \| `.paused` \| `.finished` \| `.failed`. |
| `ThreadMode` | `.none` \| `.auto` \| `.external`. |
| `Direction` | `.incremental` \| `.decremental`. |
| `FinishConfig` | `{ clear, final_text, newline }`. |
| `FormatterSet`, `TemplateValues` | Template formatters and values (see [Templates](/api/templates)). |
| `FontStyle` | Bold, dim, italic, underline, blink, reverse, strikethrough, concealed. |
| `TerminalSize` | `{ rows, cols }`. |
| `Color` | tint.zig Color union (ANSI 4-bit, 256, RGB, Hex). |
| `Style` | tint.zig Style with fg, bg, underline_color, bold, italic, etc. |
| `Named` | CSS named colors (red, green, blue, etc.). |

## Functions

| Function | Description |
|----------|-------------|
| `loaders.sleepMs(io, ms)` | Sleep the current thread. |
| `loaders.formatNs(buf, ns)` | Format nanoseconds as `MM:SS` / `HH:MM:SS`. |
| `loaders.formatRate(buf, per_sec)` | Format a rate as `123.4/s`. |
| `loaders.renderTemplate(...)` | Render a template with `TemplateValues`. |
| `loaders.validateTemplate(template, formatters)` | Validate a template; returns `error.MissingFormatter`. |
| `loaders.stdoutWriter(io)` | Get the shared stdout writer (**returns a pointer**). |
| `loaders.eraseLine(io)`, `moveUp(io, n)`, `moveDown(io, n)`, `moveRight(io, n)`, `moveLeft(io, n)` | ANSI cursor/line helpers. |
| `loaders.hideCursor(io)`, `showCursor(io)` | Hide/show the terminal cursor. |
| `loaders.getTerminalSize()` | Current terminal `{ rows, cols }`. |
| `loaders.ensureTerminal()` | Enable VT processing + UTF-8 output (Windows). |

### Color Helpers

| Function | Description |
|----------|-------------|
| `loaders.makeRgb(r, g, b)` | Create RGB color from 0-255 values. |
| `loaders.makeHex(0xRRGGBB)` | Create color from hex integer. |
| `loaders.makeAnsi256(index)` | Create 256-color palette color. |
| `loaders.makeHsl(h, s, l)` | Create HSL color. |
| `loaders.makeNamed("red")` | Create CSS named color. |
| `loaders.fg(color)` | Get foreground ANSI escape string. |
| `loaders.bg(color)` | Get background ANSI escape string. |
| `loaders.fgRgb(r, g, b)` | Get RGB foreground ANSI string. |
| `loaders.bgRgb(r, g, b)` | Get RGB background ANSI string. |
| `loaders.fgHex(0xRRGGBB)` | Get hex foreground ANSI string. |
| `loaders.fg256(index)` | Get 256-color foreground ANSI string. |

## Common Method Names

All four widget types share the same method conventions:

| Method | ProgressBar | Spinner | BlockBar | Indeterminate |
|--------|-------------|---------|----------|---------------|
| init | `init(allocator, io, config)` | same | same | same |
| start | `start() !void` | `start() !void` | `start() !void` | `start() !void` |
| update | `tick()` / `setProgress(v)` | `tickFrame()` | `tick()` / `setProgress(v)` | `tickFrame()` |
| pause | `pause()` | `pause()` | `pause()` | `pause()` |
| resume | `continue_()` | `continue_()` | `continue_()` | `continue_()` |
| finish | `finish(FinishConfig)` | `stop(FinishConfig)` | `finish(FinishConfig)` | `stop(FinishConfig)` |
| fail | `fail(message)` | `fail(message)` | `fail(message)` | `fail(message)` |
| state | `state() ProgressState` | `state() SpinnerState` | `state() BlockState` | `state() IndeterminateState` |
| status | `getStatus()` | `getStatus()` | `getStatus()` | `getStatus()` |
| runtime text | `setText(s)` | `setText(s)` | `setText(s)` | `setText(s)` |
| runtime color | `setColor(?[]const u8)` | `setColor(?[]const u8)` | `setColor(?[]const u8)` | `setColor(?[]const u8)` |
| runtime template | `setTemplate(s) !void` | `setTemplate(s) !void` | `setTemplate(s) !void` | `setTemplate(s) !void` |

## Next

- [Progress Bar](/api/progress-bar)
- [Spinner](/api/spinner)
- [Multi Bar](/api/multi-bar)
- [Batch Runner](/api/batch-runner)
- [Step Sequence](/api/step-sequence)
- [Templates](/api/templates)