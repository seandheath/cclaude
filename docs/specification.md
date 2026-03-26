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
- SSH agent forwarding via `SSH_AUTH_SOCK` (no raw keys mounted)
- No access to GPG keys or host home directory (beyond explicitly mounted files)

## CLAUDE.md Instructions

Claude Code loads instructions from three scopes (all concatenated):

1. **Managed policy** (`/etc/claude-code/CLAUDE.md`) — highest precedence. Baked into the container image from `container/claude-policy.md`. Contains container-specific environment constraints.
2. **Project** (`./CLAUDE.md`) — available via the mounted project directory.
3. **User** (`~/.claude/CLAUDE.md`) — bind-mounted read-only from host `~/.claude/CLAUDE.md` (conditional: only if file exists on host).

## Volume Layout

- `cclaude-home` — persistent named volume at `/home/claude` for Claude credentials, settings, and home directory state
- Host `~/.claude/CLAUDE.md` — bind-mounted read-only at `/home/claude/.claude/CLAUDE.md` (if present)
- Host `SSH_AUTH_SOCK` — bind-mounted read-only at `/run/ssh-agent.sock` (if set)

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
