---
description: Complete API reference for all exported types, options, and methods in loaders.zig. Bar, Spinner, BatchBar, Color, BarStyle, SpinnerStyle.
head:
  - - meta
    - name: keywords
      content: loaders.zig API, zig progress bar API, zig spinner API, BarOptions, SpinnerOptions, BarStyle, SpinnerStyle, Color
  - - meta
    - property: og:title
      content: API Reference — loaders.zig
  - - meta
    - property: og:description
      content: Complete API reference for all exported types, options, and methods in loaders.zig.
---

# loaders.zig API Reference

Complete API reference for all exported types, options, and methods.

---

## 1. Bar (Progress Bar)

### `loaders.ProgressBar`

Core progress bar structure. Thread-safe: `completed` and `total` are atomic values, so `setCompleted` / `increment` are safe to call from any thread. Rendering happens on the calling thread.

```zig
pub const Bar = struct {
    pub fn init(io: std.Io, opts: Options) Bar;
    pub fn setTotal(bar: *Bar, total: usize) void;
    pub fn setCompleted(bar: *Bar, n: usize) void;
    pub fn increment(bar: *Bar) void;
    pub fn incrementBy(bar: *Bar, n: usize) void;
    pub fn setMessage(bar: *Bar, msg: []const u8) void;
    pub fn render(bar: *Bar) void;
    pub fn renderContent(bar: *Bar, w: *std.Io.Writer) !void;
    pub fn done(bar: *Bar) void;
};
```

### `loaders.BarOptions`

Configuration passed to `Bar.init`.

```zig
pub const Options = struct {
    label: []const u8 = "",
    total: usize = 0,
    width: u16 = 0,
    style: BarStyle = .{},
    show_percent: bool = true,
    show_count: bool = false,
    show_elapsed: bool = false,
    show_eta: bool = false,
    show_rate: bool = false,
    unit_is_bytes: bool = false,
    unit: []const u8 = "",
    message: []const u8 = "",
    complete_message: []const u8 = "",
    suffix: []const u8 = "",
    file: ?std.Io.File = null,
    term: ?terminal.TermInfo = null,
    color_enabled: ?bool = null,
    custom_start: []const u8 = "",
    custom_end: []const u8 = "",
    show_date: bool = false,
    show_time: bool = false,
    timezone_offset_sec: i32 = 0,
    smooth_rate: bool = false,
    smooth_alpha: f64 = 0.2,
    template: []const u8 = "",
    min_interval_ms: u64 = 0,
    fill_color: Color = .default,
    empty_color: Color = .default,
    fill_gradient: ?Gradient = null,
    empty_gradient: ?Gradient = null,
    color: Color = .default,
    bg_color: Color = .default,
    complete_color: Color = .default,
    start_time_offset_sec: i64 = 0,
    padding_lines_above: usize = 0,
    padding_lines_below: usize = 0,
    initial_completed: usize = 0,
    success_icon: ?[]const u8 = null,
    failure_icon: ?[]const u8 = null,
    warning_icon: ?[]const u8 = null,
    info_icon: ?[]const u8 = null,
    disable_new_line: bool = true,
    messages: ?[]const []const u8 = null,
    message_interval_ms: u32 = 1500,
    on_progress: ?*const fn (bar: *Bar, completed: usize, total: usize) void = null,
    on_complete: ?*const fn (bar: *Bar) void = null,
    on_success: ?*const fn (bar: *Bar) void = null,
    on_failure: ?*const fn (bar: *Bar) void = null,
    on_warn: ?*const fn (bar: *Bar) void = null,
    on_info: ?*const fn (bar: *Bar) void = null,
    hide_after_done: bool = false,
    time_format_12h: bool = false,
    max_label_width: usize = 0,
    max_message_width: usize = 0,
    max_suffix_width: usize = 0,
};
```

