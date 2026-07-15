# 0.3.4

- Alien saucers now fire green bullets at the player's ship
- Added a pause/help overlay — press H or P to pause and view controls
- Added shields — press DOWN to activate a temporary shield that destroys asteroids and blocks alien fire (protection duration doubled)
- Added a game over screen — when all lives are lost, a translucent overlay shows your final score with asteroids still drifting in the background; press 1 to start a new game

# 0.3.1

- Ported to Zig 0.15.2 with official raylib-zig dependency (builds on the `zig-0.15` branch)
- Migrated ArrayList API for Zig 0.15 (`.empty` init, allocator params on append/resize/deinit)
- Replaced `std.BoundedArray` with `std.ArrayListUnmanaged.initBuffer()` per 0.15 stdlib changes
- Updated `build.zig` to use `b.createModule()` for executable root module
- Moved sound effects to `resources/` directory; added game screenshot
- Added migration guides (`docs/zig-0_14-migration.md`, `docs/zig-0_15-migration.md`)
- Overhauled README with ZVM install instructions, distro-specific system deps (Fedora/Ubuntu), project structure, and controls table
- Added release checklist (`docs/release/CHECKLIST.md`)
- Makefile: added `build` target, switched `run` from hardcoded zig path to `zig build run`
- Added `make deps` target for Fedora system dependency installation

# 0.3.0

Added zig-0.14 and zig-0.15 compatibility with updated raylib-zig dependency in branches with the same name.
- moved .wav files to resources/ directory

# 0.2.0

Now with quantum rematerialization support. Your ship phases in with quantum technology after being destroyed.