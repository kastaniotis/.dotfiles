#!/usr/bin/env sh
set -euo

log_section "Installing as a $ROLE on $PLATFORM"

COMMON_PKGS="ansible neovim starship fzf yq bat eza git-delta tmux"
DEBIAN_PKGS="kitty"
MAC_PKGS="kitty font-fira-code-nerd-font"


case "$PLATFORM" in
  macos)
    for pkg in $COMMON_PKGS;do
      brew install "$pkg"
    done

    # Macos is always UI
    for pkg in $MAC_PKGS;do
      brew install "$pkg"
    done

    ;;

  debian|ubuntu)
    for pkg in $COMMON_PKGS; do
      apt-get install -y "$pkg"
    done
    if [ "$ROLE" = "workstation" ]; then
    
        for pkg in $DEBIAN_PKGS; do
          apt-get install -y "$pkg"
        done

        # ---------- Install FiraCode Nerd Font ----------
        log_info "Installing FiraCode Nerd Font (Debian)…"

        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"

        # Download latest FiraCode Nerd Font release (variable font and normal weights)
        FIRA_ZIP="FiraCode.zip"
        FIRA_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"

        log_info "Downloading FiraCode Nerd Font…"
        curl -fsSL "$FIRA_URL" -o "/tmp/$FIRA_ZIP"

        log_info "Extracting FiraCode Nerd Font…"
        unzip -o "/tmp/$FIRA_ZIP" -d "$FONT_DIR" >/dev/null 2>&1

        log_info "Refreshing font cache…"
        fc-cache -fv >/dev/null

        log_info "FiraCode Nerd Font installed."
    fi
    ;;

  *)
    log_error "Unsupported OS: $OS"
    exit 1
    ;;
esac

log_section "Tool installation complete"
log_info "Installed / ensured: git, gum, ansible, neovim"
