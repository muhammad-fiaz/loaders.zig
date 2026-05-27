# loaders.zig — High Performance Loading Indicators for Zig

`loaders.zig` is a complete, production-ready, customisable terminal loading indicator and progress bar library written in **pure Zig 0.16.0** with **zero external dependencies**.

It is designed to be extremely lightweight, robust, thread-safe, and visual-first. It handles raw terminal capabilities, ANSI coloring, auto-sizing, and CI/redirection environments automatically out of the box.

---

## High-Level Capabilities

- **Stunning Visuals**: Sleek block indicators, gradient fills, styled ticks, and 18+ beautiful preset spinner structures.
- **Pure Zig**: Built from the ground up utilizing only standard library structures and the new `std.Io` concrete buffered interface.
- **Dynamic Sizing**: Automatically queries terminal widths on POSIX and Windows consoles.
- **Thread-Safety**: Safely spawn workers that update bar values atomically while a main thread orchestrates UI redraws.
- **Non-blocking Spinners**: Offload spinner animation and frame ticks to background threads with straightforward completion states (✓ Success, ✗ Failure, etc.).
- **Automatic Output Sanitization**: Detects redirection, file piping, dumb terminals, and NO_COLOR environment flags to cleanly suppress ANSI escapes.

---

## Documentation Articles

Start building beautiful terminal interfaces today:

1. **[Guide Overview](guide/)**: Start here for the walkthrough articles.
2. **[API Reference](api/)**: Full API listing of types, options, and methods.
3. **[Getting Started](guide/getting-started)**: Add your first progress bar and spinner in minutes.
4. **[Progress Bars](guide/progress-bar)**: Customize and operate single progress bars.
5. **[Spinners](guide/spinner)**: Run animated spinners in background worker threads.
6. **[Multi-Progress Rendering](guide/multi-progress)**: Coordinate and animate multiple bars concurrently.
7. **[Styling Options](guide/styling)**: Learn how to configure custom brackets, fills, and edges.
8. **[Visual Themes Presets](guide/themes)**: Browse all pre-packaged designs.
9. **[ANSI Color Support](guide/colors)**: Harness true 24-bit RGB and 256-color palettes.
10. **[Advanced Techniques](guide/advanced)**: CI environment checking, TTY logic, custom drawing targets, and custom worker integration.
