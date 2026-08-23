# Vector Graphics Scaling

## Problem

`new_field_transition_rules.md`'s spawn-grid work and the later "scale to
detected resolution" change made the *game field* (`SIZE`) track the actual
monitor resolution instead of a hardcoded 1280x960. But the *vector graphics*
— ship, asteroids, aliens, bullets, digits, the HUD panels — are all sized off
a single constant, `SCALE = 38.0`, which never changed. It was tuned by eye
against the original 1280x960 design resolution.

Once `SIZE` floats free of that design resolution, `SCALE` and the design
resolution silently drift apart. On the Bazzite handheld's 1360x768 display
this is visible: the field is short (768 vs. the 960 design height — 80% of
the original), but the ship/asteroids are still drawn at their full
1280x960-design size, so they read as noticeably too large for the field.
The reported "1.25% too big" matches this almost exactly: 1 / 0.8 = 1.25 —
i.e. the sprites are the size they'd be if nothing shrank, on a field that
shrank to 80% height.

## Goal

Derive a single runtime scale factor from `(design resolution, current
resolution)` and apply it to `SCALE` (and, if it stays visibly inconsistent,
`THICKNESS`) once at startup, so ship/asteroid/alien/bullet/digit sizes stay
proportional to the field they're drawn in on any monitor.

## Design

### Baseline

Introduce a `DESIGN_SIZE` constant holding the original design resolution,
separate from the now-dynamic `SIZE`:

```zig
const DESIGN_SIZE = Vector2.init(640 * 2, 480 * 2); // 1280x960, 4:3
```

(`SIZE`'s current default already equals this value — `DESIGN_SIZE` just
keeps a name for "what `SCALE = 38.0` was tuned against" independent of
whatever `SIZE` gets overwritten with at runtime.)

### Choosing the scale-factor formula

`drawLines()` (src/main.zig:188-218) — used for the ship, asteroids, aliens,
digits, everything — applies a single scalar `scale` uniformly to both axes
*after* rotation:

```zig
rlm.vector2Scale(rlm.vector2Rotate(p, self.rot), self.scale)
```