| Field | Default | Description |
|-------|---------|-------------|
| `label` | `""` | Label printed before the bar |
| `total` | `0` | Total units (0 = indeterminate / bouncing) |
| `width` | `0` | Bar width in columns (0 = auto from terminal) |
| `style` | `.{}` | Visual style preset |
| `show_percent` | `true` | Show percentage |
| `show_count` | `false` | Show `current/total` counts |
| `show_elapsed` | `false` | Show elapsed time |
| `show_eta` | `false` | Show estimated time remaining |
| `show_rate` | `false` | Show throughput rate |
| `unit_is_bytes` | `false` | Format rate as bytes (B/s, KiB/s) |
| `unit` | `""` | Custom unit label (e.g. "files", "items") |
| `message` | `""` | Dynamic message after indicators |
| `complete_message` | `""` | Message shown when bar reaches 100% |
| `suffix` | `""` | Custom suffix after all indicators |
| `file` | `null` | Output file (null = stderr) |
| `term` | `null` | Terminal info override (null = auto-detect) |
| `color_enabled` | `null` | Color override (null = auto-detect) |
| `custom_start` | `""` | String at absolute start of line |
| `custom_end` | `""` | String at absolute end of line |
| `show_date` | `false` | Prepend `[YYYY-MM-DD]` |
| `show_time` | `false` | Prepend `[HH:MM:SS]` |
| `timezone_offset_sec` | `0` | UTC offset in seconds for date/time |
| `smooth_rate` | `false` | Use EMA to smooth rate/ETA display |
| `smooth_alpha` | `0.2` | EMA alpha for rate smoothing (0.0–1.0) |
| `template` | `""` | Custom format template (overrides standard layout) |
| `min_interval_ms` | `0` | Minimum milliseconds between renders |
| `fill_color` | `.default` | Fill color shorthand (sets style.fill_fg) |
| `empty_color` | `.default` | Empty color shorthand (sets style.empty_fg) |
| `fill_gradient` | `null` | Gradient for filled portion |
| `empty_gradient` | `null` | Gradient for empty portion |
| `color` | `.default` | Color for the entire bar line |
| `bg_color` | `.default` | Background color for the entire bar line |
| `complete_color` | `.default` | Color for filled portion when bar is complete |
| `start_time_offset_sec` | `0` | Custom elapsed time offset in seconds |
| `padding_lines_above` | `0` | Empty lines printed above the bar |
| `padding_lines_below` | `0` | Empty lines printed below the bar |
| `initial_completed` | `0` | Initial completed count |
| `success_icon` | `null` | Custom success icon (default "✓") |
| `failure_icon` | `null` | Custom failure icon (default "✗") |
| `warning_icon` | `null` | Custom warning icon (default "⚠") |
| `info_icon` | `null` | Custom info icon (default "ℹ") |
| `disable_new_line` | `true` | Disable newline for non-TTY output |
| `messages` | `null` | Slice of messages to cycle through |
| `message_interval_ms` | `1500` | Duration in ms to show each message |
| `on_progress` | `null` | Callback: `fn(bar, completed, total) void` |
| `on_complete` | `null` | Callback when bar completes/stops |
| `on_success` | `null` | Callback when `succeed()` is called |
| `on_failure` | `null` | Callback when `fail()` is called |
| `on_warn` | `null` | Callback when `warn()` is called |
| `on_info` | `null` | Callback when `info()` is called |
| `hide_after_done` | `false` | Erase bar line after completion |
| `time_format_12h` | `false` | Format time as 12-hour AM/PM |
| `max_label_width` | `0` | Max label width (0 = no limit) |
| `max_message_width` | `0` | Max message width (0 = no limit) |
| `max_suffix_width` | `0` | Max suffix width (0 = no limit) |

---

## 2. Spinner

### `loaders.Spinner`

Background-threaded spinner manager. Heap-allocated for pointer stability across threads.

```zig
pub const Spinner = struct {
    pub fn start(io: std.Io, opts: Options) !*Spinner;
    pub fn setText(sp: *Spinner, text: []const u8) void;
    pub fn stop(sp: *Spinner, io: std.Io) void;
    pub fn succeed(sp: *Spinner, io: std.Io, text: []const u8) void;
    pub fn fail(sp: *Spinner, io: std.Io, text: []const u8) void;
    pub fn warn(sp: *Spinner, io: std.Io, text: []const u8) void;
    pub fn info(sp: *Spinner, io: std.Io, text: []const u8) void;
};
```

