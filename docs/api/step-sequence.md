---
title: StepSequence API
description: StepSequence API reference — ordered multi-step pipelines with spinner or bar per step.
---

# Step Sequence

`StepSequence` runs an ordered list of steps, each backed by a spinner or a progress bar, with success/failure/skip states and a summary.

```zig
const seq = try loaders.StepSequence.init(allocator, io, config);
```

## Config

```zig
pub const StepSequenceConfig = struct {
    interval_ms: u32 = 60,
};
```

## Types

```zig
pub const StepStatus = enum { pending, running, completed, failed, skipped };

pub const StepKind = union(enum) {
    spinner: SpinnerConfig,
    bar: ProgressBarConfig,
};

pub const StepConfig = struct {
    name: []const u8,
    kind: StepKind,
};
```

## Methods

| Method | Description |
|--------|-------------|
| `init(allocator, io, config) !StepSequence` | Create. |
| `deinit()` | Stop the render thread (if any). |
| `addStep(StepConfig) !usize` | Add a step; returns its index. |
| `startStep(index) !void` | Start a step. |
| `completeStep(index, FinishConfig)` | Mark a step completed (with `final_text`/`newline`). |
| `failStep(index, ?message)` | Mark a step failed, optionally with a message. |
| `skipStep(index)` | Mark a step skipped. |
| `runAll(context, runner)` | Run every step; `runner: *const fn (?*anyopaque, []const u8) void` receives the step name. |
| `statusOf(index) StepStatus` | Status of a step. |
| `barOf(index) *ProgressBar` | The bar widget of a bar step. |
| `spinnerOf(index) *Spinner` | The spinner widget of a spinner step. |
| `printSummary()` | Print a checkmark/cross summary of all steps. |

## Example

```zig
var seq = try loaders.StepSequence.init(allocator, io, .{});
defer seq.deinit();

_ = try seq.addStep(.{ .name = "Install", .kind = .{ .spinner = .{
    .frames = &.{ ".", "..", "..." },
    .template = "{frame} Installing...",
} } });
_ = try seq.addStep(.{ .name = "Build", .kind = .{ .bar = .{
    .total = 100,
    .template = "{bar} {percent}%",
} } });

try seq.startStep(0);
// ... do work ...
seq.completeStep(0, .{});
```