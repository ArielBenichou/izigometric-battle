const std = @import("std");

const Target = struct {
    query: std.Target.Query,
    name: []const u8,
};

const targets = [_]Target{
    .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .macos }, .name = "aarch64-macos" },
    .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .linux }, .name = "aarch64-linux" },
    .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .name = "x86_64-linux-gnu" },
    .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl }, .name = "x86_64-linux-musl" },
    .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .windows }, .name = "x86_64-windows" },
};

const APP_NAME = "izigometric-battle";
const VERSION = "0.1.0+dev";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // =================
    // ==== INSTALL ====
    // =================
    const exe = try createExecutable(b, target, optimize);
    b.installArtifact(exe);

    // =============
    // ==== RUN ====
    // =============
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ==============
    // ==== TEST ====
    // ==============
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // =================
    // ==== RELEASE ====
    // =================
    if (true) return; // FIXME:
    const release_step = b.step("release", "Create release builds for all targets");

    for (targets) |t| {
        const target_query = b.resolveTargetQuery(t.query);
        const release_exe = try createExecutable(b, target_query, .ReleaseFast);

        const release_dir_name = try std.fmt.allocPrint(
            b.allocator,
            "{s}.{s}.{s}",
            .{ APP_NAME, VERSION, t.name },
        );

        // Create release directory
        const release_path = try std.fs.path.join(b.allocator, &.{ "releases", release_dir_name });
        const install_step = b.addInstallArtifact(release_exe, .{
            .dest_dir = .{ .override = .{ .custom = release_path } },
        });
        release_step.dependOn(&install_step.step);

        // Copy assets - use platform-specific commands
        // const copy_assets = if (t.query.os_tag == .windows) blk: {
        //     const cmd = b.addSystemCommand(&.{"xcopy"});
        //     cmd.addArgs(&.{ "/E", "/I", "/Y" });
        //     cmd.addArg("assets");
        //     cmd.addArg(release_path);
        //     break :blk cmd;
        // } else blk: {
        //     const cmd = b.addSystemCommand(&.{"cp"});
        //     cmd.addArgs(&.{ "-r", "assets" });
        //     cmd.addArg(release_path);
        //     break :blk cmd;
        // };
        // copy_assets.step.dependOn(&install_step.step);

        // Create zip file - use platform-specific commands
        // const zip_cmd = if (t.query.os_tag == .windows) blk: {
        //     const cmd = b.addSystemCommand(&.{"powershell"});
        //     cmd.addArgs(&.{
        //         "Compress-Archive",
        //         "-Path",
        //         release_dir_name,
        //         "-DestinationPath",
        //         try std.fmt.allocPrint(
        //             b.allocator,
        //             "{s}.zip",
        //             .{release_dir_name},
        //         ),
        //         "-Force",
        //     });
        //
        //     cmd.setCwd(.{ .src_path = .{ .owner = b, .sub_path = "releases" } });
        //     break :blk cmd;
        // } else blk: {
        //     const cmd = b.addSystemCommand(&.{"zip"});
        //     cmd.addArgs(&.{"-r"});
        //     cmd.addArg(try std.fmt.allocPrint(
        //         b.allocator,
        //         "{s}.zip",
        //         .{release_dir_name},
        //     ));
        //     cmd.addArg(release_dir_name);
        //     cmd.setCwd(.{ .src_path = .{ .owner = b, .sub_path = "releases" } });
        //     break :blk cmd;
        // };
        // zip_cmd.step.dependOn(&copy_assets.step);
        //
        // release_step.dependOn(&zip_cmd.step);
    }
}

fn createExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = APP_NAME,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibCpp();

    // Raylib & Raygui
    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // Core lib
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });
    const core = core_dep.module("core");
    exe.root_module.addImport("core", core);

    return exe;
}
