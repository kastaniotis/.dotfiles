#!/usr/bin/env sh
set -eu

cd ~

# Detect OS

PLATFORM="$(platform)"

ui show:title "Installing Prerequisites for ($PLATFORM)"

case "$PLATFORM" in
debian|ubuntu)
    apt-get update
    apt-get install -y curl git gnupg2 ca-certificates
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
    apt-get update
    apt-get install -y gum
    ui show:sucess "Installed Successfully"
    ;;
macos)
    if ! command -v brew >/dev/null 2>&1; then
        ui show:info "[INFO] Homebrew not found, installing…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update
    brew install git
    brew install gum
    ui show:success "Installed Successfully"
    ;;
esac

#git clone https://github.com/kastaniotis/.dotfiles
cd ~/.dotfiles

. $HOME/.dotfiles/install-role.sh