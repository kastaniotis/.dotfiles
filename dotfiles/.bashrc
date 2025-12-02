#!/usr/bin/env bash
# Load shared shell environment
if [ -f "$HOME/.shell_env" ]; then
  . "$HOME/.shell_env"
fi

# Your bash-specific config goes below
# (aliases, PS1, etc – we’ll fill this later)

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
