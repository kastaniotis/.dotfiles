#!/usr/bin/env sh
set -eu

cmd=""
while IFS= read -r line; do
  [ -z "$line" ] && break
  if [ -z "$cmd" ]; then
    cmd="$line"
  fi
done

if [ "$cmd" != "get" ]; then
  exit 0
fi

# Require the token to exist
if [ -z "${GITHUB_TOKEN:-}" ]; then
  exit 0
fi

# Allow username to be configured via dotfiles
user="${GIT_USER:-}"

cat <<EOF
username=$user
password=$GITHUB_TOKEN

EOF
