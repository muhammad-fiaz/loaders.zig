---
description: Five concurrent spinners with per-item colors, different styles, and staggered finish states using loaders.zig MultiSpinner.
head:
  - - meta
    - name: keywords
      content: loaders.zig multi spinner, zig concurrent spinners, multi spinner example
  - - meta
    - property: og:title
      content: Multi Spinner Example — loaders.zig
  - - meta
    - property: og:description
      content: Five concurrent spinners with per-item colors and staggered finish states.
---

# Multi Spinner

5 concurrent spinners with per-item colors and staggered finish states (succeed, fail, warn).

---

## Source

```zig
const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const io = init.io;

    const ms = try loaders.MultiSpinner.start(io, std.Io.File.stderr(), null, allocator);
    errdefer ms.stop();

    const fetch = ms.addItem("Fetching data from API", loaders.SpinnerStyle.dots);
    const parse = ms.addItem("Parsing JSON response", loaders.SpinnerStyle.arc);
    const build = ms.addItem("Compiling assets", loaders.SpinnerStyle.aesthetic);
    const upload = ms.addItem("Uploading to CDN", loaders.SpinnerStyle.pulse);
    const check = ms.addItem("Running health checks", loaders.SpinnerStyle.wifi);

    fetch.icon = "📥";
    parse.icon = "⚙️";
    build.icon = "🏗️";
    upload.icon = "📤";
    check.icon = "🩺";

    fetch.color = .cyan;
    parse.color = .bright_yellow;
    build.color = .{ .rgb = .{ .r = 160, .g = 100, .b = 255 } };
    upload.color = .bright_blue;
    check.color = .green;

    fetch.suffix = "(50 KB/s)";

    io.sleep(std.Io.Duration.fromMilliseconds(800), .awake) catch {};
    ms.setSucceeded(fetch, "Data fetched (128 records)");

    io.sleep(std.Io.Duration.fromMilliseconds(600), .awake) catch {};
    ms.setSucceeded(parse, "JSON parsed successfully");

    io.sleep(std.Io.Duration.fromMilliseconds(1200), .awake) catch {};
    ms.setFailed(build, "Compilation failed: missing symbol");

    io.sleep(std.Io.Duration.fromMilliseconds(400), .awake) catch {};
    ms.setWarning(upload, "Upload skipped (CDN unreachable)");

    io.sleep(std.Io.Duration.fromMilliseconds(700), .awake) catch {};
    ms.setSucceeded(check, "All health checks passed");

    io.sleep(std.Io.Duration.fromMilliseconds(200), .awake) catch {};
    ms.stop();
}
```

## Run

```bash
zig build run-multi_spinner
```

## Output

```
⠹ Fetching data from API (50 KB/s)
◝ Parsing JSON response
▰▰▰▰▰▰▱▱ Compiling assets
◉ Uploading to CDN
▁▃▅▇▅ Running health checks
✓ Data fetched (128 records)
◝ JSON parsed successfully
✗ Compilation failed: missing symbol
⚠ Upload skipped (CDN unreachable)
✓ All health checks passed
```

Items complete at different times. Each gets a colored status glyph when done.
