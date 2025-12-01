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

cd ~

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
    apt-get install -y curl git gnupg2 ca-certificates
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
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

git clone https://github.com/kastaniotis/.dotfiles
cd ~/.dotfiles

. install-role.sh