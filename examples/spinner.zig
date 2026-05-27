const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Initialize the best and fastest allocator pattern:
    // A high-performance ArenaAllocator wrapping the standard page_allocator.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 1. Dots spinner
    {
        std.debug.print("--- Running Dots Spinner ---\n", .{});
        const sp = try loaders.Spinner.start(io, .{
            .text = "Initializing system...",
            .style = loaders.SpinnerStyle.dots,
            .allocator = allocator,
        });

        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.setText("Loading plugins...");
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);

        sp.succeed(io, "System initialized successfully!");
    }

    // 2. Line spinner
    {
        std.debug.print("\n--- Running Line Spinner ---\n", .{});
        const sp = try loaders.Spinner.start(io, .{
            .text = "Downloading assets...",
            .style = loaders.SpinnerStyle.line,
            .allocator = allocator,
        });

        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);
        sp.setText("Unpacking assets...");
        try io.sleep(std.Io.Duration.fromSeconds(1), .awake);

        sp.warn(io, "Assets unpacked with warnings.");
    }

    // 3. Moon spinner
    {
        std.debug.print("\n--- Running Moon Spinner ---\n", .{});
        const sp = try loaders.Spinner.start(io, .{
            .text = "Synchronizing database...",
            .style = loaders.SpinnerStyle.moon,
            .allocator = allocator,
        });

        try io.sleep(std.Io.Duration.fromSeconds(2), .awake);

        sp.info(io, "Database synchronized.");
    }
}