### `loaders.SpinnerOptions`

Configuration passed to `Spinner.start`.

```zig
pub const Options = struct {
    text: []const u8 = "",
    style: SpinnerStyle = SpinnerStyle.dots,
    file: ?std.Io.File = null,
    term: ?terminal.TermInfo = null,
    color_enabled: ?bool = null,
    custom_start: []const u8 = "",
    custom_end: []const u8 = "",
    show_date: bool = false,
    show_time: bool = false,
    timezone_offset_sec: i32 = 0,
    allocator: ?std.mem.Allocator = null,
    interval_override_ms: ?u64 = null,
    suffix: []const u8 = "",
    show_elapsed: bool = false,
    text_color: Color = .default,
    spinner_color: Color = .default,
    color: Color = .default,
    success_icon: ?[]const u8 = null,
    failure_icon: ?[]const u8 = null,
    warning_icon: ?[]const u8 = null,
    info_icon: ?[]const u8 = null,
    messages: ?[]const []const u8 = null,
    message_interval_ms: u32 = 1500,
    time_format_12h: bool = false,
    max_text_width: usize = 0,
    max_suffix_width: usize = 0,
    text_bg_color: Color = .default,
    spinner_bg_color: Color = .default,
    bg_color: Color = .default,
    start_time_offset_sec: i64 = 0,
    complete_message: []const u8 = "",
    padding_lines_above: usize = 0,
    padding_lines_below: usize = 0,
    on_complete: ?*const fn (sp: *Spinner) void = null,
    on_success: ?*const fn (sp: *Spinner) void = null,
    on_failure: ?*const fn (sp: *Spinner) void = null,
    on_warn: ?*const fn (sp: *Spinner) void = null,
    on_info: ?*const fn (sp: *Spinner) void = null,
    hide_after_done: bool = false,
};
```

| Field | Default | Description |
|-------|---------|-------------|
| `text` | `""` | Text displayed next to spinner glyph |
| `style` | `.dots` | Spinner animation style |
| `file` | `null` | Output file (null = stderr) |
| `term` | `null` | Terminal info override |
| `color_enabled` | `null` | Color override |
| `custom_start` | `""` | String at absolute start of line |
| `custom_end` | `""` | String at absolute end of line |
| `show_date` | `false` | Prepend `[YYYY-MM-DD]` |
| `show_time` | `false` | Prepend `[HH:MM:SS]` |
| `timezone_offset_sec` | `0` | UTC offset in seconds |
| `allocator` | `null` | Custom allocator (null = page_allocator) |
| `interval_override_ms` | `null` | Override animation interval in ms |
| `suffix` | `""` | Suffix text after spinner text |
| `show_elapsed` | `false` | Show elapsed time after text |
| `text_color` | `.default` | Color for spinner text |
| `spinner_color` | `.default` | Color for spinner glyph |
| `color` | `.default` | Color for entire spinner line |
| `success_icon` | `null` | Custom success icon (default "✓") |
| `failure_icon` | `null` | Custom failure icon (default "✗") |
| `warning_icon` | `null` | Custom warning icon (default "⚠") |
| `info_icon` | `null` | Custom info icon (default "ℹ") |
| `messages` | `null` | Slice of messages to cycle through |
| `message_interval_ms` | `1500` | Duration in ms to show each message |
| `time_format_12h` | `false` | Format time as 12-hour AM/PM |
| `max_text_width` | `0` | Max text width (0 = no limit) |
| `max_suffix_width` | `0` | Max suffix width (0 = no limit) |
| `text_bg_color` | `.default` | Background color for spinner text |
| `spinner_bg_color` | `.default` | Background color for spinner glyph |
| `bg_color` | `.default` | Background color for entire spinner line |
| `start_time_offset_sec` | `0` | Custom elapsed time offset in seconds |
| `complete_message` | `""` | Message shown on succeed/fail |
| `padding_lines_above` | `0` | Empty lines printed above the spinner |
| `padding_lines_below` | `0` | Empty lines printed below the spinner |
| `on_complete` | `null` | Callback when spinner stops |
| `on_success` | `null` | Callback when `succeed()` is called |
| `on_failure` | `null` | Callback when `fail()` is called |
| `on_warn` | `null` | Callback when `warn()` is called |
| `on_info` | `null` | Callback when `info()` is called |
| `hide_after_done` | `false` | Erase spinner line after completion |

