---
title: Examples
description: All 40 loaders.zig examples — run them with zig build.
---

# Examples

All 40 examples live in the `examples/` directory. Build them all with:

```bash
zig build examples
```

Run every example sequentially:

```bash
zig build run-all-examples
```

Run a single example:

```bash
zig build run-<example-name>
```

## Progress Bars

| Example | What it shows |
|---------|---------------|
| `basic_bar` | Minimal bar with `{bar} {percent}%`. |
| `custom_ascii_bar` | ASCII `#`/`-`/`>` style. |
| `custom_bracket_bar` | Custom brackets and head characters. |
| `block_bar` | Block-based bar with partial fills. |
| `indeterminate` | Sliding segment for unknown progress. |
| `indeterminate_timeout` | Indeterminate bar with timeout auto-stop. |
| `manual_tick` | Manual `.none` thread mode with `tick()`. |
| `auto_thread` | `.auto` background-thread rendering. |
| `external_thread` | Updates from an external thread. |
| `starting_value` | `current` initial value, decremental direction. |
| `progress_bar_unicode` | Unicode block characters with color. |
| `progress_bar_countdown` | Countdown bar with decremental direction. |
| `progress_bar_countdown_eta` | Countdown with ETA and speed formatters. |

## Spinners

| Example | What it shows |
|---------|---------------|
| `basic_spinner` | Minimal spinner with `{frame} {text}`. |
| `dynamic_spinner_messages` | `setText` / `setColor` mid-run. |
| `spinner_looping_messages` | Cycling text messages. |
| `spinner_conditional_messages` | Phase-based text changes. |
| `infinite_spinner` | Auto-threaded infinite spinner with `stop`. |
| `spinner_braille` | Braille dot spinner frames. |

## Multi-Progress & Batch

| Example | What it shows |
|---------|---------------|
| `multi_bar_sequential` | MultiBar sequential mode. |
| `multi_bar_parallel` | MultiBar parallel mode. |
| `batch_sequential` | BatchRunner over a slice. |
| `batch_parallel_downloads` | Parallel workers with per-item + overall bars. |
| `batch_dynamic_messages` | Workers updating text dynamically. |

## Step Sequences

| Example | What it shows |
|---------|---------------|
| `step_sequence_basic` | Spinner and bar steps, `completeStep` / `failStep`. |
| `step_runall` | `runAll` runner, skip, summary printing. |

## Colors

| Example | What it shows |
|---------|---------------|
| `custom_colors_rgb` | Raw ANSI RGB strings. |
| `custom_colors_hex` | HEX → RGB escape sequences. |
| `custom_colors_dynamic_gradient` | Gradient computed per update. |

## Advanced

| Example | What it shows |
|---------|---------------|
| `template_with_eta_speed` | `{elapsed}` / `{eta}` / `{speed}` formatters. |
| `runtime_style_swap` | `setStyle` mid-run — Phase A → Phase B. |
| `runtime_frame_swap` | `setFrames` mid-run — ASCII → emoji → moon phases. |
| `pause_resume` | `pause` / `continue_` semantics. |
| `text_updates` | Dynamic text updates. |
| `dynamic_messages` | Text + color + style changes by phase. |
| `infinite_progress_bar` | Auto-threaded infinite bar, `fail` to stop. |
| `clear_on_finish` | `FinishConfig.clear` and post-run output via `stdoutWriter`. |
| `fail_and_status` | `fail` + `getStatus` checks. |
| `callback_hooks` | `on_tick` / `on_finish` / `on_pause` / `on_resume`. |
| `state_accessor` | Reading `state()` snapshots. |
