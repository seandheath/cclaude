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
          cclaude.packages.x86_64-linux.cclaude-setup
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
          cclaude.packages.x86_64-linux.cclaude-setup
        ];
      }];
    };
  };
}
```

## Setup

On first run, `cclaude` automatically builds the container image and runs `cclaude-setup` if no token is found. Just run:

```bash
cclaude
```

To set up manually:

```bash
# Build the container image
cclaude-build

# Run the OAuth token setup flow
cclaude-setup
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

# Re-run OAuth token setup
cclaude-setup
```

## Security Model

| Control | Setting |
|---------|---------|
| Capabilities | `--cap-drop=ALL` |
| Privileges | `--security-opt no-new-privileges:true` |
| SELinux | `--security-opt label=disable` |
| Root filesystem | Read-only |
| User namespace | `--userns=keep-id` |
| Container user | Non-root (`claude`, UID 1000) |
| Project mount | Current directory only, read-write |
| Nix store | Read-only bind mount |
| Nix daemon | Socket mount (store writes go through host daemon) |
| Home directory | Persistent named volume (`cclaude-home`) |
| Temp | 2 GB tmpfs, `nosuid,nodev` |

## How It Works

The container is based on `debian:bookworm-slim` with Claude Code installed via the [official installer](https://claude.ai/install.sh). It runs as a non-root user (`claude`, UID 1000). At runtime:

1. Your current directory is mounted at `/<project-name>` (matching the host directory name)
2. The host `/nix/store` is mounted read-only
3. The host nix daemon socket is mounted so Claude can run nix commands
4. `HOME` (`/home/claude`) lives on a persistent named volume (`cclaude-home`)
5. Your OAuth token is passed via environment variable (never written to disk inside the container)
6. On first run, the image is built automatically and `cclaude-setup` runs if no token exists

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
