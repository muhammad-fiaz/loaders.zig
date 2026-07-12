---
description: Advanced techniques including custom drawing targets, multi-threaded safety, high-performance stacking, and TTY detection for CI environments.
head:
  - - meta
    - name: keywords
      content: loaders.zig advanced, zig terminal detection, TTY detection, thread safety, zig CI
  - - meta
    - property: og:title
      content: Advanced Techniques Guide — loaders.zig
  - - meta
    - property: og:description
      content: Advanced techniques including custom drawing targets, multi-threaded safety, and TTY detection.
---

# Advanced Techniques Guide

This article documents advanced techniques, thread optimization, custom drawing targets, and standard shell logic.

---

## 1. Custom Drawing Targets

By default, progress indicators write to the standard error stream. However, you can configure your progress bars to write to any file descriptor, stdout, or override color detection explicitly by passing a configured file descriptor inside `.file` option:

```zig
const file = try std.fs.cwd().createFile("output.log", .{});
defer file.close();

var bar = loaders.ProgressBar.init(io, .{
    .label = "Writing log",
    .total = 100,
    .file = file, // Direct file output
});
```

---

## 2. Multi-Threaded Progress Safety

All counters on `loaders.ProgressBar` use atomic registers (`std.atomic.Value`). The completed units and total units can be modified from separate threads safely using `.setCompleted()`, `.increment()`, or `.incrementBy()`.

Rendering operations, however, are **not thread-safe**. Refrain from calling `bar.render()` concurrently from multiple threads. Instead, configure background workers to only update completed units, and have a single rendering coordinator thread periodically invoke `bar.render()` (e.g. at 30fps / every 33ms) or call `mb.render()` in a coordinated multi-bar set.

### Custom Threading & Async Event Loops

The library is fully compatible with custom threading models and async event loops (such as custom root `std_options` overrides). All internals and test blocks utilize the standard library's `std.Options.debug_io` interface. If you configure a custom thread pool or override single-threaded IO (by defining `std_options_debug_io` or `std_options_debug_threaded_io` in your application root), `loaders.zig` will automatically utilize it for thread-safe terminal writes without crashing.

### Controlling Non-TTY Newlines

In non-TTY environments (such as CI/CD logs, redirected pipelines, or files), progress bars tend to output a new line for every single update frame, creating thousands of log lines.

By default, `loaders.ProgressBar` disables this behavior via `disable_new_line = true` (which is the default). This ensures progress updates are hidden until the final line on completion. You can re-enable intermediate log lines by configuring `disable_new_line = false`:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .total = 100,
    .disable_new_line = false, // Output new line on every render frame
});
```

---

## 3. High Performance Stacking

For low-latency CLI tools, you want to avoid dynamic memory heap allocations entirely inside the inner loops.

`loaders.ProgressBar` is designed with high-performance static rendering in mind. It uses a fixed, stack-allocated internal write buffer (`write_buf: [4096]u8`), completely avoiding heap allocator queries during `render` cycles.

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

---

## 5. Spacing, Margins & Layout Spacing

You can add empty spacing lines above and below progress indicators to separate them from other terminal output. The renderer moves the cursor dynamically to clear and redraw these empty spaces, preventing ghosting:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .total = 100,
    .padding_lines_above = 1, // 1 blank line above
    .padding_lines_below = 1, // 1 blank line below
});
```

For concurrent or grouped task renderers (`BatchBar`), you can configure the number of empty newline margins to render *in between* each individual task using `spacing_lines`:

```zig
var bb = loaders.BatchBar.init(io, .{
    .title = "Build Pipeline",
    .spacing_lines = 1, // 1 empty line in between each batch task
    .tasks = &.{
        .{ .name = "Compile", .total = 100 },
        .{ .name = "Link", .total = 50 },
    },
});
```

To prefill a progress bar to a starting value when initializing, use `initial_completed`:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .total = 100,
    .initial_completed = 35, // Prefilled to 35%
});
```

To shift elapsed times and ETA calculations (for instance, when resuming a paused task), use `start_time_offset_sec`:

```zig
var bar = loaders.ProgressBar.init(io, .{
    .total = 100,
    .start_time_offset_sec = 60, // Shift time by 60 seconds
});
```

---

## 6. I/O Stream Progress Integration

To automatically update progress bars as data streams through readers or writers, wrap them using progress wrappers:

- **Generic wrappers**: Use `progressReader(bar, stream)` and `progressWriter(bar, stream)` for duck-typed streams.
- **Concrete standard library wrappers**: Use `progressIoReader(bar, &reader)` and `progressIoWriter(bar, &writer)` for `std.Io.Reader` and `std.Io.Writer`.

```zig
var file = try std.Io.Dir.cwd().createFile(io, "output.bin", .{});
defer file.close(io);

var file_writer_buf: [4096]u8 = undefined;
var file_writer = std.Io.File.Writer.init(file, io, &file_writer_buf);

var p_io_writer = loaders.progressIoWriter(&bar, &file_writer.interface);

// Stream data directly; the progress bar is updated automatically!
_ = try response_reader.streamRemaining(p_io_writer.writer());
```
