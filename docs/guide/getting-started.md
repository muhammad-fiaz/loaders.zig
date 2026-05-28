---
description: Install loaders.zig and build your first progress bar or spinner in minutes. Supports nightly, stable release, and build-from-source installation methods.
head:
  - - meta
    - name: keywords
      content: loaders.zig install, zig progress bar, zig spinner, zig loading indicator, zig dependency, build.zig.zon
  - - meta
    - property: og:title
      content: Getting Started with loaders.zig
  - - meta
    - property: og:description
      content: Install loaders.zig and build your first progress bar or spinner in minutes.
---

# Getting Started with loaders.zig

This guide walks you through installing `loaders.zig` and writing your first progress indicator.

---

## 1. Installation

### Option A — Stable Release (Recommended for Production)

Pin to a specific tagged release for reproducible builds:

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.1.tar.gz
```

This automatically adds the dependency to your `build.zig.zon`:

```zig
.dependencies = .{
    .loaders = .{
        .url = "https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.1.tar.gz",
        .hash = "...", // auto-filled by zig fetch --save
    },
},
```

### Option B — Nightly / Beta (Latest Main Branch)

Use the latest unreleased code from `main`. This tracks HEAD and may include breaking changes:

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/loaders.zig.git
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

## 2. Wire Up `build.zig`

After adding the dependency, reference it in your `build.zig`:

```zig
const loaders_dep = b.dependency("loaders", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("loaders", loaders_dep.module("loaders"));
```

The `addImport` call exposes the `loaders` module to your executable.

---

## 3. Your First Progress Bar

Create `main.zig`:

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bar = loaders.Bar.init(io, .{
        .label = "Loading Assets",
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

Run it:

```bash
zig build run-main
```

---

## 4. Your First Spinner

Spinners run on a background thread, making them ideal for non-blocking work:

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const sp = try loaders.Spinner.start(io, .{
        .text = "Syncing local cache...",
        .style = loaders.SpinnerStyle.dots,
    });

    // Perform real work here
    try io.sleep(std.Io.Duration.fromSeconds(2), .awake);

    sp.succeed(io, "Cache synchronized successfully!");
}
```

---

## 5. Understanding stderr and TTY

By default, `loaders.zig` writes to **stderr**. This keeps progress indicators out of stdout when users redirect output (e.g. `my_tool > result.json`).

If stderr is redirected, piped, or connected to a dumb terminal, `loaders.zig` automatically:
- Disables ANSI cursor movement codes
- Falls back to newline-separated logging
- Respects `NO_COLOR` environment variable
