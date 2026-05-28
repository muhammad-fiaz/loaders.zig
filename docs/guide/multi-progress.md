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
