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

# --- Plugins (brew installed) ---
[[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# --- FZF keybindings & completion (Ctrl+R for history search) ---
source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"

# --- Aliases ---
alias l='ls -lahG'
alias ll='ls -lahG'
alias ..='cd ..'
alias ...='cd ../..'
alias vi='nvim'
alias vim='nvim'

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
eval "$(starship init zsh)"

# --- Zoxide ---
eval "$(zoxide init zsh)"

# --- Cloud SDK ---
[[ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]] && \
  . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'
[[ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]] && \
  . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'

# --- LS Colors ---
export CLICOLOR=1
export LSCOLORS=ExGxFxdaCxDaDahbadacec

source "$BREW_PREFIX/opt/zinit/zinit.zsh"

# Git aliases
zinit snippet OMZP::git

# Docker 補全 + aliases
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose

# 常用工具
zinit snippet OMZP::brew           # brew 補全

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# --- Local overrides (not tracked) ---
# ~/.zshrc.local is written by install.sh and holds per-machine vars
# (GREET_NAME / GREET_CITY / GREET_LANG / secrets / tweaks).
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Greeting ---
# Full-width banner with ASCII mascot + date + weather, shown on every
# interactive shell start. Config from ~/.zshrc.local:
#   GREET_NAME / GREET_CITY / GREET_LANG  (zh | en)
# Weather via wttr.in, cached 30 min in ~/.cache/dotfile, refreshed async
# so the shell never blocks on the network.
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

  local weather=""
  if [[ -n "$city" ]] && command -v curl >/dev/null 2>&1; then
    local cache_dir="$HOME/.cache/dotfile"
    local cache="$cache_dir/weather.${city// /_}.${lang}"
    mkdir -p "$cache_dir"
    if [[ -f "$cache" ]]; then
      local age=$(( $(date +%s) - $(stat -f %m "$cache") ))
      (( age < 1800 )) && weather="$(cat "$cache")"
    fi
    # async refresh for next shell
    ( curl -sf --max-time 4 \
        "wttr.in/${city}?format=%l:+%c+%t+%C&lang=${lang}" \
        > "$cache.tmp" 2>/dev/null \
        && mv "$cache.tmp" "$cache" ) &!
  fi

  local -a tips_zh=(
    "z <dir> 跳到常用目錄"
    "ctrl+r 搜歷史"
    "bat <file> 取代 cat"
    "tree -L 2 看目錄結構"
    "gh pr view 看 PR"
    "nvml 載入 nvm"
  )
  local -a tips_en=(
    "z <dir> — jump to frecent dirs"
    "ctrl+r — fuzzy history"
    "bat <file> — better cat"
    "tree -L 2 — quick tree"
    "gh pr view — inspect PR"
    "nvml — load nvm lazily"
  )
  local tip
  if [[ "$lang" == "en" ]]; then
    tip="${tips_en[$((RANDOM % ${#tips_en[@]} + 1))]}"
  else
    tip="${tips_zh[$((RANDOM % ${#tips_zh[@]} + 1))]}"
  fi

  local dim=$'\e[2m' pink=$'\e[38;5;218m' reset=$'\e[0m'
  local cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
  local sep=""
  local i
  for (( i = 0; i < cols; i++ )); do sep+="─"; done

  print
  printf "  %s∩___∩%s     %s? %s%s\n"   "$pink" "$reset" "$dim" "$tip" "$reset"
  printf " %s( ・ω・)%s   %s, %s 👋\n"  "$pink" "$reset" "$hi" "$name"
  printf "  %sづ づ %s    %s\n"         "$pink" "$reset" "$date_str"
  printf "   %s¯¯¯%s      %s\n"         "$pink" "$reset" "${weather:-—}"
  printf "%s%s%s\n"                     "$dim" "$sep" "$reset"
}
_greet
unset -f _greet
