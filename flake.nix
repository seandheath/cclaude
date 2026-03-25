{
  description = "cclaude: Run Claude Code in an isolated rootless Podman container with Nix flake support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        podman = "${pkgs.podman}/bin/podman";
        image = "localhost/cclaude:latest";
        tokenFile = "\${HOME}/.config/cclaude/token";
        configVolume = "cclaude-config";

        # Path to container build context in the nix store
        containerContext = "${self}/container";

        cclaude-build = pkgs.writeShellScriptBin "cclaude-build" ''
          set -euo pipefail
          ${podman} build \
            --tag ${image} \
            --pull=newer \
            ${containerContext}
        '';

        cclaude-update = pkgs.writeShellScriptBin "cclaude-update" ''
          set -euo pipefail
          ${podman} pull docker.io/library/debian:bookworm-slim
          exec ${cclaude-build}/bin/cclaude-build
        '';

        cclaude = pkgs.writeShellScriptBin "cclaude" ''
          set -euo pipefail

          token_file="${tokenFile}"
          image="${image}"

          # ── Preflight ──────────────────────────────────────────────────────
          if [[ ! -f "$token_file" ]]; then
            ${cclaude-setup}/bin/cclaude-setup
          fi

          if ! ${podman} image exists "$image" 2>/dev/null; then
            printf 'cclaude: image not found, building...\n' >&2
            ${cclaude-build}/bin/cclaude-build
          fi

          if [[ ! -S /nix/var/nix/daemon-socket/socket ]]; then
            cat >&2 <<EOF
          cclaude: nix daemon socket not found at /nix/var/nix/daemon-socket/socket
            Ensure your NixOS config has:
              nix.enable = true;
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
          EOF
            exit 1
          fi

          # ── Launch ─────────────────────────────────────────────────────────
          project_dir="$(pwd)"
          project_name="$(basename "$project_dir")"
          token="$(< "$token_file")"

          exec ${podman} run -it --rm \
            --name "cclaude-''${project_name}" \
            \
            --userns=keep-id \
            --user "$(id -u):$(id -g)" \
            \
            --cap-drop=ALL \
            --security-opt no-new-privileges:true \
            --security-opt label=disable \
            \
            --read-only \
            --tmpfs /tmp:rw,nosuid,nodev,size=2g,mode=1777 \
            --tmpfs /tmp/claude-home:rw,nosuid,nodev,size=256m,mode=700,uid="$(id -u)",gid="$(id -g)" \
            \
            -v "''${project_dir}:/workspace:rw" \
            \
            -v /nix/store:/nix/store:ro \
            -v /nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket \
            -v /nix/var/nix/profiles:/nix/var/nix/profiles:ro \
            \
            -v ${configVolume}:/tmp/claude-home/.claude:rw,U \
            \
            -e CLAUDE_CODE_OAUTH_TOKEN="''${token}" \
            -e CLAUDE_CONFIG_DIR=/tmp/claude-home/.claude \
            -e HOME=/tmp/claude-home \
            -e NIX_REMOTE=daemon \
            -e PATH="/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
            -e TERM="''${TERM:-xterm-256color}" \
            -e COLORTERM="''${COLORTERM:-truecolor}" \
            \
            -w /workspace \
            "$image" \
            "$@"
        '';

        cclaude-shell = pkgs.writeShellScriptBin "cclaude-shell" ''
          exec ${cclaude}/bin/cclaude bash
        '';

        cclaude-setup = pkgs.writeShellScriptBin "cclaude-setup" ''
          set -euo pipefail

          token_file="${tokenFile}"
          mkdir -p "$(dirname "$token_file")"

          # Run setup-token to start the OAuth flow
          printf 'Starting Claude Code OAuth flow...\n'
          claude setup-token

          # Prompt user to paste the token
          printf '\nPaste your OAuth token below, then press Ctrl-D:\n'
          install -m 600 /dev/stdin "$token_file"

          printf 'Token saved to %s\n' "$token_file"
        '';

      in {
        packages = {
          default = cclaude;
          inherit cclaude cclaude-build cclaude-update cclaude-shell cclaude-setup;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            podman
            shellcheck
            shfmt
            nil
            nixfmt
          ];

          shellHook = ''
            echo ""
            echo "cclaude development shell"
            echo "─────────────────────────"
            echo "Build image:  make build"
            echo "Run tests:    make test"
            echo "Lint:         make lint"
            echo ""
          '';
        };

        checks = {
          shellcheck = pkgs.runCommand "shellcheck" {
            buildInputs = [ pkgs.shellcheck ];
          } ''
            shellcheck ${self}/container/entrypoint.sh
            touch $out
          '';
        };
      }
    );
}
