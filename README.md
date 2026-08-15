<div align="center">

<img src="docs/public/logo.png" alt="loaders.zig" width="250" />

# loaders.zig

<a href="https://muhammad-fiaz.github.io/loaders.zig/"><img src="https://img.shields.io/badge/docs-muhammad--fiaz.github.io-blue" alt="Documentation"></a>
<a href="https://ziglang.org/"><img src="https://img.shields.io/badge/Zig-0.16.0-orange.svg?logo=zig" alt="Zig Version"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/stars/muhammad-fiaz/loaders.zig" alt="GitHub stars"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/issues"><img src="https://img.shields.io/github/issues/muhammad-fiaz/loaders.zig" alt="GitHub issues"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/pulls"><img src="https://img.shields.io/github/issues-pr/muhammad-fiaz/loaders.zig" alt="GitHub pull requests"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/last-commit/muhammad-fiaz/loaders.zig" alt="GitHub last commit"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/license/muhammad-fiaz/loaders.zig" alt="License"></a>
<img src="https://img.shields.io/badge/platforms-linux%20%7C%20windows%20%7C%20macos-blue" alt="Supported Platforms">
<a href="https://github.com/muhammad-fiaz/loaders.zig/releases/latest"><img src="https://img.shields.io/github/v/release/muhammad-fiaz/loaders.zig?label=Latest%20Release&style=flat-square" alt="Latest Release"></a>
<a href="https://pay.muhammadfiaz.com"><img src="https://img.shields.io/badge/Sponsor-pay.muhammadfiaz.com-ff69b4?style=flat&logo=heart" alt="Sponsor"></a>
<a href="https://github.com/sponsors/muhammad-fiaz"><img src="https://img.shields.io/badge/Sponsor-GitHub-pink?style=social&logo=github" alt="GitHub Sponsors"></a>
<a href="https://hits.sh/muhammad-fiaz/loaders.zig/"><img src="https://hits.sh/muhammad-fiaz/loaders.zig.svg?label=Visitors&extraCount=0&color=green" alt="Repo Visitors"></a>

<p><em>A fast, high-performance terminal progress bar and spinner library for Zig.</em></p>

<b><a href="https://muhammad-fiaz.github.io/loaders.zig/">Documentation</a> |
<a href="https://muhammad-fiaz.github.io/loaders.zig/api/">API Reference</a> |
<a href="https://muhammad-fiaz.github.io/loaders.zig/guide/getting-started">Quick Start</a> |
<a href="CONTRIBUTING.md">Contributing</a></b>

</div>

`loaders.zig` is a production-oriented Zig library for animated spinners, progress bars, and multi-progress terminal UIs. It is designed for low overhead, clean output, and cross-platform terminal behavior on Linux, Windows, and macOS.

> [!TIP]
> loaders.zig uses [tint.zig](https://github.com/muhammad-fiaz/tint.zig) internally for color support — ANSI 4-bit, 256-color, RGB/TrueColor, HEX, HSL, HSV, CMYK, and 140+ named colors. You can also pass raw ANSI escape sequences directly.

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| **Zig** | 0.16.0 |
| **OS** | Windows, Linux, macOS |

---

## Installation

### Option A — Stable Release (Recommended for Production)

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.4.tar.gz
```

### Option B — Nightly / Beta (Latest Main Branch)

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
```

### Option C — Build from Source

```bash
git clone https://github.com/muhammad-fiaz/loaders.zig.git
cd loaders.zig
zig build
```

> [!IMPORTANT]
> After installing, wire the dependency into your `build.zig`:

```zig
const loaders = b.dependency("loaders", .{});
exe.root_module.addImport("loaders", loaders.module("loaders"));
```

> [!TIP]
> Use `zig fetch --save` for the automatic flow. It resolves the hash and writes it into `build.zig.zon` for you.

---

## Quick Start

### Progress Bar

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const allocator = std.heap.page_allocator;

    var bar = try loaders.ProgressBar.init(allocator, io, .{
        .total = 100,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "{bar} {percent}%",
        .text = "Processing",
    });
    defer bar.deinit();

    var i: u64 = 0;
    while (i <= 100) : (i += 1) {
        bar.setProgress(i);
        loaders.sleepMs(io, 30);
    }
    bar.finish(.{ .newline = true });
}
```

### Spinner

```zig
var sp = try loaders.Spinner.init(allocator, io, .{
    .frames = &.{ "|", "/", "-", "\\" },
    .template = "{frame} {text}",
    .text = "Loading",
});
defer sp.deinit();

try sp.start();
loaders.sleepMs(io, 2000);
sp.stop(.{ .final_text = "Done!", .newline = true });
```

> [!CAUTION]
> On Windows, Unicode characters (Braille, emoji) require UTF-8 console encoding. loaders.zig automatically enables UTF-8 mode on Windows.

### Multi-Progress

```zig
var mb = try loaders.MultiBar.init(allocator, io, .{});
defer mb.deinit();

