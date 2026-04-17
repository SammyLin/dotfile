#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
LOCAL="$HOME/.zshrc.local"

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

personalize_greeting() {
  # Skip if already configured or non-interactive
  if grep -q "^export GREET_" "$LOCAL" 2>/dev/null; then
    echo "  ok    greeting already configured in $LOCAL (use --reconfig to redo)"
    return
  fi
  if [[ ! -t 0 ]]; then
    echo "  skip  non-interactive shell — edit $LOCAL manually"
    return
  fi

  local default_name="$USER" default_city="Taipei" default_lang="zh"
  local name city lang
  echo "  Values get written to $LOCAL (not tracked by git)."
  read -r -p "  Name [$default_name]: " name
  read -r -p "  City for weather (empty = disable) [$default_city]: " city
  read -r -p "  Language (zh|en) [$default_lang]: " lang

  name="${name:-$default_name}"
  lang="${lang:-$default_lang}"
  # empty city on purpose = disable weather, so only use default if user hit Enter first time
  if [[ -z "${city+x}" ]]; then
    city="$default_city"
  fi

  {
    [[ -s "$LOCAL" ]] && echo ""
    echo "# Shell greeting (written by dotfile install.sh on $TS)"
    echo "export GREET_NAME=\"$name\""
    echo "export GREET_CITY=\"$city\""
    echo "export GREET_LANG=\"$lang\""
  } >> "$LOCAL"
  echo "  wrote $LOCAL"

  # Warm weather cache so the first shell already shows weather.
  # Cache is per-day (see zshrc _greet) — we just populate it here.
  if [[ -n "$city" ]]; then
    local cache_dir="$HOME/.cache/dotfile"
    local cache="$cache_dir/weather.${city// /_}.${lang}"
    mkdir -p "$cache_dir"
    if "$DIR/bin/weather" "$city" "$lang" > "$cache.tmp" 2>/dev/null; then
      mv "$cache.tmp" "$cache"
      echo "  warmed weather cache: $(cat "$cache")"
    else
      rm -f "$cache.tmp"
      echo "  weather warm-up failed (will retry on shell start)"
    fi
  fi
}

NO_BREW=0
RECONFIG=0
for arg in "$@"; do
  case "$arg" in
    --no-brew)  NO_BREW=1 ;;
    --reconfig) RECONFIG=1 ;;
    -h|--help)
      echo "Usage: $0 [--no-brew] [--reconfig]"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if (( RECONFIG )); then
  if [[ -f "$LOCAL" ]]; then
    cp "$LOCAL" "$LOCAL.backup.$TS"
    # Strip any existing GREET_ block
    sed -i.bak '/^# Shell greeting/,/^export GREET_LANG=/d' "$LOCAL"
    rm -f "$LOCAL.bak"
  fi
fi

echo "==> symlinks"
link "$DIR/zshrc"         "$HOME/.zshrc"
link "$DIR/zshenv"        "$HOME/.zshenv"
link "$DIR/starship.toml" "$HOME/.config/starship.toml"

echo "==> greeting personalization"
personalize_greeting

if (( NO_BREW )); then
  echo "Skipping brew bundle (--no-brew)"
elif command -v brew >/dev/null 2>&1; then
  echo "==> brew bundle"
  brew bundle --file="$DIR/Brewfile" --no-upgrade
else
  echo "Homebrew not found. Install from https://brew.sh then re-run."
fi

echo "Done. Open a new terminal or run: exec zsh"
