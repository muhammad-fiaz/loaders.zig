---
title: Step Sequence Examples
description: StepSequence examples — ordered pipelines and summary output.
---

# Step Sequence Examples

## step_sequence_basic

Spinner and bar steps with `completeStep` / `failStep`:

```bash
zig build run-step_sequence_basic
```

```zig
var seq = try loaders.StepSequence.init(allocator, io, .{});
defer seq.deinit();

_ = try seq.addStep(.{ .name = "Install", .kind = .{ .spinner = .{
    .frames = &.{ ".", "..", "..." },
    .template = "{frame} Installing...",
} } });

try seq.startStep(0);
// ... do work ...
seq.completeStep(0, .{ .final_text = "Installed", .newline = true });
```

## step_runall

`runAll` runner with skip and summary printing:

```bash
zig build run-step_runall
```

```zig
fn runStep(ctx: ?*anyopaque, step_name: []const u8) void {
    _ = step_name;
    const io = @as(*std.Io.Threaded, @ptrCast(@alignCast(ctx))).io();
    loaders.sleepMs(io, 800);
}

seq.runAll(&threaded, runStep);
seq.printSummary();
```