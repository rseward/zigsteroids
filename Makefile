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
