<div align="center">
<img  height="400" alt="loader zig" src="https://github.com/user-attachments/assets/042252d5-0594-4984-bece-deb3b232d91f" />

<a href="https://muhammad-fiaz.github.io/loaders.zig/"><img src="https://img.shields.io/badge/docs-muhammad--fiaz.github.io-blue" alt="Documentation"></a>
<a href="https://ziglang.org/"><img src="https://img.shields.io/badge/Zig-0.16.0-orange.svg?logo=zig" alt="Zig Version"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/stars/muhammad-fiaz/loaders.zig" alt="GitHub stars"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/issues"><img src="https://img.shields.io/github/issues/muhammad-fiaz/loaders.zig" alt="GitHub issues"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/pulls"><img src="https://img.shields.io/github/issues-pr/muhammad-fiaz/loaders.zig" alt="GitHub pull requests"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/last-commit/muhammad-fiaz/loaders.zig" alt="GitHub last commit"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig"><img src="https://img.shields.io/github/license/muhammad-fiaz/loaders.zig" alt="License"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/actions/workflows/ci.yml"><img src="https://github.com/muhammad-fiaz/loaders.zig/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
<img src="https://img.shields.io/badge/platforms-linux%20%7C%20windows%20%7C%20macos-blue" alt="Supported Platforms">
<a href="https://github.com/muhammad-fiaz/loaders.zig/actions/workflows/release.yml"><img src="https://github.com/muhammad-fiaz/loaders.zig/actions/workflows/release.yml/badge.svg" alt="Release"></a>
<a href="https://github.com/muhammad-fiaz/loaders.zig/releases/latest"><img src="https://img.shields.io/github/v/release/muhammad-fiaz/loaders.zig?label=Latest%20Release&style=flat-square" alt="Latest Release"></a>
<a href="https://pay.muhammadfiaz.com"><img src="https://img.shields.io/badge/Sponsor-pay.muhammadfiaz.com-ff69b4?style=flat&logo=heart" alt="Sponsor"></a>
<a href="https://github.com/sponsors/muhammad-fiaz"><img src="https://img.shields.io/badge/Sponsor-%F0%9F%92%96-pink?style=social&logo=github" alt="GitHub Sponsors"></a>

<p><em>A fast, high-performance terminal loading indicator and progress bar library for Zig.</em></p>

<b><a href="https://muhammad-fiaz.github.io/loaders.zig/">Documentation</a> |
<a href="https://muhammad-fiaz.github.io/loaders.zig/api/">API Reference</a> |
<a href="https://muhammad-fiaz.github.io/loaders.zig/guide/getting-started">Quick Start</a> |
<a href="https://github.com/muhammad-fiaz/loaders.zig/blob/main/README.md">Source</a></b>

</div>

`loaders.zig` is a production-oriented Zig library for animated spinners, progress bars, and multi-progress terminal UIs. It is designed for low overhead, clean output, and cross-platform terminal behavior on Linux, Windows, and macOS.

> [!NOTE]
> This project is still evolving, but the current API is built to be practical for real CLI tools and long-running terminal workflows.

**⭐ If you find `loaders.zig` useful, consider starring the repository.**

---

<details>
<summary><strong>Table of Contents</strong> (click to expand)</summary>

