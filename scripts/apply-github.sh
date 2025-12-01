#!/usr/bin/env bash
set -euo pipefail

# Require gum so UX is consistent with the rest
if ! command -v gum >/dev/null 2>&1; then
  echo "[ERROR] gum is required for this script."
  echo "Run: ~/.dotfiles/scripts/install-tools.sh"
  exit 1
fi

log_info()  { gum style --foreground 39  "$@"; }
log_error() { gum style --foreground 196 "$@"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOPS_CONFIG="$REPO_ROOT/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/github.sops.yaml"

export SOPS_CONFIG

if [ ! -f "$SOPS_CONFIG" ]; then
  log_error ".sops.yaml not found at $SOPS_CONFIG"
  exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
  log_error "GitHub secrets file not found: $SECRETS_FILE"
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  log_error "yq is required. Install with: brew install yq  OR  apt install yq"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  log_error "git is required but not found."
  exit 1
fi

log_info "Decrypting GitHub token…"
tmpfile="$(mktemp)"
sops -d "$SECRETS_FILE" > "$tmpfile"

token="$(yq -r '.github.pat_push' "$tmpfile")"
rm -f "$tmpfile"

if [ "$token" = "null" ] || [ -z "$token" ]; then
  log_error "github.pat_push not found in secrets/github.sops.yaml"
  exit 1
fi

TARGET_DIR="$HOME/.config/dotfiles"
TARGET_FILE="$TARGET_DIR/github_token"

mkdir -p "$TARGET_DIR"

log_info "Writing GitHub token to $TARGET_FILE"
printf "%s\n" "$token" > "$TARGET_FILE"
chmod 600 "$TARGET_FILE"

log_info "GitHub token applied."

# --- configure git credential.helper globally -------------------------------

HELPER="!$HOME/.dotfiles/scripts/git-credential-env.sh"

current_global="$(git config --global --get credential.helper || echo "")"
if [ "$current_global" != "$HELPER" ]; then
  log_info "Configuring git to use env-based credential helper (global)…"
  git config --global credential.helper "$HELPER"
else
  log_info "Git global credential.helper already set to env-based helper."
fi

log_info "GitHub credential helper configured."
