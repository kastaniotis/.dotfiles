#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$HOME/.dotfiles"

ROLE="$(ui show:choice 'Select the Role of this machine' 'workstation' 'server')"

. "$SCRIPT_DIR/scripts/install-tools.sh" 
. "$SCRIPT_DIR/scripts/link-dotfiles.sh" 