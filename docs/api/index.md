# loaders.zig API Reference

Below is the complete API reference for all exported structures, options, and methods in the library.

---

## 1. Bar (Progress Bar)

### `loaders.Bar`
Core progress bar structure.

```zig
pub const Bar = struct {
    /// Create a progress bar and start timing.
    pub fn init(io: std.Io, opts: Options) Bar;

    /// Update the total count limit.
    pub fn setTotal(bar: *Bar, total: usize) void;

    /// Atomically update the completed units.
    pub fn setCompleted(bar: *Bar, n: usize) void;

    /// Atomically increment completed units by 1.
    pub fn increment(bar: *Bar) void;

    /// Atomically increment completed units by n.
    pub fn incrementBy(bar: *Bar, n: usize) void;

    /// Render a single frame of the bar onto the target stream.
    pub fn render(bar: *Bar) void;

    /// Mark as completed and clean up terminal state.
    pub fn done(bar: *Bar) void;
};
```

### `loaders.BarOptions`
Configuration passed to `loaders.Bar.init`.

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
    suffix: []const u8 = "",
    file: ?std.Io.File = null,
    term: ?terminal.TermInfo = null,
    color_enabled: ?bool = null,

    // Customizations
    custom_start: []const u8 = "",
    custom_end: []const u8 = "",
    show_date: bool = false,
    show_time: bool = false,
    timezone_offset_sec: i32 = 0,
};
```

---

## 2. Spinner

### `loaders.Spinner`
Background-threaded spinner manager.

```zig
pub const Spinner = struct {
    /// Spawn background animation thread and start spinner.
    pub fn start(io: std.Io, opts: Options) !*Spinner;

    /// Atomically update spinner message text.
    pub fn setText(sp: *Spinner, text: []const u8) void;

    /// Stop spinner and clear it from terminal.
    pub fn stop(sp: *Spinner, io: std.Io) void;

    /// Stop spinner, print text with green checkmark (✓).
    pub fn succeed(sp: *Spinner, io: std.Io, text: []const u8) void;

    /// Stop spinner, print text with red crossmark (✗).
    pub fn fail(sp: *Spinner, io: std.Io, text: []const u8) void;

    /// Stop spinner, print text with yellow warning symbol (⚠).
    pub fn warn(sp: *Spinner, io: std.Io, text: []const u8) void;

    /// Stop spinner, print text with cyan info symbol (ℹ).
    pub fn info(sp: *Spinner, io: std.Io, text: []const u8) void;
};
```

### `loaders.SpinnerOptions`
Configuration passed to `loaders.Spinner.start`.

```zig
pub const Options = struct {
    text: []const u8 = "",
    style: SpinnerStyle = SpinnerStyle.dots,
    file: ?std.Io.File = null,
    term: ?terminal.TermInfo = null,
    color_enabled: ?bool = null,
    prefix: []const u8 = "",

    // Customizations
    custom_start: []const u8 = "",
    custom_end: []const u8 = "",
    show_date: bool = false,
    show_time: bool = false,
    timezone_offset_sec: i32 = 0,
    allocator: ?std.mem.Allocator = null,
};
```

---

## 3. Multi-Bar & Multi-Spinner

### `loaders.MultiBar`
Manages and renders multiple bars concurrently.

```zig
pub const MultiBar = struct {
    /// Initialize a multi-bar renderer.
    pub fn init(io: std.Io, file: std.Io.File, term_info: ?terminal.TermInfo) MultiBar;

    /// Create and register a child progress bar.
    pub fn addBar(mb: *MultiBar, opts: BarOptions) *Bar;

    /// Redraw all registered bars.
    pub fn render(mb: *MultiBar) void;

    /// Complete all bars.
    pub fn done(mb: *MultiBar) void;
};
```

### `loaders.MultiSpinner`
Manages and renders multiple spinners concurrently on separate lines via a single background thread.

```zig
pub const MultiSpinner = struct {
    /// Start the multi-spinner renderer with a background thread.
    pub fn start(io: std.Io, file: std.Io.File, color_enabled: ?bool, maybe_allocator: ?std.mem.Allocator) !*MultiSpinner;

    /// Create and register a child spinner item.
    pub fn addItem(ms: *MultiSpinner, text: []const u8, style: SpinnerStyle) *SpinnerItem;

    /// Stop all child spinners and free MultiSpinner resources.
    pub fn stop(ms: *MultiSpinner) void;
};
```

---

## 4. Visual Styles

### `loaders.BarStyle`
Preset visual progress configurations.

- `BarStyle.block`: Full block unicode fill `█░`.
- `BarStyle.shaded`: Shaded blocks `▓░▒`.
- `BarStyle.ascii`: Standard `#` and space brackets.
- `BarStyle.minimal`: No brackets, slim line `─▶─`.
- `BarStyle.green` / `BarStyle.cyan` / `BarStyle.yellow` / `BarStyle.red`: Colored presets.
- `BarStyle.gradient`: Solid fill with green-to-bright tip transitions.

---

## 5. Colors

### `loaders.Color`
ANSI color specifications.
- `.default`: Standard system color.
- `.black`, `.red`, `.green`, `.yellow`, `.blue`, `.magenta`, `.cyan`, `.white`.
- `.bright_black`, `.bright_red`, etc.
- `.rgb = .{ .r = U8, .g = U8, .b = U8 }`: Full 24-bit True Color.
