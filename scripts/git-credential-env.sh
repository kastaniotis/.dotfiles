#!/usr/bin/env sh
set -eu

cmd="${1:-}"

# Git calls: helper <cmd>
# We only care about `get`
[ "$cmd" = "get" ] || exit 0

# Read the query from stdin (protocol/host/path). We don't need it,
# but we must consume it so Git isn't confused.
while IFS= read -r line; do
  [ -z "$line" ] && break
done

# Require the token to exist
: "${GITHUB_TOKEN:=}" || true
if [ -z "$GITHUB_TOKEN" ]; then
  # No credential → tell Git "I have nothing"
  exit 1
fi

# Allow username to be configured; fallback to something sane
user="${GIT_USER:-${USER:-}}"
[ -n "$user" ] || user="git"

printf 'username=%s\n' "$user"
printf 'password=%s\n\n' "$GITHUB_TOKEN"
