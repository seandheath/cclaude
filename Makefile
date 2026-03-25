.PHONY: build test run clean lint fmt check

build:
	nix build .#cclaude-build
	./result/bin/cclaude-build

test:
	nix flake check

run:
	nix run .#cclaude

clean:
	rm -rf result
	podman rmi localhost/cclaude:latest 2>/dev/null || true
	podman volume rm cclaude-config 2>/dev/null || true

lint:
	shellcheck container/entrypoint.sh
	nil diagnostics flake.nix

fmt:
	shfmt -w container/entrypoint.sh
	nixfmt flake.nix

check: fmt lint test
