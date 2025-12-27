const std = @import("std");
const rl = @import("raylib-zig/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib = rl.getModule(b, target, optimize);

    const exe = b.addExecutable(.{ .name = "lsr", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });

    rl.link(b, exe, target, optimize);
    exe.root_module.addImport("raylib", raylib);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "run");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
