# Getting Started with loaders.zig

This guide will walk you through adding `loaders.zig` as a dependency and writing your first progress indicator.

---

## 1. Adding the Dependency

In your project's `build.zig.zon` file, add `loaders` to your `.dependencies`:

```zig
.{
    .name = .my_app,
    .version = "0.1.0",
    .dependencies = .{
        .loaders = .{
            .url = "git+https://github.com/muhammad-fiaz/loaders.zig.git#COMMIT_HASH",
            .hash = "DEPENDENCY_HASH",
        },
    },
    .paths = .{""},
}
```

Next, reference this dependency inside your `build.zig`:

```zig
const loaders_dep = b.dependency("loaders", .{
    .target = target,
    .optimize = optimize,
});

// Import into your main executable module
exe.root_module.addImport("loaders", loaders_dep.module("loaders"));
```

---

## 2. Your First Progress Bar

Create a file `main.zig` and add the following 8-line progress bar:

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Create a progress bar with 100 units
    var bar = loaders.Bar.init(io, .{
        .label = "Loading Assets",
        .total = 100,
        .show_percent = true,
        .show_elapsed = true,
    });
    // Ensure terminal cursor returns to normal when finished
    defer bar.done();

    for (0..100) |i| {
        bar.setCompleted(i + 1);
        bar.render();
        // Sleep for 30ms per step
        try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
    }
}
```

---

## 3. Your First Spinner

Spinners are fantastic for indicating non-blocking asynchronous work. Here is how to launch an animated spinner in a background thread:

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Start background spinner thread
    const sp = try loaders.Spinner.start(io, .{
        .text = "Syncing local cache...",
        .style = loaders.SpinnerStyle.dots,
    });
    
    // Perform simulated work
    try io.sleep(std.Io.Duration.fromSeconds(2), .awake);
    
    // Stop and display success line
    sp.succeed(io, "Cache synchronized successfully!");
}
```

---

## 4. Understanding standard I/O and TTY

By default, `loaders.zig` will print progress updates to the Standard Error stream (`stderr`). In a terminal, both stdout and stderr render to the same screen, but keeping progress bars on stderr ensures that if a user redirects stdout to a file (e.g. `my_tool > result.json`), the progress bar does not contaminate the redirected data.

If the output stream is redirected or pipe-filtered, `loaders.zig` automatically detects this, suppresses terminal ANSI cursor movements, and defaults to safe newline logging instead.
