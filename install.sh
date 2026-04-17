#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "backing up $dst -> $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

link "$DIR/zshrc"         "$HOME/.zshrc"
link "$DIR/zshenv"        "$HOME/.zshenv"
link "$DIR/starship.toml" "$HOME/.config/starship.toml"

if command -v brew >/dev/null 2>&1; then
  echo "==> brew bundle"
  brew bundle --file="$DIR/Brewfile"
else
  echo "Homebrew not found. Install from https://brew.sh then re-run."
fi

echo "Done. Open a new terminal or run: exec zsh"
