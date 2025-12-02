#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$HOME/.dotfiles"

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
