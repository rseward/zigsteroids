# ---------------------------------------------------------------------------
# arm/Makefile — Raspberry Pi 5 (aarch64) cross-compilation for zigsteroids
# ---------------------------------------------------------------------------
#
# Run from the project root with:
#
#     make -f arm/Makefile <target>
#
# Zig can cross-compile the Zig sources and raylib's C sources on its own, but
# raylib also links against the target's system libraries (X11, GLX, GL, ...).
# Those are searched via the `paths_first` strategy, which only looks in
# directories registered on the module. For a non-native target that means a
# *sysroot* of the target machine must be supplied (see build.zig's `-Dsysroot`
# option) so those libraries and headers can be found.
#
# The sysroot is the root filesystem of the Raspberry Pi. The easiest way to
# obtain it is to rsync it from a running Pi (replace the IP/address):
#
#     make -f arm/Makefile pi-sysroot PI_HOST=pi@192.168.x.x
#
# This populates `pi-sysroot/` (at the project root) with the Pi's /usr and /lib
# trees. Afterwards:
#
#     make -f arm/Makefile build-pi5
#
# Recommended for a Pi 5 (Raspberry Pi OS Bookworm, Wayland desktop, V3D GPU):
#
#     make -f arm/Makefile pi-sysroot PI_HOST=pi@192.168.x.x
#     make -f arm/Makefile build-pi5 DISPLAY_BACKEND=wayland OPENGL_VERSION=gles_3
#
# The resulting binary is at `zig-out/bin/lsr` (an ELF aarch64 executable). Copy
# it to the Pi and run it there:
#
#     scp zig-out/bin/lsr pi@192.168.x.x:~/
#     ssh pi@192.168.x.x './lsr'
#
# Variables (override on the command line, e.g. `make -f arm/Makefile build-pi5 SYSROOT=/mnt/pi`):
#
#   SYSROOT         Pi root filesystem          (default: <project>/pi-sysroot)
#   PI_HOST         user@host for pi-sysroot     (default: rseward@192.168.1.141)
#   PI5_TARGET      full Zig target triple       (default: aarch64-linux-gnu.2.36)
#                   (.2.36 pins glibc to match Raspberry Pi OS Bookworm)
#   OPTIMIZE        zig optimize mode           (default: fast)
#   DISPLAY_BACKEND raylib display backend       (default: x11; use wayland on Pi 5)
#   OPENGL_VERSION  raylib OpenGL API version    (default: auto; use gles_3 on Pi 5)

# Anchor paths to this Makefile's location so it works regardless of the cwd
# that `make -f arm/Makefile` is invoked from.
THIS_DIR     := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PROJECT_ROOT := $(patsubst %/,%,$(dir $(THIS_DIR)))

SYSROOT           ?= $(PROJECT_ROOT)/pi-sysroot
PI_HOST           ?= rseward@192.168.1.141
PI5_TARGET        ?= aarch64-linux-gnu.2.36
OPTIMIZE          ?= fast
DISPLAY_BACKEND   ?= x11
OPENGL_VERSION    ?= auto
# Where the Pi's multiarch shared libraries land after the rsync (-L dereferences
# the merged-usr /lib -> /usr/lib symlink into ./lib/).
PI_SYSROOT_LIBDIR ?= $(SYSROOT)/lib/aarch64-linux-gnu
# Libraries raylib links against (the `-l` set from its build.zig). Covers both
# the X11/GLX backend and the Wayland/GLES backend so the dev-symlink step
# prepares either configuration.
PI_LINK_LIBS      ?= GLX X11 Xcursor Xext Xfixes Xi Xinerama Xrandr Xrender GL \
                     EGL GLESv2 wayland-client xkbcommon

.DEFAULT_GOAL := help

