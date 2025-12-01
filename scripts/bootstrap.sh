#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Dotfiles bootstrap starting ==="
echo "Repo root: $REPO_ROOT"

# 1) Install tools (git, gum, ansible, neovim, starship, kitty, fonts, etc.)
if [ -x "$REPO_ROOT/scripts/install-tools.sh" ]; then
  echo "[1/5] Running install-tools.sh..."
  "$REPO_ROOT/scripts/install-tools.sh"
else
  echo "ERROR: scripts/install-tools.sh not found or not executable."
  exit 1
fi

# 2) Setup age + sops key if needed (only if key file missing)
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
  if [ -x "$REPO_ROOT/scripts/setup-age-sops.sh" ]; then
    echo "[2/5] Running setup-age-sops.sh (no age key found)..."
    "$REPO_ROOT/scripts/setup-age-sops.sh"
  else
    echo "ERROR: scripts/setup-age-sops.sh not found or not executable."
    exit 1
  fi
else
  echo "[2/5] Skipping age+sops setup (key file already exists: $AGE_KEY_FILE)"
fi

# 3) Link dotfiles into $HOME
if [ -x "$REPO_ROOT/scripts/link-dotfiles.sh" ]; then
  echo "[3/5] Linking dotfiles..."
  "$REPO_ROOT/scripts/link-dotfiles.sh"
else
  echo "ERROR: scripts/link-dotfiles.sh not found or not executable."
  exit 1
fi

# 4) Apply SSH keys (if secrets file exists)
SSH_SECRETS_FILE="$REPO_ROOT/secrets/ssh_keys.sops.yaml"
if [ -f "$SSH_SECRETS_FILE" ]; then
  if [ -x "$REPO_ROOT/scripts/apply-ssh.sh" ]; then
    echo "[4/5] Applying SSH keys from secrets..."
    "$REPO_ROOT/scripts/apply-ssh.sh"
  else
    echo "WARNING: scripts/apply-ssh.sh not executable or missing. Skipping SSH."
  fi
else
  echo "[4/5] No SSH secrets file found, skipping SSH key install."
fi

# 5) Apply GitHub token + configure git helper (if secrets file exists)
GITHUB_SECRETS_FILE="$REPO_ROOT/secrets/github.sops.yaml"
if [ -f "$GITHUB_SECRETS_FILE" ]; then
  if [ -x "$REPO_ROOT/scripts/apply-github.sh" ]; then
    echo "[5/5] Applying GitHub token from secrets..."
    "$REPO_ROOT/scripts/apply-github.sh"
  else
    echo "WARNING: scripts/apply-github.sh not executable or missing. Skipping GitHub token."
  fi
else
  echo "[5/5] No GitHub secrets file found, skipping GitHub token."
fi

echo "=== Dotfiles bootstrap complete ==="
echo "Open a new terminal (kitty) to pick up the new shell, aliases, and prompt."
