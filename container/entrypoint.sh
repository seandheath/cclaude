#!/bin/sh
set -eu

# ~/.claude.json must exist at HOME root (separate from CLAUDE_CONFIG_DIR)
# to bypass the onboarding wizard. Re-created on each run since HOME is tmpfs.
CLAUDE_ACCOUNT_FILE="${HOME}/.claude.json"
mkdir -p "$(dirname "${CLAUDE_ACCOUNT_FILE}")"
printf '{"hasCompletedOnboarding":true}\n' > "${CLAUDE_ACCOUNT_FILE}"

exec "$@"
