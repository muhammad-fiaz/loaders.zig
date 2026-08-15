const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tint_dep = b.dependency("tint", .{});
    const tint_module = tint_dep.module("tint");

    const loaders_module = b.createModule(.{
        .root_source_file = b.path("src/loaders.zig"),
    });
    loaders_module.addImport("tint", tint_module);

    const public_module = b.addModule("loaders", .{
        .root_source_file = b.path("src/loaders.zig"),
    });
    public_module.addImport("tint", tint_module);

    const examples = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "basic_bar", .path = "examples/basic_bar.zig" },
        .{ .name = "basic_spinner", .path = "examples/basic_spinner.zig" },
        .{ .name = "custom_ascii_bar", .path = "examples/custom_ascii_bar.zig" },
        .{ .name = "custom_bracket_bar", .path = "examples/custom_bracket_bar.zig" },
        .{ .name = "block_bar", .path = "examples/block_bar.zig" },
        .{ .name = "indeterminate", .path = "examples/indeterminate.zig" },
        .{ .name = "template_with_eta_speed", .path = "examples/template_with_eta_speed.zig" },
        .{ .name = "runtime_style_swap", .path = "examples/runtime_style_swap.zig" },
        .{ .name = "runtime_frame_swap", .path = "examples/runtime_frame_swap.zig" },
        .{ .name = "manual_tick", .path = "examples/manual_tick.zig" },
        .{ .name = "external_thread", .path = "examples/external_thread.zig" },
        .{ .name = "auto_thread", .path = "examples/auto_thread.zig" },
        .{ .name = "multi_bar_sequential", .path = "examples/multi_bar_sequential.zig" },
        .{ .name = "multi_bar_parallel", .path = "examples/multi_bar_parallel.zig" },
        .{ .name = "batch_sequential", .path = "examples/batch_sequential.zig" },
        .{ .name = "batch_parallel_downloads", .path = "examples/batch_parallel_downloads.zig" },
        .{ .name = "batch_dynamic_messages", .path = "examples/batch_dynamic_messages.zig" },
        .{ .name = "step_sequence_basic", .path = "examples/step_sequence_basic.zig" },
        .{ .name = "step_runall", .path = "examples/step_runall.zig" },
        .{ .name = "custom_colors_rgb", .path = "examples/custom_colors_rgb.zig" },
        .{ .name = "custom_colors_hex", .path = "examples/custom_colors_hex.zig" },
        .{ .name = "custom_colors_dynamic_gradient", .path = "examples/custom_colors_dynamic_gradient.zig" },
        .{ .name = "pause_resume", .path = "examples/pause_resume.zig" },
        .{ .name = "text_updates", .path = "examples/text_updates.zig" },
        .{ .name = "dynamic_messages", .path = "examples/dynamic_messages.zig" },
        .{ .name = "dynamic_spinner_messages", .path = "examples/dynamic_spinner_messages.zig" },
        .{ .name = "spinner_looping_messages", .path = "examples/spinner_looping_messages.zig" },
        .{ .name = "spinner_conditional_messages", .path = "examples/spinner_conditional_messages.zig" },
        .{ .name = "infinite_spinner", .path = "examples/infinite_spinner.zig" },
        .{ .name = "infinite_progress_bar", .path = "examples/infinite_progress_bar.zig" },
        .{ .name = "clear_on_finish", .path = "examples/clear_on_finish.zig" },
        .{ .name = "fail_and_status", .path = "examples/fail_and_status.zig" },
        .{ .name = "callback_hooks", .path = "examples/callback_hooks.zig" },
        .{ .name = "state_accessor", .path = "examples/state_accessor.zig" },
        .{ .name = "starting_value", .path = "examples/starting_value.zig" },
        .{ .name = "indeterminate_timeout", .path = "examples/indeterminate_timeout.zig" },
        .{ .name = "progress_bar_unicode", .path = "examples/progress_bar_unicode.zig" },
        .{ .name = "progress_bar_countdown", .path = "examples/progress_bar_countdown.zig" },
        .{ .name = "spinner_braille", .path = "examples/spinner_braille.zig" },
        .{ .name = "progress_bar_countdown_eta", .path = "examples/progress_bar_countdown_eta.zig" },
    };

    const run_all_examples = b.step("run-all-examples", "Run all examples sequentially");
    const examples_step = b.step("examples", "Build all examples");
    var previous_run_step: ?*std.Build.Step = null;
    var previous_install_step: ?*std.Build.Step = null;

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

        if (previous_install_step) |prev| {
            exe.step.dependOn(prev);
        }

        const install_exe = b.addInstallArtifact(exe, .{});
        previous_install_step = &install_exe.step;
        examples_step.dependOn(&install_exe.step);

        const run_exe = b.addRunArtifact(exe);
        run_exe.stdio = .inherit;
        run_exe.step.dependOn(&install_exe.step);
        const run_step = b.step("run-" ++ example.name, "Run " ++ example.name ++ " example");
        run_step.dependOn(&run_exe.step);

        const run_all_exe = b.addRunArtifact(exe);
        run_all_exe.stdio = .inherit;
        run_all_exe.step.dependOn(&install_exe.step);
        if (previous_run_step) |prev| {
            run_all_exe.step.dependOn(prev);
        }
        previous_run_step = &run_all_exe.step;
    }

    if (previous_run_step) |last| {
        run_all_examples.dependOn(last);
    }

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/loaders.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("tint", tint_module);
    const tests = b.addTest(.{
        .root_module = test_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    const lib_module = b.createModule(.{
        .root_source_file = b.path("src/loaders.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_module.addImport("tint", tint_module);
    const lib = b.addLibrary(.{
        .name = "loaders",
        .linkage = .static,
        .root_module = lib_module,
    });
    b.installArtifact(lib);

    const docs_step = b.step("docs", "Generate library documentation");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);
}