Because rotation happens first, this only stays a rotation (i.e. shapes
don't shear) if the scale factor is uniform. So we cannot scale X and Y
independently without reworking every vector shape to bake in an aspect
correction — out of scope here. We need one scalar.

Three candidate formulas, evaluated against the Bazzite case
(1360x768 vs. 1280x960 design):

| Formula | Value | Effect |
|---|---|---|
| `min(ratio_x, ratio_y)` ("contain") | `min(1.0625, 0.8) = 0.8` | Shrinks to fit the more constrained axis; never lets a sprite exceed the field on either axis. |
| `sqrt(ratio_x * ratio_y)` (geometric mean / area-based) | `sqrt(1.0625 * 0.8) ≈ 0.921` | Splits the difference; sprites can still slightly exceed the short axis. |
| `(ratio_x + ratio_y) / 2` (arithmetic mean) | `0.931` | Similar to geometric mean, slightly less shrink. |

`min()` is the one that actually produces the ~0.8 factor matching the
reported "1.25x too big" (`1 / 0.8 = 1.25`), and it's also the only formula
with a hard guarantee: sprites never overflow the shorter axis regardless of
aspect ratio. Recommended:

```zig
const ratio_x = SIZE.x / DESIGN_SIZE.x;
const ratio_y = SIZE.y / DESIGN_SIZE.y;
const RENDER_SCALE = @min(ratio_x, ratio_y);
```

Optionally clamp `RENDER_SCALE` to a sane range (e.g. `0.5..2.0`) so a very
small or very large/ultrawide monitor can't degenerate into invisible or
absurdly oversized sprites. Needs a number picked by playtesting, not
guessed here.

### Applying it to `SCALE`

`SCALE` is currently a file-scope `const` and is read from ~25 call sites,
including one other file-scope `const` derived from it
(`SHIELD_RADIUS = SCALE * 1.5`, src/main.zig:19). Two changes:

1. Rename the tuned base value to `BASE_SCALE = 38.0` (const), and make
   `SCALE` a runtime `var` set once in `main()`:

   ```zig
   const BASE_SCALE = 38.0;
   var SCALE: f32 = BASE_SCALE;
   ```

   Every existing `SCALE` usage (asteroid/alien sizes, bullet spawn offset,
   digit drawing, HUD margins, etc.) keeps working unmodified — they just
   read the now-runtime value.

2. `SHIELD_RADIUS = SCALE * 1.5` can't stay a file-scope `const` once `SCALE`
   is a `var` (not comptime-known). Convert its 5 call sites
   (src/main.zig:513, 544, 637, 1171, 1173 as of this writing) to a small
   helper instead of caching a stale constant:

   ```zig
   fn shieldRadius() f32 {
       return SCALE * 1.5;
   }
   ```

### Where to compute it

In `main()`, immediately after the existing monitor-detection block that
finalizes `SIZE` (src/main.zig, in `main()` right after
`rl.setWindowSize(...)`), before `resetGame()`/state init, since ship
spawn position and first asteroid field both read `SCALE`-derived sizes:

```zig
const ratio_x = SIZE.x / DESIGN_SIZE.x;
const ratio_y = SIZE.y / DESIGN_SIZE.y;
SCALE = BASE_SCALE * @min(ratio_x, ratio_y);
```

### `THICKNESS`

`THICKNESS = 2.5` (line width for `drawLineEx`) has a single call site
(src/main.zig:214, inside `drawLines`). Not mentioned in the bug report, so
out of scope for the first pass — flagged here so it isn't forgotten if
scaled-down sprites end up with disproportionately thick outlines. If
needed, scale it the same way and clamp to a minimum of ~1.0px so lines
don't disappear at small `RENDER_SCALE`.

### Out of scope for this change

- HUD text (`font_size`/`small_font_size` in the help/game-over panels,
  src/main.zig:864/958-959) is sized independently of `SCALE` via raylib's
  font metrics. The bug report is specifically about ship/asteroid vector
  graphics; text scaling is a separate, likely lower-priority follow-up.
- Re-deriving `RENDER_SCALE`/`SCALE` on fullscreen toggle (`F` key). The
  toggle currently preserves the window's pixel dimensions (see
  `features/pause_help.md` area of `update()`), so `SIZE` doesn't change
  when toggling and no recompute is needed. If a future change makes
  fullscreen switch to a different resolution, this assumption breaks and
  `SCALE` would need recomputing alongside `SIZE`.

## Implementation Plan

1. Add `DESIGN_SIZE` constant (mirrors current `SIZE` default).
2. Rename `SCALE` constant to `BASE_SCALE`; declare `var SCALE: f32 = BASE_SCALE;`.
3. Replace the 5 `SHIELD_RADIUS` call sites with `shieldRadius()`; remove the
   `SHIELD_RADIUS` const.
4. In `main()`, after `SIZE` is finalized from monitor detection, compute
   `SCALE = BASE_SCALE * @min(SIZE.x / DESIGN_SIZE.x, SIZE.y / DESIGN_SIZE.y);`
5. (Optional, pending playtest feedback) Clamp `RENDER_SCALE` to a min/max
   bound before applying it.
6. Build and manually verify on:
   - This dev machine's native resolution (should be ~1.0x, i.e. unchanged
     from current behavior, since design resolution is likely close to or
     smaller than native).
   - The Bazzite 1360x768 target (`make build-bazzite`) — ship/asteroids
     should now read as correctly sized relative to the field, not 1.25x
     oversized.

## Testing

No headless display is available in the dev sandbox this plan was drafted
in, so this needs manual visual verification on real hardware (or at least
a machine with a display) before/after, at minimum on the Bazzite
1360x768 screen that reported the bug, plus one more resolution (ideally
something wider/taller than design, e.g. a 1920x1080 desktop) to confirm
the `min()` formula doesn't overshrink on a monitor that's *taller*
relative to its width than the design resolution.

## Status: Implemented
