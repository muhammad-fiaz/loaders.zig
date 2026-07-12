const std = @import("std");
const loaders = @import("loaders");

const Lcg = struct {
    state: u32,
    pub fn init(seed: u32) Lcg {
        return .{ .state = seed };
    }
    pub fn next(self: *Lcg, min: u32, max: u32) u32 {
        self.state = self.state *% 1103515245 +% 12345;
        const val = (self.state / 65536) % 32768;
        return min + (val % (max - min + 1));
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    std.debug.print("--- Simulating 50 MB File Download ---\n", .{});

    const total_bytes: usize = 50 * 1024 * 1024; // 50 MB
    var rng = Lcg.init(42);

    var bar = loaders.ProgressBar.init(io, .{
        .label = "Downloading",
        .total = total_bytes,
        .show_percent = true,
        .show_count = true,
        .show_rate = true,
        .show_eta = true,
        .unit_is_bytes = true,
        .style = loaders.BarStyle.cyan,
    });

    var downloaded: usize = 0;
    while (downloaded < total_bytes) {
        // Chunk sizes between 200 KB and 2 MB
        const chunk = rng.next(200 * 1024, 2 * 1024 * 1024);
        downloaded = @min(downloaded + chunk, total_bytes);
        bar.setCompleted(downloaded);
        bar.render();
        try io.sleep(std.Io.Duration.fromMilliseconds(100), .awake);
    }

    bar.done();

    std.debug.print("Downloaded: output.bin\n", .{});
}
