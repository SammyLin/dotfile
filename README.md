# sammy-dotfile

My personal dotfiles. Started life in 2012 as an oh-my-zsh theme (`sammy.zsh-theme`),
now grown into a full setup with zinit + starship + brew bundle.

## Setup on a new machine

```sh
git clone git@github.com:SammyLin/sammy-dotfile.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` will:
- symlink `zshrc` → `~/.zshrc`
- symlink `zshenv` → `~/.zshenv`
- symlink `starship.toml` → `~/.config/starship.toml`
- run `brew bundle` to install everything in `Brewfile`

Existing files get backed up to `*.backup.<timestamp>` before linking.

## Layout

| File | Purpose |
| --- | --- |
| `zshrc` | main shell config — aliases, plugins, starship, zinit |
| `zshenv` | early env (cargo, etc.) |
| `starship.toml` | prompt config (Catppuccin palette, minimal pills) |
| `Brewfile` | all brew formulae / casks / taps |
| `install.sh` | symlink + brew bundle bootstrap |
| `sammy.zsh-theme` | legacy oh-my-zsh theme (kept for nostalgia) |

## Local overrides

`zshrc` sources `~/.zshrc.local` at the end if it exists — put machine-specific
secrets or tweaks there. It is **not** tracked.

## Keeping machines in sync

Each machine has `~/.dotfiles` as a clone of this repo. To sync:

```sh
cd ~/.dotfiles && git pull
# if Brewfile changed:
brew bundle --file=Brewfile
```

To push a change from any machine:

```sh
cd ~/.dotfiles
# edit files, then:
git add -A && git commit -m "..." && git push
```

## Legacy usage (oh-my-zsh theme only)

The original `sammy.zsh-theme` still works if you want just the theme:

```sh
ln -s ~/.dotfiles/sammy.zsh-theme ~/.oh-my-zsh/themes/sammy-lin.zsh-theme
# then set ZSH_THEME="sammy-lin" in ~/.zshrc
```
