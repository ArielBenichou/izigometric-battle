const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose modules for others to import
    const core_module = b.addModule("core", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{},
    });

    // RAYLIB & RAYGUI
    const raylib_dep = b.dependency("raylib", .{
        .target = core_module.resolved_target.?,
        .optimize = core_module.optimize.?,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");
    core_module.linkLibrary(raylib_artifact);
    core_module.addImport("raylib", raylib);
    core_module.addImport("raygui", raygui);

    const lib = b.addStaticLibrary(.{
        .name = "core",
        .root_source_file = b.path("src/root.zig"),
        .version = std.SemanticVersion{ .major = 0, .minor = 0, .patch = 0 },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibCpp();
    b.installArtifact(lib);

    // TEST
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lib_unit_tests.step);
}
