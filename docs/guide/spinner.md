# Terminal Spinners Guide

This article explains how to start, update, and manage thread-safe terminal spinners.

---

## 1. Thread-Safe Architecture

Command-line programs often execute heavy synchronous operations (e.g. DNS resolution, disk writes, compression). If you try to update an animated loader in the same main loop, the animation will freeze during the heavy operation.

`loaders.Spinner` resolves this by spawning a lightweight **background render thread** when you call `start`. This thread runs a loop that periodically refreshes the spinner frame at the preset interval (e.g. every 80ms) and updates the message.

---

## 2. Basic Usage

```zig
const sp = try loaders.Spinner.start(io, .{
    .text = "Uploading data...",
    .style = loaders.SpinnerStyle.dots,
});
// perform work
try io.sleep(std.Io.Duration.fromSeconds(2), .awake);
```

---

## 3. Updating Text Mid-Run

Updating the spinner text is completely thread-safe and can be done from any thread at any time:

```zig
sp.setText("Connecting to server...");
// ...
sp.setText("Uploading database table A...");
// ...
sp.setText("Uploading database table B...");
```

---

## 4. Setting Finish States

When your work is done, you can stop the spinner and print a final status indicator in place of the spinner animation:

- **`sp.succeed(io, text)`**: Prints a green checkmark (✓) and your text, stops the animation, and destroys the spinner.
- **`sp.fail(io, text)`**: Prints a red crossmark (✗), ideal for failures.
- **`sp.warn(io, text)`**: Prints a yellow warning symbol (⚠).
- **`sp.info(io, text)`**: Prints a cyan info symbol (ℹ).
- **`sp.stop(io)`**: Erases the spinner line entirely from the terminal screen.

```zig
if (success) {
    sp.succeed(io, "All files uploaded successfully!");
} else {
    sp.fail(io, "Connection timeout: upload failed.");
}
```
Notice that calling these methods automatically stops the render thread, cleans up memory, and frees the spinner pointer. No manual `stop` is needed if you call a status indicator method.
