<div align="center">
<img src="https://github.com/user-attachments/assets/565fc3dc-dd2c-47a6-bab6-2f545c551f26" alt="logly logo" width="400" />

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
  - [Method 1: Zig Fetch](#method-1-zig-fetch)
  - [Method 3: Build from Source](#method-3-build-from-source)
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
| **Styling** | Configure brackets, fills, colors, and suffixes. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/styling) |
| **Themes** | Use built-in visual presets for bars and spinners. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/themes) |
| **ANSI Colors** | Support for 16-color ANSI, 256-color, and RGB output. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/colors) |
| **Cross-Platform TTY Handling** | Detects terminal capabilities on Windows and POSIX systems. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced) |
| **No-Color Friendly** | Respects `NO_COLOR` and redirected output. | [Guide](https://muhammad-fiaz.github.io/loaders.zig/guide/advanced) |
| **Stack-Friendly** | Designed to work well in small CLI tools and longer-running programs. | [API](https://muhammad-fiaz.github.io/loaders.zig/api/) |

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

### Method 1:

Use Zig's save flow to add `loaders.zig` as a dependency:

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
```

Add `loaders.zig` to your `build.zig.zon`:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .dependencies = .{
        .loaders = .{
            .url = "git+https://github.com/muhammad-fiaz/loaders.zig.git#main",
            .hash = "DEPENDENCY_HASH",
        },
    },
    .paths = .{""},
}
```

In `build.zig`:

```zig
const loaders_dep = b.dependency("loaders", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("loaders", loaders_dep.module("loaders"));
```

That `addImport` call is the method that exposes `loaders` to your executable or library module.

### Method 3: Build from Source

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
    var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null);

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

- `label`, `text`, and `prefix` for user-facing messages
- `total`, `show_percent`, `show_elapsed`, `show_eta`, and `show_rate` for progress details
- `style`, `color_enabled`, and custom bracket/fill fields for output control
- `file` and `term` for stream selection and terminal capability detection

See the full API at [API Reference](https://muhammad-fiaz.github.io/loaders.zig/api/).

---

## Documentation

### Online Documentation

Full documentation is available at: https://muhammad-fiaz.github.io/loaders.zig/

### Generating Local Documentation

```bash
cd docs
npm install
npm run docs:build
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

Contributions are welcome. Open an issue or pull request if you find a bug, want to improve the docs, or have an idea for a new loader style.

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