# dotfile

*[繁體中文版](README.zh-TW.md)*

Sammy's personal dotfiles — one repo, multiple Macs.

Started in 2012 as a single oh-my-zsh theme; now a full zsh + zinit +
starship + brew bundle setup. Original theme is in git history.

## Setup on a new machine

```sh
git clone git@github.com:SammyLin/dotfile.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` will:

1. Symlink `zshrc` / `zshenv` / `starship.toml` into `$HOME`
   (existing files get backed up to `*.backup.<timestamp>` first;
   if the symlink already points to the right place it prints `ok`
   and does nothing).
2. Prompt for greeting personalization and write to `~/.zshrc.local`
   (**not** tracked — machine-local).
3. Run `brew bundle --no-upgrade` to install anything in `Brewfile`.

Flags:

- `--no-brew` skip step 3 (quick re-link / re-config)
- `--reconfig` wipe the `GREET_*` block in `~/.zshrc.local` and re-prompt

## Layout

| File | Purpose |
|---|---|
| `zshrc` | main shell config — aliases, plugins, starship, zinit, greeting |
| `zshenv` | early env (cargo) |
| `starship.toml` | prompt config (Catppuccin, minimal-pills) |
| `Brewfile` | all formulae / casks / taps |
| `install.sh` | symlink + greeting prompt + brew bundle |
| `ghostty-config` | Ghostty terminal config (font, theme, keybinds) |
| `CLAUDE.md` | context for Claude Code when working in this repo |

## Ghostty (terminal)

The tracked `ghostty-config` file is symlinked to `~/.config/ghostty/config`
by `install.sh`. Reload in-app with `Cmd+Shift+,`.

```ini
# Font
font-family = "JetBrainsMono Nerd Font"
font-size = 14

# Theme — Catppuccin ships built-in; name is case- and space-sensitive
theme = Catppuccin Mocha

# Window
window-padding-x = 14
window-padding-y = 12
window-padding-balance = true
background-opacity = 0.96
background-blur = true

# Cursor — steady block (also needs the shell-integration override below)
cursor-style = block
cursor-style-blink = false
shell-integration = detect
shell-integration-features = no-cursor,sudo,title

# UX
scrollback-limit = 10000000
mouse-hide-while-typing = true
copy-on-select = clipboard
confirm-close-surface = false
clipboard-trim-trailing-spaces = true

# macOS
macos-titlebar-style = tabs
macos-option-as-alt = left
quick-terminal-position = top
quick-terminal-autohide = true

# Quick terminal (drop-down, global hotkey)
keybind = global:cmd+grave_accent=toggle_quick_terminal

# Tabs
keybind = cmd+t=new_tab
keybind = cmd+w=close_surface
keybind = cmd+alt+left=previous_tab
keybind = cmd+alt+right=next_tab

# Splits — vim-style hjkl navigation
keybind = cmd+d=new_split:right
keybind = cmd+shift+d=new_split:down
keybind = cmd+alt+h=goto_split:left
keybind = cmd+alt+j=goto_split:down
keybind = cmd+alt+k=goto_split:up
keybind = cmd+alt+l=goto_split:right
keybind = cmd+enter=toggle_split_zoom

keybind = cmd+shift+r=reload_config
```

**What each section does**

- **Font** — `JetBrainsMono Nerd Font` so starship's powerline glyphs
  render correctly. Verify the exact family name with
  `ghostty +list-fonts`.
- **Theme** — Catppuccin Mocha to match `starship.toml`. List all
  built-in themes with `ghostty +list-themes`. Names are case-sensitive
  and space-separated: `Catppuccin Mocha`, not `catppuccin-mocha`.
- **Window** — padding for breathing room; subtle translucency with a
  real blur so the desktop shows through without looking muddy.
- **Cursor** — steady block. Ghostty's shell integration re-enables
  blinking via OSC escapes, so `no-cursor` in
  `shell-integration-features` is required to actually keep it steady.
  Changes to that key need a full Ghostty restart — reload alone won't
  pick it up.
- **UX** — generous scrollback, hide mouse while typing, auto-copy
  selection to the system clipboard, no close confirmation.
- **macOS**
  - `macos-titlebar-style = tabs` — Safari-style native tab bar.
  - `macos-option-as-alt = left` — makes `Alt-b` / `Alt-f` / `Alt-.`
    work in zsh line editing while keeping right-Option free for typing
    special characters (common iTerm → Ghostty migration pain point).
  - `quick-terminal-*` — drop-down "quake"-style terminal triggered by
    `Cmd+`` globally.

**Keybinds**

| Shortcut | Action |
|---|---|
| `Cmd+`` | Toggle quick terminal (works even when Ghostty isn't focused) |
| `Cmd+T` / `Cmd+W` | New tab / close surface |
| `Cmd+Alt+←/→` | Previous / next tab |
| `Cmd+D` / `Cmd+Shift+D` | Split right / split down |
| `Cmd+Alt+H/J/K/L` | Move between splits (vim-style) |
| `Cmd+Return` | Zoom the focused split |
| `Cmd+Shift+R` | Reload config |

**Shell integration** is auto-injected when Ghostty launches zsh as the
login shell — no `zshrc` changes required, no conflict with zinit or
starship.

## Shell greeting

Every interactive shell prints a full-width banner:

```
  ∩___∩     <random quote>
 ( ・ω・)   早安, Sammy 👋
  づ づ     2026/04/17 週五
   ¯¯¯      Taipei 24° (23~29°) 🌧100% 局部多雲
────────────────────────────────────────
```

Config lives in `~/.zshrc.local`:

```sh
export GREET_NAME="Sammy"
export GREET_CITY="Taipei"   # empty = disable weather
export GREET_LANG="zh"       # zh | en
```

**Weather** comes from [wttr.in](https://wttr.in) via `bin/weather`
(current temp + today's min/max + rain probability + condition). Cached
**once per day** in `~/.cache/dotfile/` — first shell of the day
refreshes async so the network never blocks the shell.

**Quotes** come from:

1. `~/.config/dotfile/quotes.txt` — your personal collection (**not**
   tracked by git). Create it freely — one quote per line, `#` starts a
   comment.
2. `quotes.txt` in this repo — English fallback used when the personal
   file doesn't exist.

## Local overrides

`~/.zshrc.local` is sourced at the end of `zshrc`. Put machine-specific
env, secrets, PATH tweaks, work-only aliases, etc. there. It's never
tracked.

## Keeping machines in sync

Pull changes:

```sh
cd ~/.dotfiles && git pull
brew bundle --file=Brewfile --no-upgrade   # if Brewfile changed
```

Push changes:

```sh
cd ~/.dotfiles
# edit files, then:
git add -A && git commit -m "..." && git push
```
