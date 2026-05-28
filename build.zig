const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the loaders module
    const loaders_module = b.createModule(.{
        .root_source_file = b.path("src/loaders.zig"),
    });

    // Expose the module for external projects
    _ = b.addModule("loaders", .{
        .root_source_file = b.path("src/loaders.zig"),
    });

    // Build examples
    const examples = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "01_basic_bar", .path = "examples/01_basic_bar.zig" },
        .{ .name = "02_styled_bar", .path = "examples/02_styled_bar.zig" },
        .{ .name = "basic_bar", .path = "examples/basic_bar.zig" },
        .{ .name = "spinner", .path = "examples/spinner.zig" },
        .{ .name = "multi_spinner", .path = "examples/multi_spinner.zig" },
        .{ .name = "multi_progress", .path = "examples/multi_progress.zig" },
        .{ .name = "custom_style", .path = "examples/custom_style.zig" },
        .{ .name = "download_simulation", .path = "examples/download_simulation.zig" },
        .{ .name = "nested_bars", .path = "examples/nested_bars.zig" },
        .{ .name = "eta_and_rate", .path = "examples/eta_and_rate.zig" },
        .{ .name = "themed_bar", .path = "examples/themed_bar.zig" },
        .{ .name = "iterator_wrap", .path = "examples/iterator_wrap.zig" },
        .{ .name = "custom_template", .path = "examples/custom_template.zig" },
        .{ .name = "advanced_options", .path = "examples/advanced_options.zig" },
        .{ .name = "animations", .path = "examples/animations.zig" },
    };

    // Create run-all-examples step
    const run_all_examples = b.step("run-all-examples", "Run all examples sequentially");
    var previous_run_step: ?*std.Build.Step = null;

    inline for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example.path),
                .target = target,
                .optimize = optimize,
            }),
        });
        exe.root_module.addImport("loaders", loaders_module);

        const install_exe = b.addInstallArtifact(exe, .{});
        const example_step = b.step("example-" ++ example.name, "Build " ++ example.name ++ " example");
        example_step.dependOn(&install_exe.step);

        const run_exe = b.addRunArtifact(exe);
        run_exe.step.dependOn(&install_exe.step);
        const run_step = b.step("run-" ++ example.name, "Run " ++ example.name ++ " example");
        run_step.dependOn(&run_exe.step);

        // Add to run-all-examples
        const run_all_exe = b.addRunArtifact(exe);
        if (previous_run_step) |prev| {
            run_all_exe.step.dependOn(prev);
        }
        previous_run_step = &run_all_exe.step;
    }

    if (previous_run_step) |last| {
        run_all_examples.dependOn(last);
    }

    // Unit tests
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/loaders.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Library
    const lib = b.addLibrary(.{
        .name = "loaders_zig",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/loaders.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(lib);
}
