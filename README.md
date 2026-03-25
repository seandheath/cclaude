# cclaude

Run [Claude Code](https://claude.ai/code) in an isolated rootless Podman container with full Nix flake support.

Claude gets read-only access to your host Nix store and communicates with the host nix daemon — it can run `nix develop`, `nix build`, `nix flake check` without direct store write access. Only your current project directory is mounted read-write. No access to SSH keys, GPG, home directory, or system configs.

## Requirements

- NixOS with rootless Podman
- Nix daemon running (default on NixOS)
- A Claude Code OAuth token

## Installation

Add to your NixOS or home-manager configuration:

```nix
# flake.nix
{
  inputs.cclaude.url = "github:YOUR_USERNAME/cclaude";

  outputs = { self, nixpkgs, cclaude, ... }: {
    # NixOS
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [{
        environment.systemPackages = [
          cclaude.packages.x86_64-linux.default
          cclaude.packages.x86_64-linux.cclaude-build
          cclaude.packages.x86_64-linux.cclaude-update
          cclaude.packages.x86_64-linux.cclaude-shell
        ];
      }];
    };

    # Or home-manager
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      modules = [{
        home.packages = [
          cclaude.packages.x86_64-linux.default
          cclaude.packages.x86_64-linux.cclaude-build
          cclaude.packages.x86_64-linux.cclaude-update
          cclaude.packages.x86_64-linux.cclaude-shell
        ];
      }];
    };
  };
}
```

## Setup

```bash
# 1. Build the container image
cclaude-build

# 2. Get your OAuth token
#    If you have claude on the host:
claude setup-token
#    Otherwise:
nix shell nixpkgs#nodejs --command npx @anthropic-ai/claude-code setup-token

# 3. Save the token
mkdir -p ~/.config/cclaude
install -m 600 /dev/stdin ~/.config/cclaude/token
# paste token, Ctrl-D
```

## Usage

```bash
# Run Claude Code in current project
cd ~/projects/my-project
cclaude

# Pass arguments to claude
cclaude --help

# Drop into a shell inside the container
cclaude-shell

# Update Claude Code (pulls latest base image and rebuilds)
cclaude-update
```

## Security Model

| Control | Setting |
|---------|---------|
| Capabilities | `--cap-drop=ALL` |
| Privileges | `--security-opt no-new-privileges:true` |
| Root filesystem | Read-only |
| User namespace | `--userns=keep-id` |
| Memory limit | 4 GB |
| PID limit | 512 |
| Project mount | Current directory only, read-write |
| Nix store | Read-only bind mount |
| Nix daemon | Socket mount (store writes go through host daemon) |
| Home directory | tmpfs (ephemeral), `.claude` on persistent volume |

## How It Works

The container is based on `node:22-bookworm-slim` with Claude Code installed via the official installer. At runtime:

1. Your current directory is mounted at `/workspace`
2. The host `/nix/store` is mounted read-only
3. The host nix daemon socket is mounted so Claude can run nix commands
4. `HOME` is tmpfs — all writes are ephemeral except `~/.claude` which persists on a named volume
5. Your OAuth token is passed via environment variable (never written to disk inside the container)

## Development

```bash
nix develop   # Enter dev shell
make build    # Build container image
make test     # Run flake checks
make lint     # shellcheck + nil
make fmt      # shfmt + nixfmt
make clean    # Remove image and volumes
```

## License

MIT