_ = try mb.addBar(.{
    .total = 100,
    .style = .{ .filled = "#", .empty = "-" },
    .template = "Task A: {bar} {percent}%",
});
_ = try mb.addBar(.{
    .total = 100,
    .style = .{ .filled = "=", .empty = " " },
    .template = "Task B: {bar} {percent}%",
});

try mb.run();
// ... update bars ...
mb.finishAll(.{ .newline = true });
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Custom Bar Styles** | Override fill, empty, head, and bracket characters |
| **Custom Spinner Frames** | Provide any frame sequence (Braille, emoji, ASCII, etc.) |
| **ETA & Speed** | Real-time estimated time remaining and throughput via formatters |
| **Dynamic Messages** | Update text and color dynamically based on task phase or state |
| **Multi-Progress** | Sequential and parallel multi-bar rendering |
| **Batch Runner** | Process items with per-item and overall progress bars |
| **Step Sequences** | Ordered multi-step pipelines with spinner or bar per step |
| **Thread Modes** | `.none` (manual), `.auto` (background thread), `.external` (caller-driven) |
| **Pause/Resume** | Freeze and resume clocks and rendering |
| **Callbacks** | `on_tick`, `on_finish`, `on_pause`, `on_resume` hooks |
| **Runtime Swaps** | Change style, frames, template, text, color at runtime |
| **Color** | tint.zig — ANSI 4-bit, 256-color, RGB/TrueColor, HEX, HSL, HSV, CMYK, named colors |
| **Template Engine** | `{bar}`, `{frame}`, `{percent}`, `{count}`, `{elapsed}`, `{eta}`, `{speed}`, `{color}`, `{reset}` |
| **Windows UTF-8** | Automatic console code page setup for Unicode characters |

---

## Color

