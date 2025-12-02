#!/usr/bin/env sh
set -eu

# --- determine paths -----------------------------------------------------

REPO_ROOT="$HOME/.dotfiles"
KEY_FILE="$HOME/.config/sops/age/keys.txt"
echo ""
echo "Setting up cryptography for your secrets"

if ! gum confirm "Do you want to set up your secrets and their encryption now?"; then
    echo "Aborting."
    exit
fi
echo ""
if [ -f "$KEY_FILE" ]; then
    choice="$(gum choose "Use existing AGE key file" "Generate or paste new AGE keys" --header "Existing Key File will be backed up")" || exit 1

    case "$choice" in
        "Use existing AGE key file")
            echo "Using: $KEY_FILE"
            exit
            ;;
        "Generate or paste new AGE keys")
            echo "Continuing..."
            ;;
    esac
fi

mkdir -p "$(dirname "$KEY_FILE")"

gum style --border normal --border-foreground 212 --margin "1 0" --padding "0 2" \
  "age + sops setup" \
  "Repo root: $REPO_ROOT" \
  "Age key file: $KEY_FILE"

# --- ask for existing keys or generate new --------------------------------
generation="$(gum choose "Paste your AGE keys" "Generate new AGE keys")" 

if [ "$generation" = "Paste your AGE keys" ]; then
  while :; do
    AGE_PUB_INPUT="$(gum input \
        --placeholder "age1..." \
        --header "Existing AGE PUBLIC key")" || exit 1

    if [ -z "$AGE_PUB_INPUT" ]; then
        gum style --foreground 196 "Input cannot be empty."
        continue
    fi

    case "$AGE_PUB_INPUT" in
        age1*)
            break
            ;;
        *)
            gum style --foreground 196 "Key must start with 'age1'."
            ;;
    esac
  done

  while :; do
    AGE_SECRET_INPUT="$(gum input \
        --placeholder "AGE-SECRET-KEY-1..." \
        --header "Existing AGE SECRET key")" || exit 1

    if [ -z "$AGE_SECRET_INPUT" ]; then
        gum style --foreground 196 "Input cannot be empty."
        continue
    fi

    case "$AGE_SECRET_INPUT" in
        AGE-SECRET-KEY-1*)
            break
            ;;
        *)
            gum style --foreground 196 "Key must start with 'AGE-SECRET-KEY-1'."
            ;;
    esac
  done

  AGE_PUB="$AGE_PUB_INPUT"
  AGE_SECRET="$AGE_SECRET_INPUT"

  gum style --foreground 10 --margin "1 0" "Using provided age keypair."

  TS="$(date -Iseconds 2>/dev/null || date)"
  if [ -f "$KEY_FILE" ]; then
    backup="${KEY_FILE}.bak.$(date +%s)"
    mv "$KEY_FILE" "$backup"
    gum style --foreground 244 "Existing key file backed up to ${backup}"
  fi

    cat > "$KEY_FILE" <<EOF
# created: ${TS}
# public key: ${AGE_PUB}
${AGE_SECRET}
EOF

  echo ""
  gum style --foreground 244 "Key file successfully Created"

fi


exit

  


  





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
