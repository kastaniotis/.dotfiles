#!/usr/bin/env bash
set -euo pipefail

# --- checks --------------------------------------------------------------

if ! command -v gum >/dev/null 2>&1; then
  echo "Error: gum not found in PATH." >&2
  echo "Install it first (e.g. 'brew install gum' or your distro's method)." >&2
  exit 1
fi

if ! command -v age-keygen >/dev/null 2>&1; then
  gum style --foreground 196 "Error: age-keygen not found in PATH."
  exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
  gum style --foreground 196 "Error: sops not found in PATH."
  exit 1
fi

# --- determine paths -----------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

OS="$(uname -s)"
case "$OS" in
  Darwin|Linux)
    KEY_FILE="${HOME}/.config/sops/age/keys.txt"
    ;;
  *)
    gum style --foreground 214 "Warning: unsupported OS '$OS', using ~/.config/sops/age/keys.txt"
    KEY_FILE="${HOME}/.config/sops/age/keys.txt"
    ;;
esac

mkdir -p "$(dirname "$KEY_FILE")"

gum style --border normal --border-foreground 212 --margin "1 0" --padding "0 2" \
  "age + sops setup" \
  "Repo root: $REPO_ROOT" \
  "Age key file: $KEY_FILE"

# --- ask for existing keys or generate new --------------------------------

gum style --margin "1 0" "You can either:" \
  "  • paste existing age keys" \
  "  • or press Enter to generate a new keypair"

AGE_PUB_INPUT=$(
  gum input \
    --placeholder "Leave empty to generate new keypair" \
    --header "Existing age PUBLIC key (age1...), or empty for new"
)

AGE_SECRET_INPUT=$(
  gum input \
    --placeholder "Leave empty to generate new keypair" \
    --header "Existing age SECRET key (AGE-SECRET-KEY-1...), or empty for new"
)

AGE_PUB=""
AGE_SECRET=""

if [[ -n "$AGE_PUB_INPUT" || -n "$AGE_SECRET_INPUT" ]]; then
  # User wants to use existing keys
  if [[ -z "$AGE_PUB_INPUT" || -z "$AGE_SECRET_INPUT" ]]; then
    gum style --foreground 196 "Error: you must provide BOTH public and secret keys, or leave BOTH empty."
    exit 1
  fi

  AGE_PUB="$AGE_PUB_INPUT"
  AGE_SECRET="$AGE_SECRET_INPUT"

  if [[ "$AGE_PUB" != age1* ]]; then
    gum style --foreground 196 "Error: public key must start with 'age1'."
    exit 1
  fi
  if [[ "$AGE_SECRET" != AGE-SECRET-KEY-1* ]]; then
    gum style --foreground 196 "Error: secret key must start with 'AGE-SECRET-KEY-1'."
    exit 1
  fi

  gum style --foreground 10 --margin "1 0" "Using provided age keypair."

  TS="$(date -Iseconds 2>/dev/null || date)"
  if [[ -f "$KEY_FILE" ]]; then
    backup="${KEY_FILE}.bak.$(date +%s)"
    mv "$KEY_FILE" "$backup"
    gum style --foreground 244 "Existing key file backed up to ${backup}"
  fi

  cat > "$KEY_FILE" <<EOF
# created: ${TS}
# public key: ${AGE_PUB}
${AGE_SECRET}
EOF

else
  # Generate new keypair
  gum style --foreground 10 --margin "1 0" "No keys provided, generating a new age keypair..."

  if [[ -f "$KEY_FILE" ]]; then
    backup="${KEY_FILE}.bak.$(date +%s)"
    mv "$KEY_FILE" "$backup"
    gum style --foreground 244 "Existing key file backed up to ${backup}"
  fi

  age-keygen -o "$KEY_FILE" >/dev/null

  AGE_PUB="$(grep 'public key:' "$KEY_FILE" | awk '{print $4}')"
  AGE_SECRET="$(grep '^AGE-SECRET-KEY-' "$KEY_FILE")"

  gum style --foreground 10 "New keypair written to: $KEY_FILE"
fi

# --- test encrypt/decrypt using SOPS_AGE_KEY directly --------------------

gum style --margin "1 0" --foreground 39 "Testing sops encryption/decryption with this keypair..."

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sops-test-XXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: .*
    age:
      - "${AGE_PUB}"
EOF

cat > test.yaml.plain <<EOF
foo: bar
answer: 42
EOF

cp test.yaml.plain test.yaml

# Encrypt using the secret directly
SOPS_CONFIG=.sops.yaml \
SOPS_AGE_KEY="${AGE_SECRET}" \
sops -e -i test.yaml

DECRYPTED="$(
  SOPS_CONFIG=.sops.yaml \
  SOPS_AGE_KEY="${AGE_SECRET}" \
  sops -d test.yaml
)"

if diff -u test.yaml.plain - <<<"$DECRYPTED" >/dev/null 2>&1; then
  gum style --foreground 10 "Success: sops encrypted and decrypted correctly with this key."
else
  gum style --foreground 196 "Failure: decrypted content did not match original."
  gum style --margin "1 0" "Original:" "$(cat test.yaml.plain)"
  gum style --margin "1 0" "Decrypted:" "$DECRYPTED"
  exit 1
fi

# --- write repo-level .sops.yaml ----------------------------------------

SOPS_CONFIG_PATH="${REPO_ROOT}/.sops.yaml"

if [[ -f "$SOPS_CONFIG_PATH" ]]; then
  backup="${SOPS_CONFIG_PATH}.bak.$(date +%s)"
  cp "$SOPS_CONFIG_PATH" "$backup"
  gum style --foreground 244 "Existing repo .sops.yaml backed up to ${backup}"
fi

cat > "$SOPS_CONFIG_PATH" <<EOF
creation_rules:
  - path_regex: secrets/.*\.sops\.ya?ml$
    age:
      - "${AGE_PUB}"
EOF

gum style --foreground 10 "Repo .sops.yaml written to: $SOPS_CONFIG_PATH"

# --- final info + password-manager reminder ------------------------------

gum style --border normal --border-foreground 212 --margin "1 0" --padding "1 2" \
  "Age keys in use:" \
  "" \
  "Public key:" \
  "  ${AGE_PUB}" \
  "" \
  "Secret key:" \
  "  ${AGE_SECRET}" \
  "" \
  "Store BOTH of these in your password manager." \
  "Losing the secret key means losing ALL encrypted secrets."

if gum confirm --default=false "Have you stored BOTH keys safely?"; then
  gum style --foreground 10 "OK, setup complete."
  exit 0
else
  gum style --foreground 214 "Aborting at your request. Keys remain on disk, but you did NOT confirm backup."
  exit 1
fi