Colors use [tint.zig](https://github.com/muhammad-fiaz/tint.zig) internally — pass `color.toFg()` or use convenience functions:

```zig
// tint.zig color functions
.color = loaders.fg(.{ .ansi4 = .green })        // ANSI 4-bit green
.color = loaders.makeRgb(34, 197, 94).toFg()     // RGB (TrueColor)
.color = loaders.makeHex(0x22C55E).toFg()        // HEX color
.color = loaders.makeAnsi256(129).toFg()         // ANSI 256-color
.color = loaders.fg(.{ .named = .red })          // CSS named color

// Raw ANSI strings still work
.color = "\x1b[32m"        // green
.color = "\x1b[38;2;0;255;0m"  // green RGB

// No color
.color = null
```

Colors can be updated at runtime with `bar.setColor(...)` / `sp.setColor(...)`.

---

## API Reference

### ProgressBar

```zig
// Create
var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 100,
    .style = .{ .filled = "#", .empty = "-" },
    .template = "{bar} {percent}%",
    .text = "Processing",
    .color = loaders.fg(.{ .ansi4 = .green }),  // green via tint.zig
    .formatters = .{
        .elapsed = formatElapsed,
        .eta = formatEta,
        .speed = formatSpeed,
    },
});
defer bar.deinit();

// Control
bar.setProgress(50);            // Set absolute value
bar.pause();                    // Pause clock
bar.continue_();                // Resume from pause
bar.forceRedraw();              // Force immediate render
bar.finish(.{ .newline = true });
bar.fail("Network error");

// Update at runtime
bar.setText("new text");
bar.setPrefix(">");
bar.setSuffix("<");
bar.setColor(loaders.fg(.{ .ansi4 = .red }));
bar.setStyle(.{ .filled = "=", .empty = " ", .head = ">" });
try bar.setTemplate("{bar} {elapsed}");

// State
const s = bar.state();          // ProgressState
bar.getStatus();                // .pending | .running | .paused | .finished | .failed
```

### Spinner

```zig
// Create
var sp = try loaders.Spinner.init(allocator, io, .{
    .frames = &.{ "|", "/", "-", "\\" },
    .template = "{frame} {text}",
    .text = "Loading",
    .color = loaders.fg(.{ .ansi4 = .blue }),  // blue via tint.zig
    .thread_mode = .auto,
});
defer sp.deinit();

// Control
try sp.start();
sp.tickFrame();                 // Advance one frame
sp.setProgress(5);              // Set absolute frame index
sp.getCurrent();                // Get current frame index
sp.stop(.{ .final_text = "Done!", .newline = true });

// Update at runtime
sp.setText("new text");
sp.setColor(loaders.fg(.{ .ansi4 = .red }));
sp.setFrames(&.{ ".", "..", "..." });
try sp.setTemplate("{frame} {text}");

// State
const s = sp.state();           // SpinnerState
sp.getStatus();                 // .pending | .running | .finished | .failed
```

### MultiBar

```zig
var mb = try loaders.MultiBar.init(allocator, io, .{
    .mode = .sequential,        // .sequential | .parallel
});
defer mb.deinit();

_ = try mb.addBar(.{ ... });
_ = try mb.addSpinner(.{ ... });
try mb.run();
mb.finishAll(.{ .newline = true });
```

### BatchRunner

```zig
var batch = try loaders.BatchRunner.init(allocator, io, .{
    .mode = .sequential,
    .show_overall_bar = true,
    .overall_bar_config = .{
        .total = 5,
        .style = .{ .filled = "#", .empty = "-" },
        .template = "Overall: {bar} {count}",
    },
});
defer batch.deinit();

const items = [_]u32{ 1, 2, 3, 4, 5 };
try batch.run(u32, &items, processItem);
```

#### Parallel mode with worker-driven progress

In parallel mode, use `itemBar()` to drive per-item progress from the worker:

```zig
const WorkerCtx = struct {
    batch: *loaders.BatchRunner,
};

fn downloadWorker(item: DownloadItem, ctx: ?*anyopaque) void {
    const c: *WorkerCtx = @ptrCast(@alignCast(ctx orelse return));
    const bar = c.batch.itemBar() orelse return;
    var downloaded: u64 = 0;
    while (downloaded < item.size) : (downloaded += 1) {
        bar.setProgress(downloaded);
        loaders.sleepMs(g_threaded.io(), 2);
    }
    bar.setProgress(item.size);
}
```

### StepSequence

```zig
var seq = try loaders.StepSequence.init(allocator, io, .{});
defer seq.deinit();

_ = try seq.addStep(.{ .name = "Install", .kind = .{ .spinner = .{
    .frames = &.{ ".", "..", "..." },
    .template = "{frame} Installing...",
} } });

try seq.startStep(0);
// ... do work ...
seq.completeStep(0, .{});
```

---

## Template Tokens

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

> [!WARNING]
> If `{elapsed}`, `{eta}`, or `{speed}` are in the template but no formatter is provided, `init()` returns `error.MissingFormatter`.

---

## Formatter Functions

For `{elapsed}`, `{eta}`, and `{speed}` tokens, provide formatter functions:

```zig
fn formatElapsed(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);    // "MM:SS" or "HH:MM:SS"
}

fn formatEta(ns: u64, buf: []u8) []const u8 {
    return loaders.formatNs(buf, ns);
}

fn formatSpeed(per_sec: f64, buf: []u8) []const u8 {
    return loaders.formatRate(buf, per_sec);  // "123.4/s"
}

var bar = try loaders.ProgressBar.init(allocator, io, .{
    .total = 200,
    .style = .{ .filled = "=", .empty = " ", .head = ">" },
    .template = "{bar} {percent}% | Elapsed: {elapsed} ETA: {eta} | {speed}",
    .width = 30,
    .formatters = .{
        .elapsed = formatElapsed,
        .eta = formatEta,
        .speed = formatSpeed,
    },
});
```

---

## Examples

All 40 examples live in `examples/`:

```bash
zig build examples          # Build all examples
zig build run-all-examples  # Run all examples sequentially

# Run individual examples
zig build run-basic_bar
zig build run-basic_spinner
zig build run-custom_ascii_bar
zig build run-custom_bracket_bar
zig build run-block_bar
zig build run-indeterminate
zig build run-template_with_eta_speed
zig build run-runtime_style_swap
zig build run-runtime_frame_swap
zig build run-manual_tick
zig build run-external_thread
zig build run-auto_thread
zig build run-multi_bar_sequential
zig build run-multi_bar_parallel
zig build run-batch_sequential
zig build run-batch_parallel_downloads
zig build run-batch_dynamic_messages
zig build run-step_sequence_basic
zig build run-step_runall
zig build run-custom_colors_rgb
zig build run-custom_colors_hex
zig build run-custom_colors_dynamic_gradient
zig build run-pause_resume
zig build run-text_updates
zig build run-dynamic_messages
zig build run-dynamic_spinner_messages
zig build run-spinner_looping_messages
zig build run-spinner_conditional_messages
zig build run-infinite_spinner
zig build run-infinite_progress_bar
zig build run-clear_on_finish
zig build run-fail_and_status
zig build run-callback_hooks
zig build run-state_accessor
zig build run-starting_value
zig build run-indeterminate_timeout
zig build run-progress_bar_unicode
zig build run-progress_bar_countdown
zig build run-spinner_braille
zig build run-progress_bar_countdown_eta
```

---

## Building

```bash
zig build test          # Run unit tests
zig build examples      # Build all examples
zig build docs          # Generate library documentation
```

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Links

- **Repository**: https://github.com/muhammad-fiaz/loaders.zig
- **Documentation**: https://muhammad-fiaz.github.io/loaders.zig/