- [Prerequisites](#prerequisites)
- [Supported Platforms](#supported-platforms)
- [Features](#features)
- [Installation](#installation)
  - [Option A: Stable Release](#option-a--stable-release-recommended-for-production)
  - [Option B: Nightly / Beta](#option-b--nightly--beta-latest-main-branch)
  - [Option C: Build from Source](#option-c--build-from-source)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [Building](#building)
- [Contributing](#contributing)
- [License](#license)
- [Links](#links)

</details>

---

<details>
<summary><strong>Features</strong> (click to expand)</summary>

| Feature | Description | Documentation |
|---------|-------------|---------------|
| **Simple & Fluent API** | Add progress indicators in just a few lines. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/getting-started) |
| **Progress Bars** | Animated single-bar progress with percentage, ETA, and rate display. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/progress-bar) |
| **Spinners** | Background-threaded terminal spinners for non-blocking work. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/spinner) |
| **Multi Progress** | Render multiple concurrent bars or spinners together. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/multi-progress) |
| **Batch Progress** | Track multiple named tasks with per-task state (pending/running/done/failed). | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/batch-progress) |
| **Format Templates** | Custom layout strings using `{label}`, `{bar}`, `{percent}`, `{eta}`, `{rate}` tokens. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/format-templates) |
| **Rate Smoothing** | EMA-based rate/ETA smoothing for stable throughput display. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced) |
| **Styling** | Configure brackets, fills, colors, and suffixes. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/styling) |
| **Themes** | 20+ built-in visual presets for bars and spinners. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/themes) |
| **ANSI Colors** | 16-color ANSI, 256-color, 24-bit RGB, and hex string (`fromHex("#FF8800")`). | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/colors) |
| **Cross-Platform TTY Handling** | Detects terminal capabilities on Windows and POSIX systems. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced) |
| **No-Color Friendly** | Respects `NO_COLOR` and redirected output. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced) |
| **Stack-Friendly** | Zero heap allocation in core API. | [API](https://muhammad-fiaz.github.io/loaders.zig/api/) |

</details>

---

<details>
<summary><strong>Prerequisites & Supported Platforms</strong> (click to expand)</summary>

<br>

## Prerequisites

Before using `loaders.zig`, ensure you have:

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Zig** | 0.16.0 | Install from [ziglang.org](https://ziglang.org/download/) |
| **Operating System** | Windows, Linux, macOS | Cross-platform support |
| **Terminal** | Any modern terminal | For color and cursor control |

---

## Supported Platforms

| Platform | Status |
|----------|--------|
| **Windows** | Full support |
| **Linux** | Full support |
| **macOS** | Full support |

---

### Color Support

| Terminal | Support |
|----------|---------|
| **Windows Terminal** | Native ANSI |
| **PowerShell / CMD** | Supported with terminal capabilities |
| **iTerm2 / Terminal.app** | Native |
| **GNOME Terminal / Konsole** | Native |
| **VS Code Terminal** | Native |

</details>

---

## Installation

### Option A — Stable Release (Recommended for Production)

Pin to a specific tagged release for reproducible builds:

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.2.tar.gz
```

This automatically adds the dependency to your `build.zig.zon`:

```zig
.dependencies = .{
    .loaders = .{
        .url = "https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.2.tar.gz",
        .hash = "...", // auto-filled by zig fetch --save
    },
},
```

### Option B — Nightly / Beta (Latest Main Branch)

Use the latest unreleased code from `main`. This tracks HEAD and may include breaking changes:

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig.git
```

This adds a git dependency to your `build.zig.zon`:

```zig
.dependencies = .{
    .loaders = .{
        .url = "git+https://github.com/muhammad-fiaz/loaders.zig.git",
        .hash = "...", // auto-filled by zig fetch --save
    },
},
```

> [!TIP]
> Use `zig fetch --save` (with URL) for the automatic flow. It resolves the hash and writes it into `build.zig.zon` for you.

### Option C — Build from Source

```bash
git clone https://github.com/muhammad-fiaz/loaders.zig.git
cd loaders.zig
zig build
```

---

## Quick Start

### Progress Bar

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var bar = loaders.Bar.init(io, .{
        .label = "Processing",
        .total = 100,
        .show_percent = true,
        .show_elapsed = true,
    });
    defer bar.done();

    for (0..100) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
```

### Spinner

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const sp = try loaders.Spinner.start(io, .{
        .text = "Syncing local database...",
        .style = loaders.SpinnerStyle.dots,
    });
    errdefer sp.stop(io);

    try io.sleep(std.Io.Duration.fromSeconds(2), .awake);
    sp.succeed(io, "Database synchronized successfully!");
}
```

### Multi Progress

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null, .{});

    const a = mb.addBar(.{ .label = "Asset A", .total = 100 });
    const b = mb.addBar(.{ .label = "Asset B", .total = 100 });

    for (0..100) |i| {
        a.setCompleted(i + 1);
        b.setCompleted(i + 1);
        mb.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(20), .awake);
    }

    mb.done();
}
```

---

## Usage Examples

- [Getting Started](https://muhammad-fiaz.github.io/loaders.zig/guide/getting-started)
- [Progress Bars](https://muhammad-fiaz.github.io/loaders.zig/guide/progress-bar)
- [Spinners](https://muhammad-fiaz.github.io/loaders.zig/guide/spinner)
- [Multi Progress](https://muhammad-fiaz.github.io/loaders.zig/guide/multi-progress)
- [Styling](https://muhammad-fiaz.github.io/loaders.zig/guide/styling)
- [Colors](https://muhammad-fiaz.github.io/loaders.zig/guide/colors)
- [Themes](https://muhammad-fiaz.github.io/loaders.zig/guide/themes)
- [Advanced](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced)

---

## Configuration

The core options are available through `BarOptions` and `SpinnerOptions` in the API reference.

- `label`, `text`, `prefix`, and `icon` for user-facing messages and prefixes
- `total`, `show_percent`, `show_elapsed`, `show_eta`, and `show_rate` for progress details
- `style`, `color_enabled`, and custom bracket/fill fields for output control
- `file` and `term` for stream selection and terminal capability detection
- `success_icon`, `failure_icon`, `warning_icon`, and `info_icon` for custom status symbols
- `disable_new_line` to prevent spamming logs in non-TTY environments
- `icon_messages` for auto-cycling humorous or status messages with per-message custom icons
- `on_progress` and `on_complete` callbacks to fire custom functions on progress updates and bar completions
- `time_format_12h` option to render date/time prefixes in a 12-hour AM/PM format (defaults to 24-hour)
- `max_label_width`, `max_message_width`, `max_suffix_width` (for bars), `max_text_width` (for spinners), and `max_name_width` (for batch tasks) to enforce visual terminal column width truncation constraints
- `icon_gap`, `label_gap`, `datetime_gap` (for bars), `text_gap`, `state_gap` (for batch tasks/multi spinners) to specify custom explicit padding and space gaps between emojis, prefix icons, timestamp brackets, labels, and text contents (defaults to `" "` or `""`)
- `padding_lines_above` and `padding_lines_below` to insert blank padding lines above and below progress indicators, automatically positioning the cursor for clean, ghosting-free in-place redrawing
- `initial_completed` to start a progress bar with a prefilled progress value
- `start_time_offset_sec` to shift elapsed time and ETA calculations (e.g. for resuming tasks)
- `bg_color`, `text_bg_color`, `spinner_bg_color`, `label_bg_color`, `bracket_bg_color`, `percent_bg_color`, `fill_bg_color`, `empty_bg_color` to set explicit background colors on components

### I/O Progress Tracking

`loaders.zig` provides stream wrappers that automatically update progress as data is read or written:

- **Duck-typed Wrappers**: Wrap any custom stream using `progressReader(bar, stream)` and `progressWriter(bar, stream)`.
- **Standard Io Wrappers**: Wrap concrete standard library `std.Io.Reader` and `std.Io.Writer` interfaces using `progressIoReader(bar, reader)` and `progressIoWriter(bar, writer)`.

```zig
var downloader = MyDownloader.init();
var bar = loaders.Bar.init(io, .{ .total = total_size });
defer bar.done();