---

## 3. BarStyle

### `loaders.BarStyle`

Visual style for a progress bar.

```zig
pub const BarStyle = struct {
    left_bracket: []const u8 = "[",
    right_bracket: []const u8 = "]",
    fill: []const u8 = "█",
    empty: []const u8 = "░",
    tip: []const u8 = "",
    fill_fg: Color = .default,
    fill_bg: Color = .default,
    empty_fg: Color = .default,
    empty_bg: Color = .default,
    attrs: []const Attribute = &.{},
    fill_gradient: ?*const Gradient = null,
    empty_gradient: ?*const Gradient = null,
    complete_fg: Color = .default,
};
```

### Built-in Presets (18)

| Preset | Fill | Empty | Tip | Brackets | Color |
|--------|------|-------|-----|----------|-------|
| `block` | `█` | `░` | — | `[ ]` | default |
| `ascii` | `#` | ` ` | — | `[ ]` | default |
| `shaded` | `▓` | `░` | `▒` | `[ ]` | default |
| `green` | `█` | `░` | — | `[ ]` | green |
| `cyan` | `▓` | `░` | — | `[ ]` | cyan |
| `yellow` | `█` | `░` | — | `[ ]` | yellow (bold) |
| `red` | `█` | `░` | — | `[ ]` | red |
| `gradient` | `▓` | `░` | `▒` | `[ ]` | RGB green |
| `minimal` | `─` | `─` | `▶` | none | cyan |
| `blue` | `▓` | `░` | — | `[ ]` | blue (bold) |
| `magenta` | `▓` | `░` | — | `[ ]` | magenta |
| `fire` | `█` | `░` | `▓` | `[ ]` | RGB orange-red (bold) |
| `ice` | `█` | `░` | `▓` | `[ ]` | RGB blue-white |
| `ocean` | `▓` | `░` | `▒` | `[ ]` | RGB teal |
| `neon` | `█` | ` ` | `▓` | `⟦ ⟧` | RGB magenta (bold) |
| `arrow` | `=` | ` ` | `>` | `[ ]` | green |
| `dots` | `●` | `○` | — | ` ` | cyan |
| `slim` | `━` | `─` | `╸` | none | RGB green |

---

## 4. SpinnerStyle

### `loaders.SpinnerStyle`

Visual style for a spinner animation.

```zig
pub const SpinnerStyle = struct {
    frames: []const []const u8,
    interval_ms: u64 = 80,
    color: Color = .default,
    attrs: []const Attribute = &.{},
    gradient: ?*const Gradient = null,
    complete_fg: Color = .default,
};
```

### Built-in Presets (33)

