# Zig 0.15.2 Migration Guide

This document describes the changes made to migrate the zigsteroids project from Zig 0.14 to Zig 0.15.2.

## Overview

Zig 0.15 introduced several breaking changes that required updates to the build system, dependency management, and standard library usage. This migration ensures compatibility with Zig 0.15.2 and uses the best-supported raylib wrapper for this version.

## Changes Made

### 1. Updated to Official raylib-zig Repository

**Why:** The official `raylib-zig/raylib-zig` repository provides better support for Zig 0.15.x compared to the fork we were using.

**Changes in `build.zig.zon`:**
```zig
// Before (Zig 0.14)
.raylib_zig = .{
    .url = "git+https://github.com/Not-Nik/raylib-zig#7bdb0cd...",
    .hash = "raylib_zig-5.6.0-dev-KE8REM40...",
}

// After (Zig 0.15.2)
.raylib_zig = .{
    .url = "git+https://github.com/raylib-zig/raylib-zig#a4d18b2...",
    .hash = "raylib_zig-5.6.0-dev-KE8REL5M...",
}
```

**How to update:** Use `zig fetch --save=raylib_zig git+https://github.com/raylib-zig/raylib-zig` to get the latest version and hash.

### 2. Updated build.zig for Zig 0.15.2 API Changes

**Why:** Zig 0.15 changed the executable creation API to use `b.createModule()`.

**Changes in `build.zig`:**
```zig
// Before (Zig 0.14)
const exe = b.addExecutable(.{
    .name = "lsr",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

// After (Zig 0.15.2)
const exe = b.addExecutable(.{
    .name = "lsr",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

### 3. Migrated ArrayList to Zig 0.15.2 API

**Why:** Zig 0.15 changed ArrayList to not store the allocator internally by default, requiring it to be passed to each method.

**Initialization:**
```zig
// Before (Zig 0.14)
.asteroids = std.ArrayList(Asteroid).init(allocator),

// After (Zig 0.15.2)
.asteroids = .empty,
```

**Appending:**
```zig
// Before (Zig 0.14)
try state.asteroids.append(.{ ... });

// After (Zig 0.15.2)
try state.asteroids.append(state.allocator, .{ ... });
```

**Resizing:**
```zig
// Before (Zig 0.14)
try state.asteroids.resize(0);

// After (Zig 0.15.2)
try state.asteroids.resize(state.allocator, 0);
```

**Deinitialization:**
```zig
// Before (Zig 0.14)
defer state.asteroids.deinit();

// After (Zig 0.15.2)
defer state.asteroids.deinit(allocator);
```

**State struct changes:**
Added an `allocator` field to the State struct for convenience:
```zig
const State = struct {
    // ... other fields ...
    rand: Random,
    allocator: std.mem.Allocator,  // NEW
    lives: usize = 0,
    // ... other fields ...
};
```

### 4. Replaced BoundedArray

**Why:** `std.BoundedArray` was removed from the standard library in Zig 0.15. The recommended replacement is `std.ArrayListUnmanaged.initBuffer()` for stack-allocated bounded arrays.

**Before (Zig 0.14):**
```zig
var points = try std.BoundedArray(Vector2, 16).init(0);
for (lines) |p| {
    try points.append(Vector2.init(p[0], p[1]));
}
drawLines(pos, scale, rot, points.slice(), connect, color);
```

**After (Zig 0.15.2):**
```zig
var buffer: [16]Vector2 = undefined;
var points = std.ArrayListUnmanaged(Vector2).initBuffer(&buffer);
for (lines) |p| {
    points.appendAssumeCapacity(Vector2.init(p[0], p[1]));
}
drawLines(pos, scale, rot, points.items, connect, color);
```

**Key differences:**
- Use a stack-allocated buffer instead of the bounded array
- `initBuffer()` creates an unmanaged list backed by the buffer
- `appendAssumeCapacity()` doesn't need `try` (returns void, not an error)
- Access items via `.items` instead of `.slice()`

## Migration Checklist

If you're migrating another Zig 0.14 project to 0.15, follow these steps:

- [ ] Update `build.zig` to use `b.createModule()` for executable creation
- [ ] Change all `ArrayList.init(allocator)` to `.empty` initialization
- [ ] Add allocator parameter to all `.append()`, `.resize()`, and `.deinit()` calls
- [ ] Replace `std.BoundedArray` with `std.ArrayListUnmanaged.initBuffer()`
- [ ] Change `.appendAssumeCapacity()` calls to not use `try`
- [ ] Replace `.slice()` with `.items` for bounded arrays
- [ ] Update dependency URLs to use Zig 0.15-compatible versions
- [ ] Test the build with `zig build`

## Resources

- [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
- [Official raylib-zig Repository](https://github.com/raylib-zig/raylib-zig)
- [ArrayList Migration Discussion](https://github.com/ziglang/zig/pull/24699)
- [BoundedArray Removal PR](https://github.com/ziglang/zig/pull/24699)

## Build Verification

After migration, verify the build:

```bash
zig version  # Should show 0.15.1 or higher
zig build
ls -lh zig-out/bin/  # Verify executable was created
```

## Notes

- The ArrayList changes are intentional to reduce struct size and complexity
- BoundedArray removal encourages more explicit memory management
- Consider using `std.ArrayListUnmanaged` for better control when you need bounded capacity
- The official raylib-zig is tested with Zig 0.15.1+ and raylib 5.6-dev

## Troubleshooting

### "no member named 'init'" on ArrayList
Change `.init(allocator)` to `.empty` initialization.

### "expected 2 arguments" on append
Add the allocator as the first parameter: `.append(allocator, item)`.

### "no member named 'BoundedArray'"
Replace with `ArrayListUnmanaged.initBuffer()` pattern using a stack buffer.

### "expected error union type" on appendAssumeCapacity
Remove the `try` keyword - this method doesn't return an error.
