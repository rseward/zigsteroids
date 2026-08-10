init:
	# Pull in the raylib-zig submodule
	git submodule update --init --recursive
	git submodule update --remote

build:
	zig build

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

.PHONY: init build run deps install-udev clean