| Preset | Frames | Speed | Color | Description |
|--------|--------|-------|-------|-------------|
| `dots` | `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` | 80ms | cyan | Braille dots animation |
| `dots2` | `⣾⣽⣻⢿⡿⣟⣯⣷` | 80ms | cyan | Dense braille pattern |
| `line` | `-\|/` | 100ms | white | Classic ASCII line spinner |
| `arc` | `◜◠◝◞◡◟` | 100ms | cyan | Smooth arc animation |
| `globe` | `🌍🌎🌏` | 200ms | default | Earth rotating emojis |
| `arrow` | `←↖↑↗→↘↓↙` | 100ms | yellow | Eight-direction arrow |
| `pulse` | `█▓▒░▒▓` | 100ms | green | Block pulse animation |
| `bounce` | `( ●    )...` | 80ms | cyan | Bouncing ball in parentheses |
| `clock` | `🕛🕐🕑...` | 100ms | default | Analog clock face emojis |
| `moon` | `🌑🌒🌓🌔🌕🌖🌗🌘` | 80ms | default | Moon phase emojis |
| `bars` | `▁▂▃▄▅▆▇█▇▆▅▄▃▂` | 80ms | RGB green | Vertical bar fill |
| `braille` | `⡀⡄⡆⡇⣇⣧⣷⣿...` | 60ms | bright_cyan | Fast braille matrix |
| `pong` | (30 frames) | 80ms | green | Pong-style bouncing dot |
| `weather` | `☀🌤⛅🌦🌧⛈🌩🌨❄...` | 200ms | default | Weather emoji sequence |
| `hearts` | `💛💙💜💚❤️` | 100ms | default | Heart fill animation |
| `box_bounce` | `╔═╗║╝═╚║` | 120ms | bright_blue | Box-drawing animation |
| `shark` | (26 frames) | 120ms | blue | Shark fin animation |
| `sand` | `⏳⌛` | 500ms | default | Hourglass sand animation |
| `wifi` | `▁▃▅▇▅▃` | 100ms | bright_green | WiFi signal strength |
| `charging` | `🔋🔋🔋⚡` | 200ms | default | Battery charging |
| `runner` | `🚶🏃` | 140ms | default | Running person emoji |
| `snake` | (33 frames) | 60ms | RGB green | Snake/coil animation |
| `hamburger` | `☱☲☴` | 100ms | yellow | Hamburger menu expansion |
| `flip` | `_ \ \| / _ \ \| /` | 100ms | cyan | Flipping box |
| `monkey` | `🙈🙉🙊` | 300ms | default | Monkey see emoji |
| `christmas_tree` | `🎄✨⭐` | 400ms | default | Christmas tree blink |
| `christmas` | `❄❅❆❅` | 120ms | bright_cyan | Snowflake alternation |
| `finger_dance` | `🤘🤙🖖✋🤚👋` | 160ms | default | Finger dance gestures |
| `mind_blown` | `😐😑😒🤔🤯💥✨` | 200ms | default | Mind-blown explosion |
| `speaker` | `🔈🔉🔊🔉` | 200ms | default | Speaker volume |
| `triangle` | `◢◣◤◥` | 100ms | bright_yellow | Circular triangle |
| `circle_pulse` | `◯◉●◉` | 120ms | magenta | Pulsing circle |
| `aesthetic` | (8 frames) | 80ms | RGB purple | Loading bar within glyph |

---

## 5. Color

### `loaders.Color`

ANSI color specifications as a tagged union.

```zig
pub const Color = union(enum) {
    // Standard 16-color ANSI
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,

    // Extended colors
    ansi256: u8,         // 256-color palette (index 0-255)
    rgb: struct { r: u8, g: u8, b: u8 },  // 24-bit true color

    // No color
    default,

    pub fn fgCode(c: Color, buf: []u8) []const u8;
    pub fn bgCode(c: Color, buf: []u8) []const u8;
};
```

### Color Tiers

| Tier | Type | Example |
|------|------|---------|
| **Standard** | 16 ANSI colors | `.red`, `.bright_cyan` |
| **256-color** | 8-bit palette | `.{ .ansi256 = 196 }` |
| **True Color** | 24-bit RGB | `.{ .rgb = .{ .r = 255, .g = 128, .b = 0 } }` |

---

## 6. Attribute

### `loaders.Attribute`

ANSI text attributes.

```zig
pub const Attribute = enum(u8) {
    bold = 1,
    dim = 2,
    italic = 3,
    underline = 4,
    blink = 5,
    blink_rapid = 6,
    reverse = 7,
    hidden = 8,
    strikethrough = 9,
};
```

---

## 7. Colorizer

### `loaders.Colorizer`

Controls whether color output is active. All methods emit empty strings when `enabled == false`.

