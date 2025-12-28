# Zig 0.14 Migration Guide

This document describes the changes required to migrate the zigsteroids project from an older version of Zig to Zig 0.14.1.

## Overview

The migration involved updating the build system, source code, and dependencies to be compatible with breaking changes introduced in Zig 0.14. The main areas affected were:

- Build system API changes
- Standard library reorganization
- Raylib/raylib-zig API compatibility
- Enum naming conventions

## Build System Changes

### 1. Module Import API (`build.zig`)

**Before:**
```zig
exe.addModule("raylib", raylib);
exe.addModule("raylib-math", raylib_math);
```

**After:**
```zig
exe.root_module.addImport("raylib", raylib);
```

**Rationale:** Zig 0.14 moved module management to the `root_module` field. Additionally, we removed the separate `raylib-math` import since it's now accessible through `rl.math`.

### 2. raylib-zig Wrapper Updates (`raylib-zig/build.zig`)

#### Removed Unsupported Options

The following options were removed from the raylib dependency call as they're not supported by raylib 5.0:

```zig
// Removed:
.platform = options.platform,
.shared = options.shared,
.linux_display_backend = options.linux_display_backend,
.opengl_version = options.opengl_version,
.android_api_version = options.android_api_version,
.android_ndk = options.android_ndk,
```

Also removed the raygui dependency as it's not available in the project's build.zig.zon.

#### Fixed Module Paths

**Before:**
```zig
.root_source_file = b.path("lib/raylib.zig"),
```

**After:**
```zig
.root_source_file = b.path("raylib-zig/lib/raylib.zig"),
```

**Rationale:** The wrapper's `build.zig` is imported by the parent project, so paths must be relative to the parent directory.

### 3. Raylib 5.0 Build Script Updates

These changes were made to the cached raylib build script to support Zig 0.14 APIs:

#### Type Changes

```zig
// Before:
pub fn addRaylib(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode, options: Options) *std.Build.CompileStep

// After:
pub fn addRaylib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: Options) *std.Build.Step.Compile
```

```zig
// Before:
switch (target.getOsTag()) {

// After:
switch (target.result.os.tag) {
```

#### LazyPath Changes

```zig
// Before:
raylib.addIncludePath(.{ .path = srcdir ++ "/external/glfw/include" });

// After:
raylib.addIncludePath(.{ .cwd_relative = srcdir ++ "/external/glfw/include" });
```

```zig
// Before:
lib.installHeader("src/raylib.h", "raylib.h");

// After:
lib.installHeader(b.path("src/raylib.h"), "raylib.h");
```

#### C Macro API Changes

```zig
// Before:
raylib.defineCMacro("PLATFORM_DESKTOP", null);

// After:
raylib.root_module.addCMacro("PLATFORM_DESKTOP", "");
```

**Note:** The new API requires a string value instead of null for empty macros.

## Source Code Changes

### 1. Standard Library Reorganization (`src/main.zig`)

#### Random Number Generation

**Before:**
```zig
const rand = std.rand;
// ...
rand: rand.Random,
// ...
var prng = rand.Xoshiro256.init(seed);
```

**After:**
```zig
const Random = std.Random;
// ...
rand: Random,
// ...
var prng = std.Random.Xoshiro256.init(seed);
```

**Rationale:** The `std.rand` namespace was reorganized in Zig 0.14.

### 2. Raylib Module Access

**Before:**
```zig
const rl = @import("raylib");
const rlm = @import("raylib-math");
```

**After:**
```zig
const rl = @import("raylib");
const rlm = rl.math;
```

**Rationale:** raylib-math is now a submodule of raylib to avoid module conflicts in Zig 0.14.

### 3. Variable Mutability

Fixed several instances where `var` should have been `const`:

```zig
// Before:
var objcolor = switch (icolor) { ... };
var qrcPct: f32 = ...;
var c1 = rl.Color.dark_blue;
var shipcolor: rl.Color = qrcColor();

// After:
const objcolor = switch (icolor) { ... };
const qrcPct: f32 = ...;
const c1 = rl.Color.dark_blue;
const shipcolor: rl.Color = qrcColor();
```

### 4. Error Handling

**Before:**
```zig
sound = .{
    .bloopLo = rl.loadSound("bloop_lo.wav"),
    // ...
};
```

**After:**
```zig
sound = .{
    .bloopLo = try rl.loadSound("bloop_lo.wav"),
    // ...
};
```

**Rationale:** raylib-zig now returns error unions for resource loading functions.

### 5. Enum Naming Changes

#### Keyboard Keys

**Before:**
```zig
rl.isKeyDown(.key_left)
rl.isKeyDown(.key_right)
rl.isKeyDown(.key_up)
rl.isKeyDown(.key_w)
rl.isKeyPressed(.key_space)
```

**After:**
```zig
rl.isKeyDown(.left)
rl.isKeyDown(.right)
rl.isKeyDown(.up)
rl.isKeyDown(.w)
rl.isKeyPressed(.space)
```

#### Mouse Buttons

**Before:**
```zig
rl.isMouseButtonPressed(.mouse_button_left)
```

**After:**
```zig
rl.isMouseButtonPressed(.left)
```

**Rationale:** Enum names were simplified by removing redundant prefixes.

## Raylib-zig Compatibility Fixes

### IsSoundValid Function

**Before:**
```zig
pub fn loadSound(fileName: [:0]const u8) RaylibError!Sound {
    const sound = cdef.LoadSound(@as([*c]const u8, @ptrCast(fileName)));
    const isValid = cdef.IsSoundValid(sound);
    return if (isValid) sound else RaylibError.LoadSound;
}
```

**After:**
```zig
pub fn loadSound(fileName: [:0]const u8) RaylibError!Sound {
    const sound = cdef.LoadSound(@as([*c]const u8, @ptrCast(fileName)));
    // const isValid = cdef.IsSoundValid(sound);
    // return if (isValid) sound else RaylibError.LoadSound;
    return sound;
}
```

**Rationale:** The `IsSoundValid` function doesn't exist in raylib 5.0. The validation check was commented out for compatibility.

## Known Issues

1. **Linker Warnings**: The build produces harmless warnings about archive members not being ET_REL or LLVM bitcode. These can be ignored.

2. **Version Mismatch**: The raylib-zig wrapper is more recent than raylib 5.0, which can cause compatibility issues. If you encounter undefined symbol errors, you may need to comment out validation checks for newer raylib functions.

## Testing

After migration, verify:

1. The project builds without errors:
   ```bash
   zig build
   ```

2. The application runs correctly:
   ```bash
   zig build run
   ```

3. All game functionality works as expected (rendering, input, audio, etc.)

## References

- [Zig 0.14.0 Release Notes](https://ziglang.org/download/0.14.0/release-notes.html)
- [raylib 5.0](https://github.com/raysan5/raylib/releases/tag/5.0)
- [raylib-zig](https://github.com/Not-Nik/raylib-zig)
