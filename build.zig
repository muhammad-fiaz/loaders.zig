const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const loaders_mod = b.addModule("loaders", .{
        .root_source_file = b.path("src/loaders.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Tests
    const test_step = b.step("test", "Run all tests");

    const src_files = [_][]const u8{
        "src/utils.zig",
        "src/color.zig",
        "src/terminal.zig",
        "src/style.zig",
        "src/bar.zig",
        "src/spinner.zig",
        "src/multi.zig",
        "src/version.zig",
        "src/loaders.zig",
    };
    for (src_files) |src| {
        const t = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(src),
                .target = target,
                .optimize = optimize,
            }),
        });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }

    // Examples
    const examples = [_]struct { name: []const u8, src: []const u8 }{
        .{ .name = "01_basic_bar", .src = "examples/01_basic_bar.zig" },
        .{ .name = "02_styled_bar", .src = "examples/02_styled_bar.zig" },
        .{ .name = "basic_bar", .src = "examples/basic_bar.zig" },
        .{ .name = "spinner", .src = "examples/spinner.zig" },
        .{ .name = "multi_spinner", .src = "examples/multi_spinner.zig" },
        .{ .name = "multi_progress", .src = "examples/multi_progress.zig" },
        .{ .name = "custom_style", .src = "examples/custom_style.zig" },
        .{ .name = "download_simulation", .src = "examples/download_simulation.zig" },
        .{ .name = "nested_bars", .src = "examples/nested_bars.zig" },
        .{ .name = "eta_and_rate", .src = "examples/eta_and_rate.zig" },
        .{ .name = "themed_bar", .src = "examples/themed_bar.zig" },
        .{ .name = "iterator_wrap", .src = "examples/iterator_wrap.zig" },
        .{ .name = "custom_template", .src = "examples/custom_template.zig" },
        .{ .name = "advanced_options", .src = "examples/advanced_options.zig" },
        .{ .name = "animations", .src = "examples/animations.zig" },
    };

    const examples_step = b.step("examples", "Build all examples");
    const run_all_step = b.step("run-all-examples", "Run all examples in sequence");

    var prev_install_step: ?*std.Build.Step = null;
    var prev_run_step: ?*std.Build.Step = null;

    for (examples) |ex| {
        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(ex.src),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "loaders", .module = loaders_mod },
                },
            }),
        });

        // Force sequential compilation to avoid parallel LLVM OOM
        if (prev_install_step) |prev| {
            exe.step.dependOn(prev);
        }

        const install_step = &b.addInstallArtifact(exe, .{}).step;
        examples_step.dependOn(install_step);
        prev_install_step = install_step;

        const run_step = b.step(
            b.fmt("run-{s}", .{ex.name}),
            b.fmt("Run the {s} example", .{ex.name}),
        );
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        if (prev_run_step) |prev| {
            run_cmd.step.dependOn(prev);
        }
        prev_run_step = &run_cmd.step;
    }

    if (prev_run_step) |prev| {
        run_all_step.dependOn(prev);
    }
}
