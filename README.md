# dotfile

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
| `CLAUDE.md` | context for Claude Code when working in this repo |

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
