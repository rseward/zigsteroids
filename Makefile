init:
	# Pull in the raylib-zig submodule
	git submodule update --init --recursive

run:
	$(HOME)/bin/zig build run

deps:
	sudo dnf install glfw-devel -y
