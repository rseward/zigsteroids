const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Optional sysroot used when cross-compiling (e.g. for Raspberry Pi).
    //
    // raylib links against system libraries (X11, GLX, GL, ...) via
    // `linkSystemLibrary`, which uses the `paths_first` search strategy. That
    // strategy only searches directories explicitly registered on the module,
    // so for a non-native target it cannot discover the target's libraries on
    // its own. When a sysroot is supplied we register the sysroot's multiarch
    // library and header directories on both the executable and the raylib
    // artifact so those system libraries resolve during cross-compilation.
    //
    // Populate the sysroot from the target machine, for example by rsyncing the
    // Pi's root filesystem or mounting its SD card, then pass it with
    // `-Dsysroot=/path/to/pi-rootfs`.
    const sysroot = b.option([]const u8, "sysroot", "Sysroot directory for cross-compilation") orelse "";

    // Linux display backend handed through to raylib's GLFW. Defaults to X11,
    // which is what most desktops use. On a Wayland-only desktop (such as a
    // Raspberry Pi 5 running Raspberry Pi OS Bookworm's labwc) GLX context
    // creation over Xwayland can fail with `GLXBadFBConfig`; building with
    // `-Dlinux_display_backend=wayland` makes GLFW use EGL on Wayland directly
    // and avoids the problem. `both` enables both backends in the GLFW build.
    const DisplayBackend = enum { x11, wayland, both };
    const display_backend = b.option(DisplayBackend, "linux_display_backend", "Linux display backend: x11, wayland, or both") orelse .x11;
    // raylib_zig's `linux_display_backend` option is the enum { X11, Wayland,
    // Both }; forwarding the tag name as a string lets the dependency's
    // `b.option` parse it into its own enum type.
    const rl_display_backend: []const u8 = switch (display_backend) {
        .x11 => "X11",
        .wayland => "Wayland",
        .both => "Both",
    };

    // OpenGL API version handed through to raylib. Defaults to `auto`, which
    // means desktop OpenGL on the Linux desktop backends. On a Raspberry Pi 5
    // the V3D driver exposes OpenGL ES via EGL (Wayland); requesting desktop GL
    // there makes `eglCreateContext` fail with "Arguments are inconsistent", so
    // build with `-Dopengl_version=gles_3` (or `gles_2`) on the Pi.
    const OpenglVersion = enum { auto, gl_1_1, gl_2_1, gl_3_3, gl_4_3, gles_2, gles_3 };
    const opengl_version = b.option(OpenglVersion, "opengl_version", "OpenGL API version (auto = desktop GL)") orelse .auto;
    const rl_opengl_version: []const u8 = switch (opengl_version) {
        .auto => "auto",
        .gl_1_1 => "gl_1_1",
        .gl_2_1 => "gl_2_1",
        .gl_3_3 => "gl_3_3",
        .gl_4_3 => "gl_4_3",
        .gles_2 => "gles_2",
        .gles_3 => "gles_3",
    };

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = rl_display_backend,
        .opengl_version = rl_opengl_version,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // raylib's Linux desktop (GLFW) Wayland path links EGL/wayland/xkbcommon but
    // does not link the OpenGL ES library. With `opengl_version` set to GLES the
    // GL entry points are called directly (not via the runtime glad loader), so
    // link libGLESv2 explicitly to resolve them.
    if (opengl_version == .gles_2 or opengl_version == .gles_3) {
        raylib_artifact.root_module.linkSystemLibrary("GLESv2", .{});
    }

    const exe = b.addExecutable(.{
        .name = "lsr",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    if (sysroot.len > 0) {
        // Debian/Raspberry Pi OS style multiarch tuple, e.g. "aarch64-linux-gnu".
        const multiarch = std.fmt.allocPrint(b.allocator, "{s}-{s}-{s}", .{
            @tagName(target.result.cpu.arch),
            @tagName(target.result.os.tag),
            @tagName(target.result.abi),
        }) catch unreachable;

        const lib_dirs = [_][]const u8{
            b.pathJoin(&.{ "usr/lib", multiarch }),
            "usr/lib",
            b.pathJoin(&.{ "lib", multiarch }),
            "lib",
        };
        const inc_dirs = [_][]const u8{
            "usr/include",
            b.pathJoin(&.{ "usr/include", multiarch }),
        };

        for (lib_dirs) |d| {
            const p = b.pathJoin(&.{ sysroot, d });
            raylib_artifact.root_module.addLibraryPath(.{ .cwd_relative = p });
            exe.root_module.addLibraryPath(.{ .cwd_relative = p });
        }
        for (inc_dirs) |d| {
            const p = b.pathJoin(&.{ sysroot, d });
            raylib_artifact.root_module.addSystemIncludePath(.{ .cwd_relative = p });
            exe.root_module.addSystemIncludePath(.{ .cwd_relative = p });
        }
    }

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "run");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
