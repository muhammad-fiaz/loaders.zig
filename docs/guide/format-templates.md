---
description: Format template engine for loaders.zig v0.0.2 — create custom progress bar layouts using named tokens like {label}, {bar}, {percent}, {eta}.
head:
  - - meta
    - name: keywords
      content: loaders.zig format template, progress bar template, custom layout, zig progress bar
  - - meta
    - property: og:title
      content: Format Templates — loaders.zig
---

# Format Templates

`loaders.zig` includes a powerful, allocation-free template rendering engine.  
Instead of the default layout, you can define a custom format string using named tokens.

---

## Quick Start

```zig
var bar = loaders.Bar.init(io, .{
    .total    = 100,
    .label    = "Upload",
    .template = "{label} [{bar}] {percent}  ETA {eta}  {rate}",
    .style    = loaders.BarStyle.ocean,
    .width    = 30,
});
defer bar.done();
```

The `template` field replaces the default rendering layout entirely.  
Any combination of tokens and literal text is valid.

---

## Supported Tokens

| Token | Description | Example output |
|-------|-------------|----------------|
| `{label}` | The bar label | `Upload` |
| `{bar}` | Filled progress bar segment | `▓▓▓▓░░░░░░` |
| `{percent}` | Formatted percentage | ` 42%` |
| `{elapsed}` | Elapsed time (MM:SS or H:MM:SS) | `01:23` |
| `{eta}` | Estimated time remaining | `00:45` |
| `{rate}` | Throughput rate | `12.3/s` or `1.20 MiB/s` |
| `{count}` | current/total with optional unit | `42/100` or `42/100 items` |
| `{time}` | Current wall-clock time [HH:MM:SS] | `14:35:02` |
| `{date}` | Current wall-clock date [YYYY-MM-DD] | `2026-04-15` |
| `{message}` | Dynamic message (updated via `setMessage`) | `processing...` |
| `{spinner}` | Animated spinner glyph | `⠙` |

> Unknown tokens like `{custom}` are passed through unchanged.

---

## Template Examples

### Rate + ETA focus
```zig
"{label} [{bar}] {percent}  {elapsed} ETA {eta}  {rate}"
```

### Spinner prefix
```zig
"{spinner} [{bar}] {count}  {message}"
```

### Timestamped log-style
```zig
"[{date} {time}] {label} [{bar}] {percent}"
```

### Minimal (just bar + percent)
```zig
"[{bar}] {percent}"
```

### Full kitchen sink
```zig
"[{time}] {label} [{bar}] {percent}  {elapsed} ETA {eta}  {rate}  {count}  {message}"
```

---

## The `{bar}` Token

The `{bar}` token renders fill/empty characters from the active `BarStyle`.  
Its width is controlled by the `width` option (or auto-sized if `width = 0`).

For indeterminate bars (`total = 0`), `{bar}` renders a bouncing animation.

---

## The `{spinner}` Token

The `{spinner}` token cycles through the frames of `SpinnerStyle.dots` by default.  
It is mainly useful for indeterminate bars to show activity.

---

## The `{count}` Token

The `{count}` token uses the `unit` option:

```zig
var bar = loaders.Bar.init(io, .{
    .total    = 1000,
    .unit     = "records",
    .template = "[{bar}] {count}",
});
// renders: [▓▓▓▓░░░░] 420/1000 records
```

---

## The `{rate}` Token

When `unit_is_bytes = true`, `{rate}` formats as bytes-per-second:

```zig
var bar = loaders.Bar.init(io, .{
    .total         = 100 * 1024 * 1024,
    .unit_is_bytes = true,
    .template      = "[{bar}] {percent}  {rate}",
});
// renders: [▓▓▓░░░░░░░]  42%  1.24 MiB/s
```

---

## `hasToken` Helper

Check if your template uses a specific token at compile time or runtime:

```zig
const has_bar = loaders.hasToken("{label} [{bar}] {percent}", "bar"); // true
const has_eta = loaders.hasToken("{label} [{bar}] {percent}", "eta"); // false
```

---

## Mixing Template and Style

The `template` works with all `BarStyle` presets and custom styles:

```zig
var bar = loaders.Bar.init(io, .{
    .total       = 100,
    .template    = "{label} [{bar}] {percent}",
    .style       = loaders.BarStyle.fire,
    .width       = 30,
    .label       = "Hot Task",
    .label_color = .bright_red,
});
```
