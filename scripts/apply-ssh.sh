#!/usr/bin/env bash
set -euo pipefail

# --- REQUIREMENTS -------------------------------------------------------------

if ! command -v gum >/dev/null 2>&1; then
  echo "[ERROR] gum is required for this script."
  echo "Please run: ~/.dotfiles/scripts/install-tools.sh"
  exit 1
fi

# --- LOGGING ------------------------------------------------------------------

log_info()  { gum style --foreground 39  "$@"; }
log_warn()  { gum style --foreground 214 "$@"; }
log_error() { gum style --foreground 196 "$@"; }

# --- PATHS --------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOPS_CONFIG="$REPO_ROOT/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/ssh_keys.sops.yaml"

export SOPS_CONFIG

# --- VALIDATION ---------------------------------------------------------------

if [ ! -f "$SOPS_CONFIG" ]; then
  log_error ".sops.yaml not found at $SOPS_CONFIG"
  exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
  log_error "SSH secrets file not found: $SECRETS_FILE"
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  log_error "yq is required. Install with: brew install yq  OR  apt install yq"
  exit 1
fi

# --- DECRYPT ------------------------------------------------------------------

log_info "Decrypting SSH secrets…"

tmpfile="$(mktemp)"
sops -d "$SECRETS_FILE" > "$tmpfile"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# --- INSTALL FUNCTION ---------------------------------------------------------

install_key() {
  local name="$1"
  local priv_target="$2"
  local pub_target="$3"

  log_info "Installing SSH key: $name"

  priv="$(yq -r ".ssh.$name.private" "$tmpfile")"
  pub="$(yq -r ".ssh.$name.public" "$tmpfile")"

  if [ "$priv" = "null" ] || [ "$pub" = "null" ]; then
    log_warn "Skipping $name — missing in secrets file."
    return
  fi

  # Backup
  for f in "$priv_target" "$pub_target"; do
    if [ -e "$f" ] && [ ! -L "$f" ]; then
      backup="${f}.bak.$(date +%s)"
      log_warn "Backing up existing $f → $backup"
      mv "$f" "$backup"
    fi
  done

  # Private
  log_info "Writing $priv_target"
  printf "%s\n" "$priv" > "$priv_target"
  chmod 600 "$priv_target"

  # Public
  log_info "Writing $pub_target"
  printf "%s\n" "$pub" > "$pub_target"
  chmod 644 "$pub_target"
}

# --- EXECUTION ----------------------------------------------------------------

install_key dimkasta "$HOME/.ssh/id_rsa"       "$HOME/.ssh/id_rsa.pub"
install_key ops       "$HOME/.ssh/id_ed25519"  "$HOME/.ssh/id_ed25519.pub"

rm -f "$tmpfile"
log_info "SSH keys installed successfully."