help:
	@echo "Raspberry Pi 5 (aarch64) cross-compile targets (run from project root):"
	@echo "  make -f arm/Makefile pi-sysroot [PI_HOST=pi@x.x.x.x]"
	@echo "      Pull headers + libs from the Pi into $(SYSROOT) and prepare dev symlinks."
	@echo "  make -f arm/Makefile pi-sysroot-dev-symlinks"
	@echo "      (Re)create missing lib<name>.so dev symlinks in the sysroot (idempotent)."
	@echo "  make -f arm/Makefile build-pi5 [DISPLAY_BACKEND=wayland OPENGL_VERSION=gles_3]"
	@echo "      Cross-compile zig-out/bin/lsr for the Pi 5."
	@echo "  make -f arm/Makefile run-pi5"
	@echo "      Build + run the aarch64 binary on this host via QEMU (if installed)."
	@echo ""
	@echo "Recommended for a Pi 5 (Wayland desktop, V3D GPU):"
	@echo "  make -f arm/Makefile build-pi5 DISPLAY_BACKEND=wayland OPENGL_VERSION=gles_3"

# Fetch only the headers and shared libraries from the Pi into the sysroot so
# the cross-compiler/linker can find the aarch64 X11/GL/... system libraries.
# This deliberately excludes /usr/bin, /usr/share, /usr/libexec and the rest of
# /usr, keeping the sysroot to just what the build actually needs.
#
# A Pi without the -dev packages installed only ships the runtime
# `lib<name>.so.<N>` files, not the `lib<name>.so` dev symlinks the linker needs
# for `-l<name>`. The pi-sysroot-dev-symlinks dependency recreates those symlinks
# so a freshly pulled sysroot is ready to cross-compile as-is.
pi-sysroot:
	@mkdir -p $(SYSROOT)
	rsync -avL --copy-links \
		--include='/usr/include/***' \
		--include='/usr/lib/***' \
		--include='/lib/***' \
		--exclude='*' \
		$(PI_HOST):/ $(SYSROOT)/
	@$(MAKE) --no-print-directory -f $(THIS_DIR)/Makefile pi-sysroot-dev-symlinks
	@echo "Pi sysroot populated and prepared at $(SYSROOT)"

# Create `lib<name>.so -> lib<name>.so.<N>` dev symlinks in the sysroot for any
# of raylib's link libraries that are missing them (idempotent).
pi-sysroot-dev-symlinks:
	@for lib in $(PI_LINK_LIBS); do \
	  dir="$(PI_SYSROOT_LIBDIR)"; \
	  if [ ! -e "$$dir/lib$$lib.so" ]; then \
	    tgt=$$(ls -v $$dir/lib$$lib.so.* 2>/dev/null | head -1); \
	    if [ -n "$$tgt" ]; then \
	      ln -sf "$$(basename $$tgt)" "$$dir/lib$$lib.so"; \
	      echo "  dev-symlink: lib$$lib.so -> $$(basename $$tgt)"; \
	    fi; \
	  fi; \
	done

# Cross-compile the aarch64 binary that runs on a Raspberry Pi 5.
build-pi5:
	cd $(PROJECT_ROOT) && zig build \
		-Dtarget=$(PI5_TARGET) \
		-Dsysroot=$(SYSROOT) \
		-Dlinux_display_backend=$(DISPLAY_BACKEND) \
		-Dopengl_version=$(OPENGL_VERSION) \
		--release=$(OPTIMIZE)
	@echo "Built Pi 5 (aarch64) binary: $(PROJECT_ROOT)/zig-out/bin/lsr (backend: $(DISPLAY_BACKEND), gl: $(OPENGL_VERSION))"

# (Optional) Build + run the cross-compiled aarch64 binary on this host via QEMU
# user emulation, if qemu-aarch64 and the matching libs are installed.
run-pi5:
	cd $(PROJECT_ROOT) && zig build run \
		-Dtarget=$(PI5_TARGET) \
		-Dsysroot=$(SYSROOT) \
		-Dlinux_display_backend=$(DISPLAY_BACKEND) \
		-Dopengl_version=$(OPENGL_VERSION) \
		--release=$(OPTIMIZE) \
		-fqemu

.PHONY: help pi-sysroot pi-sysroot-dev-symlinks build-pi5 run-pi5