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
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
