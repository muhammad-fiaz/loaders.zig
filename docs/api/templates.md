---
title: Templates & Formatters
description: Template tokens, formatter functions, and custom output formatting.
---

# Templates & Formatters

Every widget renders through the template engine. Templates are validated at `init` — if the template uses `{elapsed}`, `{eta}`, or `{speed}` without a matching formatter, `init` returns `error.MissingFormatter`.

## Tokens

| Token | Description |
|-------|-------------|
| `{bar}` | Rendered bar track (filled + empty characters) |
| `{frame}` | Current spinner animation frame |
| `{percent}` | Progress percentage (e.g. `50.0`) |
| `{count}` | Current/total count (e.g. `50/100`) |
| `{elapsed}` | Elapsed time (requires `formatters.elapsed`) |
| `{eta}` | Estimated time remaining (requires `formatters.eta`) |
| `{speed}` | Throughput rate (requires `formatters.speed`) |
| `{prefix}` | Optional prefix text |
| `{suffix}` | Optional suffix text |
| `{text}` | Optional display text |
| `{color}` | Raw ANSI color escape sequence |
| `{reset}` | ANSI reset sequence (`\x1b[0m`) |

## FormatterSet

```zig
pub const ElapsedFormatter = *const fn (ns: u64, buf: []u8) []const u8;
pub const SpeedFormatter = *const fn (per_sec: f64, buf: []u8) []const u8;

pub const FormatterSet = struct {
    elapsed: ?ElapsedFormatter = null,
    eta: ?ElapsedFormatter = null,
    speed: ?SpeedFormatter = null,
};
```

### Built-in formatter helpers

```zig
fn formatElapsed(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);        // "MM:SS" or "HH:MM:SS"
}

fn formatEta(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);
}

fn formatSpeed(per_sec: f64, buf: []u8) []const u8 {
    return loaders.formatRate(buf, per_sec); // "123.4/s"
}
```

## Usage

```zig
var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 200,
    .template = "{bar} {percent}% | Elapsed: {elapsed} ETA: {eta} | {speed}",
    .width = 30,
    .formatters = .{
        .elapsed = formatElapsed,
        .eta = formatEta,
        .speed = formatSpeed,
    },
});
```

## Direct Rendering

The engine is also exposed for custom widgets:

```zig
pub const TemplateValues = struct {
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    text: ?[]const u8 = null,
    bar: ?[]const u8 = null,
    frame: ?[]const u8 = null,
    percent: ?f64 = null,
    count: ?u64 = null,
    total: ?u64 = null,
    elapsed_ns: ?u64 = null,
    eta_ns: ?u64 = null,
    speed: ?f64 = null,
    color: ?[]const u8 = null,
};
```

- `loaders.validateTemplate(template, formatters) !void` — `error.MissingFormatter`.
- `loaders.renderTemplate(buf, scratch, template, values, formatters) ![]const u8` — rendered into the caller-provided `buf` (with `scratch` for formatters). No allocation; returns `error.MissingFormatter` / `error.BufferOverflow`.

```zig
var buf: [256]u8 = undefined;
var scratch: [64]u8 = undefined;
const out = try loaders.renderTemplate(&buf, &scratch, "{bar} {percent}%", .{
    .bar = "#####",
    .percent = 50.0,
}, .{});
```

> [!NOTE]
> Formatter functions receive `scratch` and must return a slice of it (or of the passed-in `buf`) — do not return a slice of a local stack array.