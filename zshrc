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
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
BREW_PREFIX="/opt/homebrew"

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
command -v starship >/dev/null && eval "$(starship init zsh)"

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
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

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

  # Weather — cache once per day. Refresh async if cache is stale.
  local weather=""
  if [[ -n "$city" ]]; then
    local cache_dir="$HOME/.cache/dotfile"
    local cache="$cache_dir/weather.${city// /_}.${lang}"
    local today=$(date +%Y%m%d)
    mkdir -p "$cache_dir"

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
}
_greet
unset -f _greet
