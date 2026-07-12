---
description: Render and coordinate multiple progress bars concurrently using BatchBar. Inline task configuration, worker synchronization patterns.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi progress, zig multi bar, concurrent progress bars, terminal multi progress, batch bar
  - - meta
    - property: og:title
      content: Multi-Progress Rendering Guide — loaders.zig
  - - meta
    - property: og:description
      content: Render and coordinate multiple progress bars concurrently using BatchBar.
---

# Multi-Progress Rendering Guide

This article covers rendering and coordinating multiple progress bars concurrently using `BatchBar`.

---

## 1. Concepts and Screen Layout

Standard progress bars operate by drawing their state, returning the cursor to the beginning of the line with a carriage return (`\r`), and overwriting the line on the next update. This only works for a single bar.

To render multiple bars, `BatchBar` coordinates the layout:
1. It registers child tasks (each a progress bar).
2. When you call `bb.render()`, it draws each bar on its own line, separated by newlines (`\n`).
3. On the next draw cycle, it uses terminal ANSI escape sequences to move the cursor up by the number of bars, erases each line, and redraws the bars from top to bottom.

This creates the illusion of multiple independently animated bars.

---

## 2. Basic Setup — Inline Task Configuration

The simplest way to run multiple bars is to define tasks inline at init time:

```zig
var bb = loaders.BatchBar.init(io, .{
    .title = "My Tasks",
    .tasks = &.{
        .{ .name = "Task 1", .total = 100, .color = .cyan },
        .{ .name = "Task 2", .total = 150, .color = .green },
    },
});

// Update tasks by index
bb.setCompleted(0, 50);
bb.setCompleted(1, 75);
bb.render();

bb.done();
```

Each `TaskInit` entry defines:
- `name` — Label for the task
- `total` — Total units for the task
- `color` — Optional color for the task's bar line

---

## 3. Worker Synchronization Pattern

Since `BatchBar` progress updates are thread-safe, you can offload work to separate background threads and let them update their bars independently:

```zig
const Context = struct {
    bar_idx: usize,
    bb: *loaders.BatchBar,
    io: std.Io,
};

fn worker(ctx: Context) void {
    for (0..100) |i| {
        ctx.bb.setCompleted(ctx.bar_idx, i + 1);
        ctx.io.sleep(std.Io.Duration.fromMilliseconds(50), .awake) catch {};
    }
}

// In your main thread:
const t1 = try std.Thread.spawn(.{}, worker, .{Context{ .bar_idx = 0, .bb = &bb, .io = io }});
const t2 = try std.Thread.spawn(.{}, worker, .{Context{ .bar_idx = 1, .bb = &bb, .io = io }});

// Main thread acts as the rendering coordinator
while (bb.completed[0] < 100 or bb.completed[1] < 150) {
    bb.render();
    try io.sleep(std.Io.Duration.fromMilliseconds(30), .awake);
}

t1.join();
t2.join();

bb.done();
```

This pattern keeps worker code clean, extremely modular, and guarantees perfectly fluid terminal rendering at constant frame rates without any thread locks.

---

## 4. Custom Coloring

You can apply custom colors to each individual progress bar via `TaskInit`:

### Inline Task Colors
```zig
var bb = loaders.BatchBar.init(io, .{
    .title = "Downloads",
    .tasks = &.{
        .{ .name = "Task A", .total = 100, .color = .cyan },
        .{ .name = "Task B", .total = 150, .color = .green },
    },
});
```

### Layout Spacing Margins

You can configure empty spacing line margins to render *in between* each individual progress bar:

- **`BatchBar`**: Pass `spacing_lines` inside `BatchOptions` when initializing:
  ```zig
  var bb = loaders.BatchBar.init(io, .{
      .title = "Build Pipeline",
      .spacing_lines = 1, // 1 blank line between each progress bar
      .tasks = &.{
          .{ .name = "Compile", .total = 100 },
          .{ .name = "Link", .total = 50 },
      },
  });
  ```
