#!/usr/bin/env sh
set -eu

ui show:title "Setting up your personal GitHub Token"

token="$(gum input --header 'Leave the field empty to skip' --placeholder 'Github Token')"

if [ "$token" = "null" ] || [ -z "$token" ]; then
  ui show:warning "Skipping GitHub Token"
  exit 1
fi

TARGET_DIR="$HOME/.config/dotfiles"
TARGET_FILE="$TARGET_DIR/github_token"

mkdir -p "$TARGET_DIR"

# ui show:info "Writing GitHub token to $TARGET_FILE"
# printf "%s\n" "$token" > "$TARGET_FILE"
# chmod 600 "$TARGET_FILE"
write "$token" "$TARGET_FILE"

ui show:success "GitHub token applied."

# --- configure git credential.helper globally -------------------------------

HELPER="$HOME/.dotfiles/scripts/git-credential-env.sh"

ui show:info "Configuring git to use env-based credential helper (global)…"

# Optional: clear any existing global helpers
git config --global --unset-all credential.helper 2>/dev/null || true

git config --global credential.helper "$HELPER"

ui show:success "GitHub credential helper configured."

