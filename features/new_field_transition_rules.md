# New Field Transition Rules

## Problem

When only a medium or large rock is left in the field, shooting and hitting
that large or medium rock caused the transition to the next field. This is
inaccurate. In the original game, large and medium rocks had to be broken
down into their smallest atoms (small asteroids). Only after all the small
asteroids have been destroyed would the field transition.

The presence of an alien on the field also should not prevent the transition
to a new field. Instead the alien(s) should also be transitioned to the new
field along with the player when the last small rock has been destroyed.

When spawning rocks around the player, divide the asteroid field into a
twelve by twelve grid. The width and height of one of these grid squares is
the minimum distance an asteroid is allowed to spawn near the player's ship.
This change prevents "unfair" deaths that frequently occur at present.

## Implementation

### Transition check (src/main.zig — update())

The field transition condition checks that **both** the active asteroid list
(`state.asteroids`) and the pending queue (`state.asteroids_queue`) are
empty. The queue holds child asteroids created by `hitAsteroid()` during the
same frame a big or medium rock is destroyed. By also checking the queue we
prevent a premature transition when the last big or medium rock is split into
smaller fragments.

```zig
if (!state.gameOver and
    state.asteroids.items.len == 0 and
    state.asteroids_queue.items.len == 0)
{
    try resetAsteroids();
}
```

### Aliens carried over (src/main.zig — resetAsteroids())

Aliens are **not** cleared during a field transition. They are carried over
to the new field along with the player, matching the original game's
behaviour. However, any in-flight **alien projectiles** are cleared so the
player is not unfairly hit during the transition.

### Grid-based spawn placement (src/main.zig — resetAsteroids())

`FIELD_GRID_DIV` (12) divides the field into a 12×12 grid. The width and
height of one grid square is the minimum distance an asteroid may spawn from
the player's ship, preventing unfair deaths from rocks appearing on top of
the player.

## Status: Implemented