const std = @import("std");
const loaders = @import("loaders");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = std.heap.smp_allocator;

    std.debug.print("=== Loaders.zig: HTTP File Downloader Demo ===\n\n", .{});

    // 1. Set up the target URL and file path
    const url_str = "https://www.rd.usda.gov/sites/default/files/pdf-sample_0.pdf";
    const filename = "pdf-sample_0.pdf";

    // 2. Open output file in current directory
    var file = try std.Io.Dir.cwd().createFile(io, filename, .{});
    defer file.close(io);

    // 3. Set up progress bar with custom padding
    var bar = loaders.Bar.init(io, .{
        .label = "Downloading PDF",
        .total = 0, // Will be set dynamically from Content-Length
        .unit_is_bytes = true,
        .show_rate = true,
        .show_eta = true,
        .style = loaders.BarStyle.cyan,
        .padding_lines_above = 1,
        .padding_lines_below = 1,
    });
    defer bar.done();

    // 4. Initialize HTTP client
    var client = std.http.Client{ .allocator = allocator, .io = io };
    defer client.deinit();

    // Parse URI
    const uri = try std.Uri.parse(url_str);

    // Create GET request
    var req = try client.request(.GET, uri, .{
        .redirect_behavior = @enumFromInt(3),
        .extra_headers = &.{
            .{ .name = "User-Agent", .value = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" },
            .{ .name = "Accept", .value = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" },
            .{ .name = "Accept-Language", .value = "en-US,en;q=0.9" },
        },
    });
    defer req.deinit();

    // Send the bodiless request
    try req.sendBodiless();

    // Receive headers
    var redirect_buffer: [2048]u8 = undefined;
    var response = try req.receiveHead(&redirect_buffer);

    // Check status and fall back to W3C dummy PDF if USDA blocks the cloud runner
    if (response.head.status != .ok) {
        std.debug.print("Warning: HTTP request to USDA failed with status {} (common for cloud/CI IPs).\n", .{response.head.status});
        std.debug.print("Falling back to W3C public sample PDF...\n", .{});

        const fallback_url = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
        const fallback_uri = try std.Uri.parse(fallback_url);

        req.deinit();
        req = try client.request(.GET, fallback_uri, .{
            .redirect_behavior = @enumFromInt(3),
            .extra_headers = &.{
                .{ .name = "User-Agent", .value = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" },
            },
        });
        try req.sendBodiless();
        response = try req.receiveHead(&redirect_buffer);

        if (response.head.status != .ok) {
            std.debug.print("Error: Fallback request also failed with status {}\n", .{response.head.status});
            return;
        }
    }

    // Read Content-Length and update the progress bar's total limit
    const content_len = response.head.content_length orelse 0;
    if (content_len > 0) {
        bar.setTotal(content_len);
    }

    // 5. Wrap the file writer with progressIoWriter
    var file_writer_buf: [4096]u8 = undefined;
    var file_writer = std.Io.File.Writer.init(file, io, &file_writer_buf);

    var p_io_writer = loaders.progressIoWriter(&bar, &file_writer.interface);

    // 6. Stream from response reader directly into progress-wrapped file writer
    const reader = response.reader(&.{});
    _ = try reader.streamRemaining(p_io_writer.writer());

    std.debug.print("\nSuccessfully downloaded '{s}' to local workspace!\n", .{filename});
}