var p_reader = loaders.progressReader(&bar, &downloader);
var buf: [4096]u8 = undefined;
while (true) {
    const n = try p_reader.read(&buf);
    if (n == 0) break;
    bar.render();
}
```

### Custom Threading & Async Support

`loaders.zig` is designed to be compatible with custom thread pools and async event loops (such as when overriding `std_options` in Zig). The library and tests leverage the standard library's `std.Options.debug_io` interface. If you configure a custom thread pool or override single-threaded IO (by defining `std_options_debug_io` or `std_options_debug_threaded_io` in your application root), the library's background render threads and progress indicators will utilize it natively.

See the full API at [API Reference](https://muhammad-fiaz.github.io/loaders.zig/api/).

---

## Documentation

### Online Documentation

Full documentation is available at: https://muhammad-fiaz.github.io/loaders.zig/

### Generating Local Documentation

```bash
cd docs
bun install
bun run build
```

The output is written to `docs/.vitepress/dist/`.

---

## Building

```bash
zig build test
zig build examples
zig fmt --check build.zig src/ examples/
```

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) for details on how to get started, run tests, and submit pull requests.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Links

- **Documentation**: https://muhammad-fiaz.github.io/loaders.zig/
- **API Reference**: https://muhammad-fiaz.github.io/loaders.zig/api/
- **Guide**: https://muhammad-fiaz.github.io/loaders.zig/guide/
- **Repository**: https://github.com/muhammad-fiaz/loaders.zig
- **Issues**: https://github.com/muhammad-fiaz/loaders.zig/issues
