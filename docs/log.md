# cclaude — Decision Log

## 2026-03-25 — Initial Architecture

**Decision:** Use `node:22-bookworm-slim` as base image with Claude Code installed via official installer script.
**Rationale:** Node is pre-installed, image stays lean. Official installer is the canonical installation method.
**Alternatives considered:** `nixos/nix` base (used in llm-devcontainer — heavier, nix-in-nix complexity), Alpine (missing glibc deps).

## 2026-03-25 — Package-only Flake Distribution

**Decision:** Expose CLI tools as `writeShellScriptBin` packages, no NixOS or home-manager modules.
**Rationale:** Simplest integration path for public consumption. Users just add to `environment.systemPackages` or `home.packages`. Modules add complexity without clear benefit for a CLI tool.
**Alternatives considered:** home-manager module (declarative config), NixOS module (system-level integration).

## 2026-03-25 — OAuth Token File Auth

**Decision:** Single auth method — OAuth token from `~/.config/cclaude/token`.
**Rationale:** Claude Code's native auth mechanism. API keys are a different product (API vs Claude Code).
**Alternatives considered:** Supporting both OAuth and ANTHROPIC_API_KEY.

## 2026-03-25 — Host Nix Daemon Socket Mount

**Decision:** Mount host nix daemon socket into container, set `NIX_REMOTE=daemon`.
**Rationale:** Zero cold-start for nix operations. Store writes go through the host daemon — Claude can't corrupt store paths directly. No need to run a nix daemon inside the container.
**Alternatives considered:** Running nix daemon inside container (complex, wasteful), nix store bind mount rw (security risk).

## 2026-03-25 — Tmpfs HOME with Persistent .claude Volume

**Decision:** `HOME=/tmp/claude-home` on tmpfs, with `cclaude-config` named volume mounted at `$HOME/.claude`.
**Rationale:** All home writes are ephemeral except Claude credentials/settings. Prevents state accumulation across runs. Volume persists auth so users don't re-login each time.
**Alternatives considered:** Full persistent home volume (state bloat over time), fully ephemeral (must re-auth every run).
