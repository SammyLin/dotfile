#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
LOCAL="$HOME/.zshrc.local"

link() {
  local src="$1" dst="$2"

  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok    $dst"
    return
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "  back  $dst → $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link  $dst → $src"
}

# Escape a string for safe embedding in a sourced shell script.
# Uses printf %q which produces valid shell tokens for bash and zsh.
shell_quote() {
  printf '%q' "$1"
}

# Idempotently replace a sentinel-marked block in a file.
# Usage: ensure_block <file> <name> <content>
ensure_block() {
  local file="$1" name="$2" content="$3"
  local begin="# >>> dotfile:${name} >>>"
  local end="# <<< dotfile:${name} <<<"

  touch "$file"
  if grep -qF "$begin" "$file"; then
    # Replace in-place; surrounding whitespace is preserved. Content passed
    # via ENVIRON so awk doesn't reinterpret backslash escapes in -v.
    local tmp="$file.tmp.$$"
    DOTFILE_BLOCK_CONTENT="$content" \
    awk -v b="$begin" -v e="$end" '
      $0 == b { print; print ENVIRON["DOTFILE_BLOCK_CONTENT"]; skip = 1; next }
      skip && $0 == e { print; skip = 0; next }
      !skip { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  else
    {
      [[ -s "$file" ]] && echo ""
      echo "$begin"
      printf '%s\n' "$content"
      echo "$end"
    } >> "$file"
  fi
}

remove_block() {
  local file="$1" name="$2"
  local begin="# >>> dotfile:${name} >>>"
  local end="# <<< dotfile:${name} <<<"
  [[ -f "$file" ]] || return 0
  local tmp="$file.tmp.$$"
  awk -v b="$begin" -v e="$end" '
    $0 == b { skip = 1; next }
    skip && $0 == e { skip = 0; next }
    !skip { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Write a block if detected, prune it if not. Makes migrate_machine_integrations
# symmetric: uninstalling a tool removes its block on the next install.sh run.
sync_block() {
  local name="$1" detected="$2" content="$3"
  if (( detected )); then
    ensure_block "$LOCAL" "$name" "$content"
    echo "  +     $name"
  elif grep -qF "# >>> dotfile:${name} >>>" "$LOCAL" 2>/dev/null; then
    remove_block "$LOCAL" "$name"
    echo "  -     $name (no longer detected)"
  fi
}

# Auto-migrate pre-sentinel `export GREET_*` lines into a sentinel block,
# preserving the user's existing values. Called before personalize_greeting
# so a legacy config gets upgraded silently on the next install.sh run.
migrate_legacy_greeting() {
  [[ -f "$LOCAL" ]] || return 0
  grep -qF "# >>> dotfile:greeting >>>" "$LOCAL" 2>/dev/null && return 0
  grep -q "^export GREET_" "$LOCAL" 2>/dev/null || return 0

  local name city lang
  name=$(sed -n 's/^export GREET_NAME=\(.*\)$/\1/p' "$LOCAL" | head -1)
  city=$(sed -n 's/^export GREET_CITY=\(.*\)$/\1/p' "$LOCAL" | head -1)
  lang=$(sed -n 's/^export GREET_LANG=\(.*\)$/\1/p' "$LOCAL" | head -1)
  # Legacy values were written as `"value"` — strip one layer of quotes.
  name=${name#\"}; name=${name%\"}
  city=${city#\"}; city=${city%\"}
  lang=${lang#\"}; lang=${lang%\"}

  cp "$LOCAL" "$LOCAL.backup.$TS"
  sed -i.bak -e '/^# Shell greeting/d' -e '/^export GREET_NAME=/d' \
             -e '/^export GREET_CITY=/d' -e '/^export GREET_LANG=/d' "$LOCAL"
  rm -f "$LOCAL.bak"

  local block
  block=$(cat <<EOF
# Shell greeting config (migrated from legacy format on $TS)
export GREET_NAME=$(shell_quote "$name")
export GREET_CITY=$(shell_quote "$city")
export GREET_LANG=$(shell_quote "$lang")
EOF
)
  ensure_block "$LOCAL" "greeting" "$block"
  echo "  migrated legacy greeting → sentinel format (backup: $LOCAL.backup.$TS)"
}

personalize_greeting() {
  if grep -qF "# >>> dotfile:greeting >>>" "$LOCAL" 2>/dev/null; then
    echo "  ok    greeting already configured in $LOCAL (use --reconfig to redo)"
    return
  fi
  if [[ ! -t 0 ]]; then
    echo "  skip  non-interactive shell — edit $LOCAL manually"
    return
  fi

  local default_name="$USER" default_lang="zh"
  local name city lang
  echo "  Values get written to $LOCAL (not tracked by git)."
  read -r -p "  Name [$default_name]: " name
  read -r -p "  City for weather (blank = disable): " city
  read -r -p "  Language (zh|en) [$default_lang]: " lang

  name="${name:-$default_name}"
  lang="${lang:-$default_lang}"

  local block
  block=$(cat <<EOF
# Shell greeting config (written by install.sh on $TS)
export GREET_NAME=$(shell_quote "$name")
export GREET_CITY=$(shell_quote "$city")
export GREET_LANG=$(shell_quote "$lang")
EOF
)
  ensure_block "$LOCAL" "greeting" "$block"
  echo "  wrote $LOCAL"

  # Warm weather cache so the first shell already shows weather.
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

# Detect machine-specific integrations (formerly inlined in zshrc) and
# write them to ~/.zshrc.local with sentinel markers so they stay out of
# the tracked repo. Idempotent.
migrate_machine_integrations() {
  local has_pnpm=0 has_ag=0 has_kiro=0
  [[ -d "$HOME/Library/pnpm" ]] && has_pnpm=1
  [[ -d "$HOME/.antigravity/antigravity/bin" ]] && has_ag=1
  command -v kiro >/dev/null 2>&1 && has_kiro=1

  sync_block "pnpm" "$has_pnpm" 'export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac'

  sync_block "antigravity" "$has_ag" \
    'export PATH="$HOME/.antigravity/antigravity/bin:$PATH"'

  sync_block "kiro" "$has_kiro" \
    '[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"'
}

install_go_tools() {
  command -v go >/dev/null 2>&1 || { echo "  skip  go not installed"; return; }
  local gobin
  gobin="$(go env GOBIN)"
  [[ -z "$gobin" ]] && gobin="$(go env GOPATH)/bin"
  local pkgs=(
    "google.golang.org/protobuf/cmd/protoc-gen-go@latest"
    "google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
  )
  local p
  for p in "${pkgs[@]}"; do
    local bin="${p##*/}"; bin="${bin%@*}"
    if [[ -x "$gobin/$bin" ]]; then
      echo "  ok    $bin"
    else
      echo "  go install $p"
      go install "$p" || echo "  warn  failed: $p"
    fi
  done
}

install_cargo_tools() {
  command -v cargo >/dev/null 2>&1 || { echo "  skip  cargo not installed"; return; }
  local p
  for p in agg; do
    if command -v "$p" >/dev/null 2>&1; then
      echo "  ok    $p"
    else
      echo "  cargo install $p"
      cargo install "$p" || echo "  warn  failed: $p"
    fi
  done
}

# herdr keeps its plugin registry in ~/.config/herdr/plugins, outside this repo,
# so a fresh machine has the keybindings from config.toml pointing at plugins
# that aren't there yet.
install_herdr_plugins() {
  command -v herdr >/dev/null 2>&1 || { echo "  skip  herdr not installed"; return; }

  local installed
  installed="$(herdr plugin list 2>/dev/null || true)"

  if [[ "$installed" == *"worktrunk"* ]]; then
    echo "  ok    worktrunk"
  else
    echo "  herdr plugin install worktrunk"
    herdr plugin install devashish2203/herdr-worktrunk --yes >/dev/null 2>&1 ||
      echo "  warn  failed: worktrunk"
  fi
}

# The `ccw` alias runs Claude Code against ~/.claude-work so the work account's
# credentials stay separate from the personal one. Config is meant to be shared,
# not duplicated, so everything except auth and history is symlinked back to
# ~/.claude — install a plugin on either side and both see it.
setup_claude_work_config() {
  local main="$HOME/.claude" work="$HOME/.claude-work"
  [[ -d "$main" ]] || { echo "  skip  ~/.claude not found"; return; }

  mkdir -p "$work"
  local f
  for f in settings.json CLAUDE.md RTK.md statusline.js \
           plugins skills hooks parked-skills workflows lib .agents; do
    [[ -e "$main/$f" ]] || continue
    link "$main/$f" "$work/$f"
  done
  echo "  run 'ccw' in a new shell to sign in to the work account"
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

if (( RECONFIG )) && [[ -f "$LOCAL" ]]; then
  cp "$LOCAL" "$LOCAL.backup.$TS"
  remove_block "$LOCAL" "greeting"
  # Also wipe legacy (pre-sentinel) greeting lines if present.
  sed -i.bak -e '/^# Shell greeting/d' -e '/^export GREET_NAME=/d' \
             -e '/^export GREET_CITY=/d' -e '/^export GREET_LANG=/d' "$LOCAL"
  rm -f "$LOCAL.bak"
fi

echo "==> symlinks"
link "$DIR/zshrc"          "$HOME/.zshrc"
link "$DIR/zshenv"         "$HOME/.zshenv"
link "$DIR/starship.toml"  "$HOME/.config/starship.toml"
link "$DIR/tmux.conf"      "$HOME/.tmux.conf"
link "$DIR/ghostty-config" "$HOME/.config/ghostty/config"
# ghostty-herdr.conf is pulled in by ghostty-config's own config-file line,
# so it needs no symlink of its own.
link "$DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link "$DIR/herdr/sounds"      "$HOME/.config/herdr/sounds"
# Orca reads this once at startup -- after changing it, Settings → Keyboard
# Shortcuts → Reload from Disk, or restart the app.
link "$DIR/orca/keybindings.json" "$HOME/.orca/keybindings.json"

install_herdr_plugins

echo "==> claude work account config (~/.claude-work)"
setup_claude_work_config

echo "==> machine integrations → $LOCAL"
migrate_machine_integrations

echo "==> greeting personalization"
migrate_legacy_greeting
personalize_greeting

if (( NO_BREW )); then
  echo "Skipping brew bundle (--no-brew)"
elif command -v brew >/dev/null 2>&1; then
  echo "==> brew bundle"
  brew bundle --file="$DIR/Brewfile" --no-upgrade
  echo "==> go tools"
  install_go_tools
  echo "==> cargo tools"
  install_cargo_tools
else
  echo "Homebrew not found. Install from https://brew.sh then re-run."
fi

echo "Done. Open a new terminal or run: exec zsh"
