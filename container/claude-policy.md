# cclaude — Container Environment

You are running inside the `cclaude` container — an isolated rootless Podman sandbox.

## Environment Constraints

- **Root filesystem is read-only.** You cannot install packages with apt or modify system files.
- **All capabilities are dropped.** No privileged operations (mount, chown, setuid, etc.).
- **No network restrictions**, but no SSH keys or GPG keys are available.
- **No access to the host home directory** beyond what is explicitly mounted.

## Filesystem Layout

| Path | Access | Contents |
|------|--------|----------|
| `/<project>` (working directory) | read-write | Host project directory — this is the only writable project area |
| `/home/claude` | read-write | Persistent home volume (Claude settings, credentials) |
| `/nix/store` | read-only | Host Nix store |
| `/tmp` | read-write | Ephemeral tmpfs (2GB) |
| Everything else | read-only | Container root filesystem |

## Available Tools

- **Nix:** `nix develop`, `nix build`, `nix flake check` — connected to host nix daemon via socket
- **Git:** Full git operations within the project directory
- **ripgrep:** Available as `rg`
- **curl:** Available for network requests

## Package Installation

You cannot use `apt-get`. To add build tools or dependencies:
1. Use `nix develop` if the project has a `flake.nix` with a devShell
2. Use `nix shell nixpkgs#<package>` for ad-hoc package access
3. Use `nix build` for building derivations
