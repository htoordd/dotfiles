#!/usr/bin/env bash
# ensure you set the executable bit on the file with `chmod u+x install.sh`
#
# This script executes during workspace creation in place of the default behavior
# (which is to symlink dotfiles from this repo to the home directory).
#
# It handles:
#   1. Symlinking all dotfiles (including nested .config/ and .claude/ dirs)
#   2. Any additional workspace setup you want to run

set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"

echo "==> Setting up dotfiles..."

# Symlink all dotfiles (files under directories starting with '.') to $HOME.
# This handles top-level dotfiles (.zshrc, .tmux.conf, etc.) as well as
# nested configs (.config/gh/config.yml, .claude/settings.json, etc.).
find "$DOTFILES_PATH" -type f -path "$DOTFILES_PATH/.*" |
while read -r df; do
  link=${df/$DOTFILES_PATH/$HOME}
  mkdir -p "$(dirname "$link")"
  ln -sf "$df" "$link"
  echo "  linked: ${df#$DOTFILES_PATH/}"
done

echo "==> Dotfiles linked!"

# Install workspace dependencies
echo "==> Installing workspace packages..."
sudo apt-get update -qq && sudo apt-get install -y -qq rsync xclip

# Make bin/ scripts executable and available.
# The .zshrc adds ~/dotfiles/bin to PATH directly.
if [ -d "$DOTFILES_PATH/bin" ]; then
  echo "==> Setting up bin/ scripts..."
  chmod +x "$DOTFILES_PATH/bin/"* 2>/dev/null || true
  echo "  bin/ scripts ready (available via PATH)"
fi

echo "==> Done!"
