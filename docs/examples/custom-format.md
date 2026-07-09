---
description: Custom format template example for loaders.zig v0.0.3 — use named tokens to define fully custom progress bar layouts.
---

# Custom Format Template Example

Demonstrates the template rendering engine using `{label}`, `{bar}`, `{percent}`, `{eta}`, `{rate}`, `{time}`, `{spinner}`, `{message}` tokens.

**Source:** [`examples/custom_format.zig`](https://github.com/muhammad-fiaz/loaders.zig/blob/main/examples/custom_format.zig)

**Run:**
```bash
zig build run-custom_format
```

## Code Excerpt

```zig
// Layout 1: Rate + ETA
var bar1 = loaders.Bar.init(io, .{
    .total         = 80,
    .label         = "Upload",
    .unit_is_bytes = true,
    .template      = "{label} [{bar}] {percent}  {elapsed} ETA {eta}  {rate}",
    .style         = loaders.BarStyle.ocean,
    .width         = 30,
});

// Layout 2: Spinner prefix + message
var bar2 = loaders.Bar.init(io, .{
    .total    = 100,
    .template = "{spinner} [{bar}] {count}  {message}",
    .style    = loaders.BarStyle.neon,
    .width    = 25,
});

// Layout 3: Timestamped
var bar3 = loaders.Bar.init(io, .{
    .total    = 50,
    .label    = "Indexing",
    .template = "[{date} {time}] {label} [{bar}] {percent}  ETA {eta}",
    .style    = loaders.BarStyle.green,
    .width    = 20,
});
```

## Supported Tokens

| Token | Output |
|-------|--------|
| `{label}` | Bar label |
| `{bar}` | Fill bar segment |
| `{percent}` | ` 42%` |
| `{elapsed}` | `01:23` |
| `{eta}` | `00:45` |
| `{rate}` | `1.2 MiB/s` or `5.5/s` |
| `{count}` | `42/100` or `42/100 items` |
| `{time}` | `14:35:02` |
| `{date}` | `2026-04-15` |
| `{message}` | dynamic message |
| `{spinner}` | `⠙` animation glyph |
