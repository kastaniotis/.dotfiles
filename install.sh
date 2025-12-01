#!/usr/bin/env bash
set -euo pipefail

# Small helper: check if a command exists
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Logging helpers (use gum if present, fall back to echo)

log_info() {
  if has_cmd gum; then
    gum style --foreground 39 "$@"
  else
    echo "[INFO] $*"
  fi
}

log_success() {
  if has_cmd gum; then
    gum style --foreground 46 "$@"
  else
    echo "[OK] $*"
  fi
}

log_warn() {
  if has_cmd gum; then
    gum style --foreground 214 "$@"
  else
    echo "[WARN] $*"
  fi
}

log_error() {
  if has_cmd gum; then
    gum style --foreground 196 "$@"
  else
    echo "[ERROR] $*" >&2
  fi
}

log_section() {
  if has_cmd gum; then
    gum style --border normal --border-foreground 212 --margin "1 0" --padding "0 2" "$@"
  else
    echo
    echo "=== $* ==="
  fi
}

# Detect OS

OS="$(uname -s 2>/dev/null)"

if [ "$OS" = "Darwin" ]; then
    PLATFORM="macos"
elif [ "$OS" = "Linux" ]; then
    if grep -qi 'ubuntu' /etc/os-release; then
        PLATFORM="ubuntu"
    elif grep -qi 'debian' /etc/os-release; then
        PLATFORM="debian"
    fi
else
  echo "Unknown Platform"
  exit
fi

log_info "Installing Prerequisites"

case "$PLATFORM" in
debian|ubuntu)
    apt-get update
    apt-get install -y curl git ca-certificates
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    apt-get update
    apt-get install -y gum
    log_success "Installed Successfully"
    ;;
macos)
    if ! command -v brew >/dev/null 2>&1; then
        echo "[INFO] Homebrew not found, installing…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update
    brew install git
    brew install gum
    log_success "Installed Successfully"
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# . "$SCRIPT_DIR/scripts/helpers/platform.sh"
# . "$SCRIPT_DIR/scripts/helpers/log.sh"

# PLATFORM="$(detect_platform)"
# log_section "Detected Platform: $PLATFORM"

# install_prerequisites "$PLATFORM"


ROLE="$(gum choose --limit 1 --header 'Select the Role of this machine' \
    workstation \
    server
)"

. "$SCRIPT_DIR/scripts/install-tools.sh" 
. "$SCRIPT_DIR/scripts/link-dotfiles.sh" 

exit

# --- ROLE-SPECIFIC BOOTSTRAP --------------------------------------------------

case "$ROLE" in
  workstation)
    echo "[INFO] Running workstation bootstrap…"
    if [ -x "./scripts/bootstrap.sh" ]; then
      ./scripts/bootstrap.sh
    else
      echo "[ERROR] scripts/bootstrap.sh not found or not executable."
      exit 1
    fi
    ;;

  server)
    echo "[INFO] Running server-safe bootstrap (no private keys, no age identity)…"

    # 1) Install tools (but you may want to slim this down for servers later)
    if [ -x "./scripts/install-tools.sh" ]; then
      ./scripts/install-tools.sh
    else
      echo "[ERROR] scripts/install-tools.sh not found or not executable."
      exit 1
    fi

    # 2) Link dotfiles (prompt, aliases, tmux, etc.).
    #    NOTE: This will *not* be able to decrypt secrets on the server
    #    because we will NEVER copy the age key there.
    if [ -x "./scripts/link-dotfiles.sh" ]; then
      ./scripts/link-dotfiles.sh
    else
      echo "[ERROR] scripts/link-dotfiles.sh not found or not executable."
      exit 1
    fi

    echo "[INFO] Skipping age+sops setup and secret application on server role."
    echo "[INFO] Do NOT copy ~/.config/sops/age/keys.txt to servers."
    ;;

esac

echo "[INFO] Dotfiles install finished (role: ${ROLE})"
