# herdr + Ghostty keys

Open this popup any time: **cmd+shift+/** (or `ctrl+b` then `K`).
herdr's own generated list: **cmd+/** (or `ctrl+b` then `?`).

The mental model nests four levels: **session → workspace → tab → pane**.

## Agent states

The sidebar dot, plus the word next to it. Icons are hardcoded in herdr; the
word comes from the `state_text` token.

| Dot | Word | Means |
|---|---|---|
| 🔴 red | blocked | **waiting on you** — approve, answer, confirm |
| 🟡 yellow | working | actively processing |
| 🔵 teal | done | finished, you haven't looked yet |
| 🟢 green | idle | finished and seen |
| ⚪ gray | unknown | herdr can't tell |

Sound: one UI click for every state change, when the agent is in a
*background* workspace. Which state it was is on the dot, not in the sound.

`agent_panel_sort = "priority"` floats whatever needs you to the top of the
sidebar, so red is always the first thing on screen.

## Tabs

| Key | Does | Raw |
|---|---|---|
| cmd+t | new tab | `ctrl+b c` |
| cmd+shift+w | close tab | `ctrl+b X` |
| cmd+shift+t | rename tab | `ctrl+b T` |
| cmd+alt+← / → | previous / next tab | `ctrl+b p` / `n` |
| cmd+1..9 | jump to tab N | `ctrl+b 1..9` |

## Workspaces

| Key | Does | Raw |
|---|---|---|
| cmd+n | new workspace | `ctrl+b N` |
| cmd+shift+n | rename workspace | `ctrl+b W` |
| cmd+p | workspace picker | `ctrl+b w` |
| cmd+alt+↑ / ↓ | previous / next workspace | `ctrl+b ↑` / `↓` |
| cmd+shift+1..5 | jump to workspace N | `ctrl+b !@#$%` |
| — | jump palette (any space/tab/pane) | `ctrl+b g` |
| — | close workspace | `ctrl+b D` |

## Worktrees

The `worktrunk` plugin, not herdr's built-in worktree action — the picker also
lists existing worktrees and runs worktrunk's create/remove hooks, so `ctrl+b G`
replaces the native `new_worktree` on the same key.

| Key | Does | Raw |
|---|---|---|
| — | picker: switch, or create off the default branch | `ctrl+b G` |
| — | same, but new branches fork from the current one | `ctrl+b alt+g` |
| — | pick a worktree to remove | `ctrl+b alt+x` |

Needs the `wt` CLI (`brew install worktrunk`). The plugin lives outside this
repo — a fresh machine needs
`herdr plugin install devashish2203/herdr-worktrunk --yes`.

## Panes

| Key | Does | Raw |
|---|---|---|
| cmd+d | split vertical | `ctrl+b v` |
| cmd+shift+d | split horizontal | `ctrl+b -` |
| cmd+w | close pane | `ctrl+b x` |
| cmd+enter | zoom pane | `ctrl+b z` |
| cmd+alt+h/j/k/l | focus pane left/down/up/right | `ctrl+b h/j/k/l` |
| cmd+alt+r | resize mode | `ctrl+b r` |
| — | cycle panes | `ctrl+b tab` |
| — | edit scrollback in $EDITOR | `ctrl+b e` |

## Session

| Key | Does | Raw |
|---|---|---|
| cmd+/ | herdr's own keybind help | `ctrl+b ?` |
| cmd+shift+/ | this cheatsheet | `ctrl+b K` |
| cmd+, | herdr settings | `ctrl+b s` |
| cmd+b | toggle sidebar | `ctrl+b b` |
| cmd+shift+q | detach (session keeps running) | `ctrl+b q` |
| — | goto / jump palette | `ctrl+b g` |

## Real Ghostty, not herdr

cmd+t/w/d belong to herdr now. Ghostty's own are:

| Key | Does |
|---|---|
| ctrl+cmd+t | Ghostty tab |
| ctrl+cmd+w | close Ghostty surface |
| ctrl+cmd+d | Ghostty split |
| cmd+alt+` | quick terminal (drop-down) |
| cmd+shift+, | reload Ghostty config |

## CLI

```
herdr                        attach / start
herdr --remote <host>        attach over ssh
herdr server reload-config   apply config.toml without restarting
herdr --default-config       print every option with its default
ghostty +list-keybinds       every Ghostty binding, after overrides
```

## Files

- `~/.config/herdr/config.toml`
- `~/.dotfiles/ghostty-herdr.conf` — the cmd+* → `\x02*` routing
- `~/.dotfiles/ghostty-config` — comment out its last `config-file` line to
  hand cmd+t/w/d back to Ghostty
