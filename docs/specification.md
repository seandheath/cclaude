# cclaude — Specification

## Overview

cclaude runs Claude Code inside an isolated rootless Podman container. It mounts the host Nix store read-only and connects to the host nix daemon, allowing Claude to use `nix develop`, `nix build`, and `nix flake check` without direct store write access.

Distributed as a Nix flake. Users add it to `environment.systemPackages` or `home.packages`.

## Target Platform

NixOS with rootless Podman enabled and the nix daemon running.

## Container Image

- Base: `node:22-bookworm-slim`
- Claude Code installed via `curl -fsSL https://claude.ai/install.sh | bash`
- Additional packages: git, git-lfs, ca-certificates, ripgrep, curl
- Nix client configured for daemon mode with flakes enabled

## Authentication

OAuth token stored at `~/.config/cclaude/token` (mode 600). Passed into the container as `CLAUDE_CODE_OAUTH_TOKEN`.

## Security Model

- Read-only root filesystem
- All capabilities dropped (`--cap-drop=ALL`)
- No new privileges (`--security-opt no-new-privileges:true`)
- SELinux labels disabled (`--security-opt label=disable`)
- User namespace isolation (`--userns=keep-id`)
- Memory limit: 4GB
- PID limit: 512
- `/tmp` as tmpfs (2GB, nosuid, nodev)
- Only the current project directory is mounted read-write
- Host nix store mounted read-only
- No access to SSH keys, GPG, home directory, or `/etc`

## Volume Layout

- `cclaude-config` — persistent named volume at `/tmp/claude-home/.claude` for Claude credentials and settings
- `HOME=/tmp/claude-home` — tmpfs, ephemeral per run (except the `.claude` volume mount)

## CLI Commands

| Command | Description |
|---------|-------------|
| `cclaude [args...]` | Run Claude Code in current directory |
| `cclaude-build` | Build the container image |
| `cclaude-update` | Pull latest base image and rebuild |
| `cclaude-shell` | Drop into bash inside the container |

## Nix Flake Outputs

- `packages.default` = `cclaude`
- `packages.cclaude-build`
- `packages.cclaude-update`
- `packages.cclaude-shell`
- `devShells.default` — development tools (shellcheck, shfmt, nil, nixfmt)
- `checks.shellcheck` — lint entrypoint.sh
