#!/usr/bin/env sh
set -eu

ui show:title "Setting up your personal GitHub Token"

username="$(gum input --header 'Leave the field empty to skip' --placeholder 'Github Username')"

token="$(gum input --header 'Leave the field empty to skip' --placeholder 'Github Token')"

if [ "$token" = "null" ] || [ -z "$token" ]; then
  ui show:warning "Skipping GitHub Token"
  exit 1
fi

TARGET_DIR="$HOME/.config/git"
TARGET_FILE="$TARGET_DIR/github.credentials"

mkdir -p "$TARGET_DIR"

# ui show:info "Writing GitHub token to $TARGET_FILE"
# printf "%s\n" "$token" > "$TARGET_FILE"
# 
write "https://$username:$token@github.com" "$TARGET_FILE"
chmod 600 "$TARGET_FILE"

ui show:success "GitHub token applied."

# --- configure git credential.helper globally -------------------------------

ui show:info "Configuring git to use credentials"

# Optional: clear any existing global helpers
git config --global credential.helper "store --file=$TARGET_FILE"

ui show:success "GitHub credential helper configured."

