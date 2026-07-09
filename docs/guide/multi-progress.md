---
description: Render and coordinate multiple progress bars concurrently using loaders.MultiBar. Cursor-based rendering, worker synchronization patterns.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi progress, zig multi bar, concurrent progress bars, terminal multi progress
  - - meta
    - property: og:title
      content: Multi-Progress Rendering Guide — loaders.zig
  - - meta
    - property: og:description
      content: Render and coordinate multiple progress bars concurrently using loaders.MultiBar.
---

# Multi-Progress Rendering Guide

This article covers rendering and coordinating multiple progress bars concurrently using `loaders.MultiBar`.

---

## 1. Concepts and Screen Layout

Standard progress bars operate by drawing their state, returning the cursor to the beginning of the line with a carriage return (`\r`), and overwriting the line on the next update. This only works for a single bar.

To render multiple bars, `MultiBar` coordinates the layout:
1. It registers child bars.
2. When you call `mb.render()`, it draws each bar on its own line, separated by newlines (`\n`).
3. On the next draw cycle, it uses terminal ANSI escape sequences to move the cursor up by the number of bars (`\x1b[{N}A`), erases each line, and redraws the bars from top to bottom.

This creates the illusion of multiple independently animated bars.

---

## 2. Basic Setup

To run a multi-bar set:

```zig
var mb = loaders.MultiBar.init(io, std.Io.File.stderr(), null);

// Add progress bars
const bar1 = mb.addBar(.{ .label = "File A", .total = 100 });
const bar2 = mb.addBar(.{ .label = "File B", .total = 150 });

// Ensure correct terminal cleanup when finished
defer mb.done();
```

---

## 3. Worker Synchronization Pattern

Since `Bar.setCompleted` and `Bar.increment` are completely thread-safe, you can offload work to separate background threads and let them update their bars independently:

```zig
const Context = struct {
    bar: *loaders.Bar,
    io: std.Io,
};

fn worker(ctx: Context) void {
    for (0..100) |i| {
        ctx.bar.setCompleted(i + 1);
        ctx.io.sleep(std.Io.Duration.fromMilliseconds(50), .awake) catch {};
    }
}

// In your main thread:
const t1 = try std.Thread.spawn(.{}, worker, .{Context{ .bar = bar1, .io = io }});
const t2 = try std.Thread.spawn(.{}, worker, .{Context{ .bar = bar2, .io = io }});

// Main thread acts as the rendering coordinator
while (bar1.completed.load(.acquire) < 100 or bar2.completed.load(.acquire) < 150) {
    mb.render();
    try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
}

t1.join();
t2.join();

mb.done();
```

This pattern keeps worker code clean, extremely modular, and guarantees perfectly fluid terminal rendering at constant frame rates without any thread locks.

---

## 4. Custom Coloring

You can apply custom colors to each individual progress bar in `MultiBar` or spinner in `MultiSpinner`:

### MultiBar Task Colors
```zig
const bar1 = mb.addBar(.{
    .label = "Task A",
    .total = 100,
    .color = .cyan, // Custom global color for this bar line
});

const bar2 = mb.addBar(.{
    .label = "Task B",
    .total = 150,
    .fill_color = .green, // Custom filled block color
});
```

### MultiSpinner Item Colors
For `MultiSpinner`, you can configure styling directly on each added `SpinnerItem`:

```zig
const item1 = ms.addItem("Fetching data", .dots);
item1.color = .cyan; // Whole line colored cyan

const item2 = ms.addItem("Processing", .arc);
item2.color = .bright_blue; // Global color
item2.text_color = .bright_white; // White text override
item2.spinner_color = .bright_red; // Red spinner glyph override
```

### Customizable Spacing Gaps

For concurrent progress setups, you can override default gaps directly:

- **`MultiBar`**: Respects standard progress bar config options (`icon_gap`, `label_gap`, `datetime_gap`) per added bar:
  ```zig
  const bar = mb.addBar(.{
      .label = "Asset A",
      .total = 100,
      .label_gap = "  ", // 2 spaces after label
  });
  ```
- **`MultiSpinner`**: Configure spacing via `MultiSpinnerOptions` when starting:
  - **`icon_gap`**: Gap printed after running icons/messages (defaults to `" "`).
  - **`text_gap`**: Gap printed after active frame spinner symbols / completed status checkmarks (defaults to `" "`).
  ```zig
  const ms = try MultiSpinner.start(io, .stderr(), .{
      .allocator = allocator,
      .icon_gap = "   ",   // space after wide prefix emoji icons
      .text_gap = "  ",
  });
  ```

### Layout Spacing Margins

You can configure empty spacing line margins to render *in between* each individual progress bar or spinner item in concurrent layouts:

- **`MultiBar`**: Pass `spacing_lines` inside `MultiBarOptions` when initializing:
  ```zig
  var mb = loaders.MultiBar.init(io, file, null, .{
      .spacing_lines = 1, // 1 blank line between each progress bar
  });
  ```
- **`MultiSpinner`**: Pass `spacing_lines` inside `MultiSpinnerOptions` when starting:
  ```zig
  const ms = try loaders.MultiSpinner.start(io, .stderr(), .{
      .allocator = allocator,
      .spacing_lines = 1, // 1 blank line between each spinner item
  });
  ```
