#!/usr/bin/env sh

. scripts/helpers/log.sh

detect_platform() {
    OS="$(uname -s 2>/dev/null)"

    if [ "$OS" = "Darwin" ]; then
        echo "macos"
        return
    fi

    if [ "$OS" = "Linux" ]; then
        if grep -qi 'ubuntu' /etc/os-release; then
            echo "ubuntu"
            return
        elif grep -qi 'debian' /etc/os-release; then
            echo "debian"
            return
        fi
    fi

    echo "Unknown Platform"
    exit
}

install_prerequisites() {
    OS="$1"

    log_info "Installing Prerequisites"

    case "$OS" in
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

}