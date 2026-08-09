=== ZIGSTEROIDS (aka. LARGE SPACE ROCKS) ===

A poorly done Zig implementation of the classic 1979 arcade game Asteroids.

Done live on stream 16/March 2024 - https://www.youtube.com/watch?v=ajbYYgbDXGk

== Controls ==

Keyboard:
  LEFT/RIGHT  Rotate ship
  UP / W      Thrust
  DOWN        Shields
  SPACE/CLICK Shoot
  H / P       Pause
  1           New Game (on game over screen)

Xbox Controller:
  Left Stick / D-PAD  Rotate (analog stick = variable speed)
  RT (Right Trigger)  Thrust
  B / LT              Shields
  A                   Shoot
  Start               Pause / New Game

== Building ==

  zig build run

Or:

  make run

== Linux: Xbox Controller Setup ==

raylib reads gamepad input directly from /dev/input/event* (evdev), unlike
SDL2-based programs which use systemd-logind ACLs. Without udev rules, non-root
users cannot access the device nodes and gamepad input will silently fail.

Install the included udev rules:

  make install-udev

Or manually:

  sudo cp udev/99-xbox-controller.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules
  sudo udevadm trigger

Then replug your controller. Verify with:

  ls -la /dev/input/event*

If gamepad input still doesn't work, the input system will automatically fall
back to reading /dev/input/js* directly (raw joydev), bypassing GLFW's gamepad
mapping requirement.