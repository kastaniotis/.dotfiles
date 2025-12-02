# Load shared shell environment
if [ -f "$HOME/.shell_env" ]; then
  . "$HOME/.shell_env"
fi

# Your zsh-specific config goes below
# (prompt, completion, etc – we’ll fill this later)

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Added by installer
export PATH="$HOME/.local/bin:$PATH"
