# Advanced Techniques Guide

This article documents advanced techniques, thread optimization, custom drawing targets, and standard shell logic.

---

## 1. Custom Drawing Targets

By default, progress indicators write to the standard error stream. However, you can configure your progress bars to write to any file descriptor, stdout, or override color detection explicitly by passing a configured file descriptor inside `.file` option:

```zig
const file = try std.fs.cwd().createFile("output.log", .{});
defer file.close();

var bar = loaders.Bar.init(io, .{
    .label = "Writing log",
    .total = 100,
    .file = file, // Direct file output
});
```

---

## 2. Multi-Threaded Progress Safety

All counters on `loaders.Bar` use atomic registers (`std.atomic.Value`). The completed units and total units can be modified from separate threads safely using `.setCompleted()`, `.increment()`, or `.incrementBy()`.

Rendering operations, however, are **not thread-safe**. Refrain from calling `bar.render()` concurrently from multiple threads. Instead, configure background workers to only update completed units, and have a single rendering coordinator thread periodically invoke `bar.render()` (e.g. at 30fps / every 33ms) or call `mb.render()` in a coordinated multi-bar set.

---

## 3. High Performance Stacking

For low-latency CLI tools, you want to avoid dynamic memory heap allocations entirely inside the inner loops.

`loaders.Bar` is designed with high-performance static rendering in mind. It uses a fixed, stack-allocated internal write buffer (`write_buf: [4096]u8`), completely avoiding heap allocator queries during `render` cycles.

---

## 4. TTY Detection and Redirects Natively

On Linux and macOS, `loaders.zig` detects TTY status by querying the file descriptor using standard system POSIX parameters:
```zig
const is_tty = std.posix.isatty(std.posix.STDERR_FILENO);
```

On Windows, it queries the console parameters using kernel handle operations:
```zig
var mode: DWORD = undefined;
if (kernel32.GetConsoleMode(file.handle, &mode) != 0) { ... }
```

If these checks return `false`, `loaders.zig` automatically enters passive mode, avoiding complex ANSI cursor-move codes and simply logging standard progress lines separated by clean newlines. This guarantees clean outputs in all redirect pipelines and automated script triggers.
