---
description: BatchBar guide for loaders.zig v0.0.2 — track multiple named tasks with per-task progress bars in one grouped display.
head:
  - - meta
    - name: keywords
      content: loaders.zig batch progress, multi-task progress, BatchBar, zig task tracker
  - - meta
    - property: og:title
      content: Batch Progress — loaders.zig
---

# Batch Progress

`BatchBar` tracks multiple named tasks in a grouped display, each with its own progress bar, state indicator, and optional percentage.

---

## Quick Start

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var bb = loaders.BatchBar.init(io, .{
        .title       = "▶  Build Pipeline",
        .title_color = .bright_magenta,
        .show_percent = true,
        .style        = loaders.BarStyle.slim,
    });

    const compile = bb.addTask("Compile", 100);
    const link    = bb.addTask("Link   ", 50);
    const tests   = bb.addTask("Tests  ", 60);

    // ... advance tasks in your loop ...
    bb.setTaskCompleted(compile, 50);
    bb.render();

    bb.setTaskDone(compile);
    bb.setTaskFailed(link);
    bb.done();
}
```

---

## Task States

Each task has one of six states displayed with a visual glyph:

| State | Glyph | Color | Description |
|-------|-------|-------|-------------|
| `pending` | `○` | dim | Not yet started |
| `running` | `●` | cyan | Actively progressing |
| `done` | `✓` | green | Successfully completed |
| `failed` | `✗` | red | Failed |
| `warn` | `⚠` | yellow | Warning |
| `info` | `ℹ` | cyan | Information |

---

## `BatchOptions`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | `[]const u8` | `""` | Title line above all task bars |
| `title_color` | `Color` | `.bright_white` | Color of the title |
| `width` | `u16` | `0` | Bar width (0 = auto) |
| `style` | `BarStyle` | `BarStyle.slim` | Style for all task bars |
| `show_percent` | `bool` | `true` | Show percentage per task |
| `show_count` | `bool` | `false` | Show `n/total` per task |
| `file` | `?std.Io.File` | `null` | Output file (default: stderr) |
| `hide_cursor` | `bool` | `true` | Hide cursor during rendering |
| `icon` | `?[]const u8` | `null` | Optional running icon prefix |
| `success_icon` | `?[]const u8` | `null` | Custom success icon override |
| `failure_icon` | `?[]const u8` | `null` | Custom failure icon override |
| `warning_icon` | `?[]const u8` | `null` | Custom warning icon override |
| `info_icon` | `?[]const u8` | `null` | Custom info icon override |

---

## API Reference

### `init(io, opts) BatchBar`

Create a BatchBar with the given options.

### `addTask(name, total) usize`

Add a task with a display name and total step count.  
Returns the task **index** used for subsequent operations.  
Panics if `max_tasks` (32) is reached.

### `setTaskCompleted(idx, n) void`

Set the completed count for task `idx` (thread-safe via atomic).  
Automatically transitions state from `.pending` to `.running`.

### `incrementTask(idx) void`

Increment a task's completed count by 1 (thread-safe).

### `setTaskDone(idx) void`

Mark a task as successfully completed. Sets `completed = total`.

### `setTaskFailed(idx) void`

Mark a task as failed. The task bar stops progressing.

### `setTaskWarning(idx) void`

Mark a task as completed with a warning.

### `setTaskInfo(idx) void`

Mark a task as completed with an information status.

### `render() void`

Re-render all task bars in-place. Call from your main loop.

### `done() void`

Perform a final render and restore the cursor.

### `countByState(state) usize`

Count how many tasks are in a given `TaskState`.

### `allFinished() bool`

Returns `true` when all tasks are in `.done` or `.failed` state.

---

## Thread Safety

`BatchTask.completed` is an `atomic.Value(usize)`. You can safely call  
`setTaskCompleted` and `incrementTask` from background threads while the  
main thread calls `render`.

---

## Task Custom Colors

Each `BatchTask` returned by `addTask` can be styled with individual task colors:
- `color`: Global color for the entire task progress bar line (e.g. `.cyan`).
- `label_color`: Custom color for the task name/label (e.g. `.bright_yellow`).
- `fill_color`: Custom filled bar color (e.g. `.green`).
- `empty_color`: Custom empty bar color.

```zig
const compile = bb.addTask("Compile", 100);
bb.tasks[compile].color = .cyan;
bb.tasks[compile].label_color = .bright_yellow;
bb.tasks[compile].fill_color = .green;
bb.tasks[compile].empty_color = .bright_black;
```

---

## Customizable Spacing Gaps

To adjust spacing between prefix icons, status symbols (`✓`, `✗`, `●`), task names/labels, and the progress bar blocks, you can configure these options:

- **`icon_gap`**: Gap printed after running icons/prefixes (defaults to `" "`).
- **`state_gap`**: Gap printed after state glyph status indicators (defaults to `" "`).
- **`label_gap`**: Gap printed after task name/label (defaults to `" "`).

```zig
var bb = loaders.BatchBar.init(io, .{
    .icon = "⚙️",
    .icon_gap = "  ",  // wide gap after icon
    .state_gap = "   ", // padding before name
    .label_gap = "  ",
});
```

---

## Layout Spacing Margins

You can configure empty spacing line margins to render *in between* each individual task in a `BatchBar` using the `spacing_lines` option:

```zig
var bb = loaders.BatchBar.init(io, .{
    .title = "Build Pipeline",
    .spacing_lines = 1, // 1 blank line between each task
});
```

---

## Maximum Tasks

`BatchBar` supports up to **32 tasks** (`max_tasks`). This is a stack-allocated constant — no heap allocation is needed.

---

## Example: Build Pipeline

```zig
var bb = loaders.BatchBar.init(io, .{
    .title        = "Build Pipeline",
    .title_color  = .bright_cyan,
    .show_percent = true,
    .style        = loaders.BarStyle.slim,
    .icon         = "⚙️",
});

const compile = bb.addTask("Compile ", 80);
const lint    = bb.addTask("Lint    ", 40);
const tests   = bb.addTask("Tests   ", 60);

while (!bb.allFinished()) {
    // ... update tasks ...
    bb.render();
    try io.sleep(std.Io.Duration.fromMilliseconds(50), .awake);
}

bb.done();

std.debug.print(
    "Done: {d} succeeded, {d} failed\n",
    .{ bb.countByState(.done), bb.countByState(.failed) },
);
```
