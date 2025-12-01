#!/usr/bin/env sh

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