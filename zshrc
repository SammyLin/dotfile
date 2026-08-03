
# --- Core Env ---
export EDITOR=nvim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# --- Tab Completion (menu select) ---
# Only rebuild compinit dump once per day
autoload -Uz compinit
if [[ -z "$ZSH_COMPDUMP" ]]; then
  ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"
fi
if [[ "$ZSH_COMPDUMP"(#qNmh-24) ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -d "$ZSH_COMPDUMP"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Option + 左右：按單字移動
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# --- Homebrew ---
# Inlined `brew shellenv` output: shelling out to brew cost ~120ms per shell,
# and what it prints only changes if Homebrew itself moves. Re-derive with
# `brew shellenv` if that ever happens.
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export INFOPATH="/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}"
  typeset -U path fpath
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi
BREW_PREFIX="/opt/homebrew"

# --- Cached tool init ---
# `foo init zsh` prints the same script until the binary changes, so cache it
# and re-run the generator only when the binary is newer than the cache.
_cached_init() {
  local name="$1"; shift
  local bin="${commands[$1]}"
  [[ -n "$bin" ]] || return 0

  local cache="$HOME/.cache/dotfile/init.$name.zsh"
  if [[ ! -s "$cache" || "$bin" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    local tmp="$cache.$$.tmp"
    if "$@" >"$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
      mv "$tmp" "$cache"
    else
      # Generator failed — fall back to the live eval, cache nothing.
      rm -f "$tmp"
      eval "$("$@")" 2>/dev/null
      return
    fi
  fi
  source "$cache"
}

# --- PATH ---
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# --- Plugins (brew installed) ---
[[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# --- FZF keybindings & completion (Ctrl+R for history search) ---
[[ -r "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]] && \
  source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
[[ -r "$BREW_PREFIX/opt/fzf/shell/completion.zsh" ]] && \
  source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"

# --- Aliases ---
alias l='ls -lahG'
alias ll='ls -lahG'
alias ..='cd ..'
alias ...='cd ../..'
alias vi='nvim'
alias vim='nvim'
alias cc='claude'
alias oc='ocx opencode'

# GCP quick switch
function gpick() {
  local cfg=$(gcloud config configurations list --format="value(name)" | fzf)
  [ -n "$cfg" ] && gcloud config configurations activate "$cfg"
}

# --- Lazy NVM ---
load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ]] && . "$BREW_PREFIX/opt/nvm/nvm.sh"
}
alias nvml="load_nvm"

# --- Starship Prompt ---
_cached_init starship starship init zsh

# --- Cloud SDK ---
[[ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]] && \
  . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'
[[ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]] && \
  . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'

# --- LS Colors ---
export CLICOLOR=1
export LSCOLORS=ExGxFxdaCxDaDahbadacec

if [[ -r "$BREW_PREFIX/opt/zinit/zinit.zsh" ]]; then
  source "$BREW_PREFIX/opt/zinit/zinit.zsh"
  zinit snippet OMZP::git
  zinit snippet OMZP::docker
  zinit snippet OMZP::docker-compose
  zinit snippet OMZP::brew
  # zinit registers `zi` as an alias for itself — free it up so zoxide
  # can use it for the interactive picker. Full name `zinit` still works.
  unalias zi 2>/dev/null
fi

# --- Zoxide ---
# Init AFTER zinit + unalias above so zoxide's `zi` (interactive fzf picker)
# is the one that runs.
_cached_init zoxide zoxide init zsh

# --- worktrunk ---
# Wraps `wt` in a shell function so `wt switch` can cd the current shell into
# the worktree -- the bare binary can only print the path.
_cached_init worktrunk wt config shell init zsh

# --- Local overrides (not tracked) ---
# Machine-specific integrations (pnpm / Antigravity / Kiro / etc.) belong in
# ~/.zshrc.local, not here. install.sh migrates detected ones automatically.
# ~/.zshrc.local is written by install.sh and holds per-machine vars
# (GREET_NAME / GREET_CITY / GREET_LANG / secrets / tweaks).
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Greeting ---
# Full-width banner shown on every interactive shell start. Config from
# ~/.zshrc.local: GREET_NAME / GREET_CITY / GREET_LANG (zh | en).
# Quotes come from ~/.config/dotfile/quotes.txt if it exists, else from
# the tracked ~/.dotfiles/quotes.txt. Weather uses ~/.dotfiles/bin/weather
# with a once-per-day cache in ~/.cache/dotfile/ — the first shell of the
# day refreshes async so it never blocks.
_greet() {
  [[ -o interactive ]] || return
  local name="${GREET_NAME:-$USER}"
  local city="${GREET_CITY:-}"
  local lang="${GREET_LANG:-zh}"

  local hour=${$(date +%H)#0}
  local hi
  if [[ "$lang" == "en" ]]; then
    if   (( hour < 5 ));  then hi="Late night"
    elif (( hour < 12 )); then hi="Good morning"
    elif (( hour < 18 )); then hi="Good afternoon"
    else                       hi="Good evening"
    fi
  else
    if   (( hour < 5 ));  then hi="夜深了"
    elif (( hour < 12 )); then hi="早安"
    elif (( hour < 18 )); then hi="午安"
    else                       hi="晚安"
    fi
  fi

  local date_str
  if [[ "$lang" == "en" ]]; then
    date_str="$(date "+%Y/%m/%d %a")"
  else
    local -a wd=(一 二 三 四 五 六 日)
    date_str="$(date +%Y/%m/%d) 週${wd[$(date +%u)]}"
  fi

  # Shared cache scaffolding for any daily-cached feature in _greet
  # (weather, dotfiles fetch, ...). `today` is a YYYYMMDD stamp compared
  # against cache file mtimes to decide whether to refresh.
  local cache_dir="$HOME/.cache/dotfile"
  local today=$(date +%Y%m%d)
  mkdir -p "$cache_dir"

  # Weather — cache once per day. Refresh async if cache is stale.
  local weather=""
  if [[ -n "$city" ]]; then
    local cache="$cache_dir/weather.${city// /_}.${lang}"

    local cache_day=""
    [[ -f "$cache" ]] && cache_day=$(date -r "$(stat -f %m "$cache")" +%Y%m%d 2>/dev/null)

    if [[ "$cache_day" == "$today" ]]; then
      weather="$(cat "$cache")"
    else
      [[ -f "$cache" ]] && weather="$(cat "$cache")  ·  (更新中)"
      # Async refresh — don't block the shell. PID-suffixed tmp avoids
      # clobbering when two shells refresh concurrently.
      (
        local tmp="$cache.$$.tmp"
        if "$HOME/.dotfiles/bin/weather" "$city" "$lang" >"$tmp" 2>/dev/null; then
          mv "$tmp" "$cache"
        else
          rm -f "$tmp"
        fi
      ) &!
    fi
  fi

  # Quote: user file wins, else tracked default.
  local quote=""
  local qfile=""
  if [[ -s "$HOME/.config/dotfile/quotes.txt" ]]; then
    qfile="$HOME/.config/dotfile/quotes.txt"
  elif [[ -s "$HOME/.dotfiles/quotes.txt" ]]; then
    qfile="$HOME/.dotfiles/quotes.txt"
  fi
  if [[ -n "$qfile" ]]; then
    local -a qlines
    qlines=("${(@f)$(awk '!/^[[:space:]]*#/ && NF' "$qfile")}")
    (( ${#qlines} > 0 )) && quote="${qlines[$((RANDOM % ${#qlines} + 1))]}"
  fi

  local dim=$'\e[2m' pink=$'\e[38;5;218m' reset=$'\e[0m'
  local cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
  local sep=""
  local i
  for (( i = 0; i < cols; i++ )); do sep+="─"; done

  print
  printf "  %s∩___∩%s     %s%s%s\n"    "$pink" "$reset" "$dim" "$quote" "$reset"
  printf " %s( ・ω・)%s   %s, %s 👋\n"  "$pink" "$reset" "$hi" "$name"
  printf "  %sづ づ %s    %s\n"         "$pink" "$reset" "$date_str"
  printf "   %s¯¯¯%s      %s\n"         "$pink" "$reset" "${weather:-—}"
  printf "%s%s%s\n"                     "$dim" "$sep" "$reset"

  # Dotfiles sync status — shown only when ~/.dotfiles is not clean.
  # - Working-tree diff + ahead/behind are computed synchronously from
  #   refs already on disk (fast, no network).
  # - `git fetch` runs once per day in the background (&!), marked via
  #   ~/.cache/dotfile/dotfiles.fetched's mtime. Current shell shows
  #   whatever the last fetch saw; today's fetch lands for the next one.
  local DOTFILES_DIR="$HOME/.dotfiles"
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    local df_dirty df_ahead=0 df_behind=0
    df_dirty=$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    local df_fetch_mark="$cache_dir/dotfiles.fetched"
    local fetch_day=""
    [[ -f "$df_fetch_mark" ]] && \
      fetch_day=$(date -r "$(stat -f %m "$df_fetch_mark")" +%Y%m%d 2>/dev/null)
    if [[ "$fetch_day" != "$today" ]]; then
      ( git -C "$DOTFILES_DIR" fetch --quiet origin 2>/dev/null && \
        touch "$df_fetch_mark" ) &!
    fi

    local upstream
    upstream=$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
      # One rev-list, not two: --left-right --count prints "behind<TAB>ahead".
      local counts
      counts=$(git -C "$DOTFILES_DIR" rev-list --left-right --count \
        "$upstream...HEAD" 2>/dev/null)
      df_behind=${counts%%[[:space:]]*}
      df_ahead=${counts##*[[:space:]]}
      : "${df_behind:=0}" "${df_ahead:=0}"
    fi

    local -a parts
    if [[ "$lang" == "en" ]]; then
      (( df_dirty > 0 ))  && parts+=("$df_dirty uncommitted")
      (( df_ahead > 0 ))  && parts+=("$df_ahead ahead")
      (( df_behind > 0 )) && parts+=("$df_behind behind $upstream")
    else
      (( df_dirty > 0 ))  && parts+=("$df_dirty 個未 commit")
      (( df_ahead > 0 ))  && parts+=("領先 $df_ahead 個")
      (( df_behind > 0 )) && parts+=("落後 $upstream $df_behind 個")
    fi

    # Format mtime of the fetch marker: HH:MM today, MM/DD HH:MM otherwise.
    # Blank if no fetch has ever succeeded (first shell after clone).
    local last_fetch=""
    if [[ -f "$df_fetch_mark" ]]; then
      local mtime mday
      mtime=$(stat -f %m "$df_fetch_mark" 2>/dev/null)
      if [[ -n "$mtime" ]]; then
        mday=$(date -r "$mtime" +%Y%m%d 2>/dev/null)
        if [[ "$mday" == "$today" ]]; then
          last_fetch=$(date -r "$mtime" "+%H:%M" 2>/dev/null)
        else
          last_fetch=$(date -r "$mtime" "+%m/%d %H:%M" 2>/dev/null)
        fi
      fi
    fi

    local color line
    if (( ${#parts} > 0 )); then
      color=$'\e[38;5;221m'  # yellow — something needs attention
      local joined="${(j: · :)parts}"
      if [[ "$lang" == "en" ]]; then
        line="⚠  dotfiles: $joined"
      else
        line="⚠  dotfiles：$joined"
      fi
    else
      color=$'\e[38;5;114m'  # green — in sync
      if [[ "$lang" == "en" ]]; then
        line="✓  dotfiles in sync${last_fetch:+ · last fetch $last_fetch}"
      else
        line="✓  dotfiles 已同步${last_fetch:+ · 上次 fetch $last_fetch}"
      fi
    fi
    printf "%s%s%s\n" "$color" "$line" "$reset"
  fi

  # Missing-tool check — the CLIs this repo's configs actually depend on.
  # Runs at most once a day (same mtime-stamp trick as the weather and
  # fetch caches) so a normal shell start pays nothing. Silent when every
  # tool is present; a second always-on ✓ line would just pad the banner.
  local tools_cache="$cache_dir/tools.missing"
  local tools_day=""
  [[ -f "$tools_cache" ]] && \
    tools_day=$(date -r "$(stat -f %m "$tools_cache")" +%Y%m%d 2>/dev/null)

  if [[ "$tools_day" != "$today" ]]; then
    local -a missing
    local t
    for t in herdr bat starship zoxide fzf; do
      command -v "$t" >/dev/null 2>&1 || missing+=("$t")
    done
    [[ -d /Applications/Ghostty.app ]] || missing+=("ghostty")
    print -r -- "${(j: :)missing}" >"$tools_cache"
  fi

  local missing_line
  missing_line=$(<"$tools_cache")
  if [[ -n "$missing_line" ]]; then
    local warn=$'\e[38;5;221m'
    if [[ "$lang" == "en" ]]; then
      printf "%s⚠  not installed: %s · brew bundle --file ~/.dotfiles/Brewfile%s\n" \
        "$warn" "$missing_line" "$reset"
    else
      printf "%s⚠  沒裝：%s · brew bundle --file ~/.dotfiles/Brewfile%s\n" \
        "$warn" "$missing_line" "$reset"
    fi
  fi
}
_greet
unset -f _greet
# CF CLI completions
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"

export PATH="$PATH:$HOME/.maestro/bin"

# sentry
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
