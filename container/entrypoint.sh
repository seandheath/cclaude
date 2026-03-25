#!/bin/sh
set -eu

# Add claude install path and nix profile paths
export PATH="/home/claude/.local/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/system/sw/bin:${PATH}"

# Skip onboarding wizard
printf '{"hasCompletedOnboarding":true}\n' > "${HOME}/.claude.json"

exec "$@"
