- Managed with git + shell + sops + age
- Contains:
  - dotfiles for shell, git, neovim, etc.
  - encrypted secrets (SSH keys, tokens) in ./secrets

docker run -it --rm debian:stable-slim bash

apt update
apt install curl
curl -fSL https://raw.githubusercontent.com/kastaniotis/.dotfiles/master/install.sh | sh