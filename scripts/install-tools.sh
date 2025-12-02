#!/usr/bin/env sh
set -eu

ui show:title "Installing as a $ROLE on $PLATFORM"

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
        ui show:info "Installing FiraCode Nerd Font (Debian)…"

        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"

        # Download latest FiraCode Nerd Font release (variable font and normal weights)
        FIRA_ZIP="FiraCode.zip"
        FIRA_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"

        ui show:info "Downloading FiraCode Nerd Font…"
        curl -fsSL "$FIRA_URL" -o "/tmp/$FIRA_ZIP"

        ui show:info "Extracting FiraCode Nerd Font…"
        unzip -o "/tmp/$FIRA_ZIP" -d "$FONT_DIR" >/dev/null 2>&1

        ui show:info "Refreshing font cache…"
        fc-cache -fv >/dev/null

        ui show:info "FiraCode Nerd Font installed."
    fi
    ;;

  *)
    ui show:error "Unsupported OS: $OS"
    exit 1
    ;;
esac

ui show:success "Tool installation complete"