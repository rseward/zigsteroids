init:
	# Pull in the raylib-zig submodule
	git submodule update --init --recursive
	git submodule update --remote

build:
	zig build

# Pin to glibc 2.42 (Bazzite's glibc version) so the binary built on this
# (newer-glibc) host doesn't fail on Bazzite with a GLIBC_x.xx not found
# error. Uses this host's own root filesystem as the sysroot since it's the
# same architecture (x86_64) as Bazzite, so its X11/GLX libraries can be
# used for linking.
build-bazzite:
	zig build -Dtarget=x86_64-linux-gnu.2.42 -Dsysroot=/

run:
	zig build run

deps:
	sudo dnf install glfw-devel -y

install-udev:
	sudo cp udev/99-xbox-controller.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules
	sudo udevadm trigger

# Remove build outputs and the Zig build cache.
clean:
	rm -rf zig-out .zig-cache

.PHONY: init build build-bazzite run deps install-udev clean
