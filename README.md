
# Zigsteroids

A Zig implementation of the classic Asteroids game.

The original project is at:
- https://github.com/jdah/zigsteroids.git

It was mainly written on jdah's live stream on stream 16/March 2024 
- https://www.youtube.com/watch?v=ajbYYgbDXGk

This project is a fork and modification of the original, with additional features and improvements.

## Building

This project currently supports zig-0.11.

### Pull dependent raylib-zig submodule

```bash
git submodule update --init --recursive
```

### Build

```bash
zig build
```
or

```bash
make init
make run
```


## Running

```bash
zig build run
```

## Controls

- Arrow keys to move and rotate
- Space to fire
- R to restart

## Features

- Ship movement and rotation
- Shooting mechanics
- Asteroid destruction and splitting
- Score tracking
- Game over and restart functionality

## License

MIT