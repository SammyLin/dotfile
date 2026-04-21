# CLAUDE.md

Context for Claude Code working in this repo. Read this before changing anything.

## What this repo is

Sammy's personal dotfiles — source of truth for zsh / prompt / installed
packages across multiple Macs. Each machine has `~/.dotfiles` as a clone;
`install.sh` symlinks the tracked files into `$HOME` and runs `brew bundle`.

The repo started in 2012 as a single oh-my-zsh theme (`sammy.zsh-theme`,
since removed from HEAD but still in git history).

## Stack

- **Shell:** zsh (the oh-my-zsh framework is **not** loaded — `~/.oh-my-zsh/`
  may exist on disk as a leftover but nothing sources it)
- **Plugin manager:** [`zinit`](https://github.com/zdharma-continuum/zinit),
  pulling oh-my-zsh plugins via `zinit snippet OMZP::<name>`
- **Zsh plugins (brew):** `zsh-autosuggestions`, `zsh-fast-syntax-highlighting`, `fzf`
- **Prompt:** [`starship`](https://starship.rs) — config in `starship.toml`, Catppuccin palette, minimal-pills style
- **Dir jumping:** `zoxide` (alias `z`)
- **Editor:** `neovim` (aliased as `vi` / `vim`)
- **Package manager:** Homebrew + `Brewfile` (declarative)

## File layout

| File | Role |
|---|---|
| `zshrc` | Interactive shell config — aliases, plugins, prompt wiring, greeting banner |
| `zshenv` | Very early env (cargo) |
| `starship.toml` | Prompt config |
| `Brewfile` | Declarative package list for `brew bundle` |
| `install.sh` | Symlink + `brew bundle` + interactive greeting personalization + cache warm-up |
| `bin/weather` | Helper: fetches wttr.in JSON, outputs single-line weather summary with min/max + rain% |
| `ghostty-config` | Ghostty terminal config — symlinked to `~/.config/ghostty/config` by `install.sh` |
| `quotes.txt` | English fallback quotes (used if `~/.config/dotfile/quotes.txt` missing) |
| `README.md` | Human-facing usage (English) |
| `README.zh-TW.md` | Human-facing usage (Traditional Chinese); keep in sync with `README.md` |
| `CLAUDE.md` | This file |

Machine-local file (**not** in this repo, written by `install.sh`):

- `~/.zshrc.local` — per-machine overrides. Sourced at the end of `zshrc`.
  Holds `GREET_NAME` / `GREET_CITY` / `GREET_LANG`, plus any secrets or
  tweaks the user wants machine-local.

## Rules when modifying

1. **Never hardcode `/Users/<name>/`.** Always use `$HOME`. Past incident:
   one commit had `/Users/sammylin/...` which broke on a machine where the
   user dir was `/Users/sammy/`.
2. **Anything machine-specific or secret → `~/.zshrc.local`**, not tracked
   files. No API keys, tokens, or private paths in `zshrc`/`zshenv`/etc.
3. **`install.sh` must stay idempotent.** Re-running should print `ok` for
   already-correct symlinks and not overwrite anything. Always back up
   before replacing a real file or a wrongly-pointed symlink.
4. **Brewfile edits:** prefer hand edits (alphabetical within the `brew`
   block). `brew bundle dump --file=Brewfile --force` can regenerate but
   drags in cruft — review the diff before committing.
5. **Greeting (`_greet` in `zshrc`):** must not block shell startup.
   Weather is cached **per calendar day** in `~/.cache/dotfile/` — refresh
   happens async in the background. Quotes are picked from
   `~/.config/dotfile/quotes.txt` (personal, untracked) or `quotes.txt`
   (tracked fallback). Don't add synchronous network calls to the greet
   path.
6. **Don't break the symlink contract.** `install.sh` expects each tracked
   filename to map to exactly one `$HOME` destination. If you add a new
   tracked config, add a matching `link` call in `install.sh`.

## Testing a change locally

```sh
cd ~/.dotfiles
# edit files...
./install.sh --no-brew   # fast: just relink, no brew
zsh -i -c 'exit'         # sanity-check zshrc loads without error and prints greeting
exec zsh                 # full reload in-place
```

Full test including brew:

```sh
./install.sh
```

Re-run greeting personalization:

```sh
./install.sh --reconfig
```

## Commit style

Short imperative subject, bullet body explaining the **why** (not just
what — the diff already shows what). Match the tone of recent commits.

## Don't touch without asking

- **Legacy `sammy.zsh-theme`** is gone from HEAD but preserved in history
  (commits pre-2026-04). Don't try to "clean up" old commits — history is
  the continuity.
- The old fork `SammyLin/oh-my-zsh` (framework fork, unrelated to this
  repo) is intentionally kept for nostalgia — do not delete.