```zig
pub const Colorizer = struct {
    enabled: bool,
    ansi_enabled: bool = true,
    cr_enabled: bool = true,

    pub fn begin(self: Colorizer, w: *std.Io.Writer, fg: Color, bg: Color, attrs: []const Attribute) !void;
    pub fn reset(self: Colorizer, w: *std.Io.Writer) !void;
    pub fn clearLine(self: Colorizer, w: *std.Io.Writer) !void;
    pub fn cursorUp(self: Colorizer, w: *std.Io.Writer, n: usize) !void;
    pub fn cr(self: Colorizer, w: *std.Io.Writer) !void;
    pub fn hideCursor(self: Colorizer, w: *std.Io.Writer) !void;
    pub fn showCursor(self: Colorizer, w: *std.Io.Writer) !void;
};
```

---

## 8. TermInfo

### `loaders.TermInfo`

Terminal capability information.

```zig
pub const TermInfo = struct {
    is_tty: bool,
    ansi_supported: bool,
    cols: u16,

    pub const dumb: TermInfo;
};
```

| Field | Description |
|-------|-------------|
| `is_tty` | Whether the file descriptor is a TTY |
| `ansi_supported` | Whether ANSI escape codes are supported |
| `cols` | Terminal width in columns (default 80 if unknown) |

---

## 9. UpdateChecker

### `loaders.UpdateChecker`

Optional GitHub release update checker. Requires network access at runtime.

```zig
pub const UpdateChecker = struct {
    pub const UpdateResult = struct {
        latest_raw: []const u8,
        latest: std.SemanticVersion,
        current: std.SemanticVersion,
        update_available: bool,
        order: std.math.Order,
    };

    pub fn check(allocator: std.mem.Allocator, io: std.Io) ?UpdateResult;
};
```

---

## 10. Gradient

### `loaders.Gradient`

Defines a color gradient with interpolation support.

```zig
pub const Gradient = struct {
    colors: []const Color,
    pub fn at(self: *const Gradient, t: f64) Color,
};
```

### Built-in Presets

| Preset | Description |
|--------|-------------|
| `Gradient.rainbow` | Full rainbow spectrum |
| `Gradient.fire` | Warm fire tones |
| `Gradient.ocean` | Cool ocean blues |
| `Gradient.sunset` | Sunset warmth |
| `Gradient.neon` | Bright neon |
| `Gradient.forest` | Forest greens |
| `Gradient.ice` | Icy blues |
| `Gradient.pastel` | Soft pastel rainbow |
| `Gradient.monochrome` | Grayscale |
| `Gradient.rainbow_reversed` | Reversed rainbow |

### Custom Gradient

```zig
const my_gradient = loaders.Gradient{
    .colors = &.{ .red, .yellow, .green },
};
```

The `at(t)` method accepts a `f64` from `0.0` to `1.0` and returns the interpolated `Color` at that position.

---

## 11. Module Exports

```zig
// Root module
pub const loaders = @import("loaders");

// Sub-modules
pub const utils = @import("utils.zig");
pub const color = @import("color.zig");
pub const terminal = @import("terminal.zig");
pub const style = @import("style.zig");
pub const bar = @import("bar.zig");
pub const spinner = @import("spinner.zig");
pub const batch = @import("batch.zig");
pub const version_info = @import("version.zig");

// Re-exports
pub const version: []const u8;  // "0.0.3"
pub const Bar = bar.Bar;
pub const BarOptions = bar.Options;
pub const Spinner = spinner.Spinner;
pub const SpinnerOptions = spinner.Options;
pub const BatchBar = batch.BatchBar;
pub const BatchOptions = batch.Options;
pub const TaskInit = batch.TaskInit;
pub const Color = color.Color;
pub const Rgb = color.Rgb;
pub const Attribute = color.Attribute;
pub const Colorizer = color.Colorizer;
pub const TermInfo = terminal.TermInfo;
pub const BarStyle = style.BarStyle;
pub const SpinnerStyle = style.SpinnerStyle;
pub const Gradient = style.Gradient;
pub const UpdateChecker = @import("update_checker.zig");
```
