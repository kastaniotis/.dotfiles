#!/usr/bin/env bash
set -euo pipefail

SRC="${SCRIPT_DIR}/dotfiles"
DEST="$HOME"

if [ ! -d "$SRC" ]; then
  log_error "Dotfiles source directory not found: $SRC"
  exit 1
fi

log_section "Linking dotfiles from $SRC to $DEST"

# First ensure all directories exist
find "$SRC" -mindepth 1 -type d | while read -r dir; do
  rel="${dir#$SRC/}"
  target_dir="$DEST/$rel"

  if [ ! -d "$target_dir" ]; then
    log_info "Creating directory: ~/$rel"
    mkdir -p "$target_dir"
  else
    log_info "Directory already exists: ~/$rel"
  fi
done

# Then symlink all files
find "$SRC" -mindepth 1 -type f | while read -r file; do
  rel="${file#$SRC/}"
  target="$DEST/$rel"
  target_dir="$(dirname "$target")"

  if [ ! -d "$target_dir" ]; then
    log_info "Creating parent directory for: ~/$rel"
    mkdir -p "$target_dir"
  fi

  if [ -L "$target" ]; then
    # existing symlink, just replace
    log_info "Updating symlink: ~/$rel"
    ln -snf "$file" "$target"
  elif [ -e "$target" ]; then
    # existing real file, back it up then link
    backup="${target}.bak.$(date +%s)"
    log_warn "Backing up existing file: ~/$rel -> ${backup}"
    mv "$target" "$backup"
    log_info "Creating symlink: ~/$rel -> $file"
    ln -snf "$file" "$target"
  else
    log_info "Creating symlink: ~/$rel -> $file"
    ln -snf "$file" "$target"
  fi
done

log_section "Dotfile linking complete"
