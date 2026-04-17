#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1" dst="$2"

  # Already symlinked to the right place → nothing to do
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok    $dst"
    return
  fi

  # Something else is there (regular file, dir, or wrong symlink) → back up
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "  back  $dst → $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link  $dst → $src"
}

echo "==> symlinks"
link "$DIR/zshrc"         "$HOME/.zshrc"
link "$DIR/zshenv"        "$HOME/.zshenv"
link "$DIR/starship.toml" "$HOME/.config/starship.toml"

if [[ "${1:-}" == "--no-brew" ]]; then
  echo "Skipping brew bundle (--no-brew)"
elif command -v brew >/dev/null 2>&1; then
  echo "==> brew bundle"
  brew bundle --file="$DIR/Brewfile" --no-upgrade
else
  echo "Homebrew not found. Install from https://brew.sh then re-run."
fi

echo "Done. Open a new terminal or run: exec zsh"
