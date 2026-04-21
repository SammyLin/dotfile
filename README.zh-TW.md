# dotfile

*[Read this in English](README.md)*

Sammy 的個人 dotfiles——一個 repo，多台 Mac。

起源於 2012 年的一個 oh-my-zsh theme；現在是完整的 zsh + zinit +
starship + brew bundle 設定。原本的 theme 還留在 git history 裡。

## 新機器初始化

```sh
git clone git@github.com:SammyLin/dotfile.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` 會做這些事：

1. 把 `zshrc` / `zshenv` / `starship.toml` symlink 到 `$HOME`
   （原本存在的檔案會先備份成 `*.backup.<timestamp>`；如果 symlink
   已經指到對的地方，就印 `ok` 然後什麼都不做）。
2. 問你 greeting 的個人化設定，寫到 `~/.zshrc.local`
   （**不會** tracked——machine-local）。
3. 跑 `brew bundle --no-upgrade` 裝 `Brewfile` 裡的所有東西。

Flags:

- `--no-brew` 跳過第 3 步（快速重新 link / 重新設定）
- `--reconfig` 把 `~/.zshrc.local` 裡的 `GREET_*` 區塊清掉重問

## 檔案配置

| 檔案 | 用途 |
|---|---|
| `zshrc` | 主 shell 設定——aliases、plugins、starship、zinit、greeting |
| `zshenv` | 早期 env（cargo） |
| `starship.toml` | prompt 設定（Catppuccin、minimal-pills） |
| `Brewfile` | 所有 formulae / casks / taps |
| `install.sh` | symlink + greeting 個人化 + brew bundle |
| `CLAUDE.md` | 給 Claude Code 在這個 repo 工作時用的 context |

## Ghostty（終端機）

建議的設定檔放在 `~/.config/ghostty/config`。在 app 裡用 `Cmd+Shift+,`
重新載入。

```ini
# Font
font-family = "JetBrainsMono Nerd Font"
font-size = 14

# Theme — Catppuccin 是內建主題，名稱有大小寫和空格之分
theme = Catppuccin Mocha

# Window
window-padding-x = 14
window-padding-y = 12
window-padding-balance = true
background-opacity = 0.96
background-blur = true

# Cursor — 穩定方塊游標（還需要下面的 shell-integration 覆寫才會真的不閃）
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

# 快速終端機（下拉式，全域快捷鍵）
keybind = global:cmd+grave_accent=toggle_quick_terminal

# Tabs
keybind = cmd+t=new_tab
keybind = cmd+w=close_surface
keybind = cmd+alt+left=previous_tab
keybind = cmd+alt+right=next_tab

# Splits — vim 風 hjkl 移動
keybind = cmd+d=new_split:right
keybind = cmd+shift+d=new_split:down
keybind = cmd+alt+h=goto_split:left
keybind = cmd+alt+j=goto_split:down
keybind = cmd+alt+k=goto_split:up
keybind = cmd+alt+l=goto_split:right
keybind = cmd+enter=toggle_split_zoom

keybind = cmd+shift+r=reload_config
```

**各區段在做什麼**

- **Font（字型）** — `JetBrainsMono Nerd Font` 讓 starship 的
  powerline 圖示能正確顯示。用 `ghostty +list-fonts` 驗證實際的
  字型名稱。
- **Theme（主題）** — Catppuccin Mocha 跟 `starship.toml` 對齊。用
  `ghostty +list-themes` 列出所有內建主題。名稱有大小寫和空格之分：
  是 `Catppuccin Mocha`，不是 `catppuccin-mocha`。
- **Window（視窗）** — 邊距讓文字有呼吸空間；微透明搭配真模糊，
  讓桌面若隱若現但又不會糊成一團。
- **Cursor（游標）** — 穩定方塊游標。Ghostty 的 shell integration
  會透過 OSC escape 把閃爍重新打開，所以**一定要**同時在
  `shell-integration-features` 加 `no-cursor` 才會真的不閃。這個
  欄位改了要完全重啟 Ghostty，reload 抓不到。
- **UX** — 大容量 scrollback、打字時自動隱藏滑鼠、選取文字自動
  複製到系統剪貼簿、關閉視窗不要再跳確認。
- **macOS**
  - `macos-titlebar-style = tabs` — Safari 風格的原生 tab bar。
  - `macos-option-as-alt = left` — 讓 `Alt-b`/`Alt-f`/`Alt-.` 在
    zsh line editor 能動，同時右 Option 還能打特殊字元
    （iTerm 轉 Ghostty 最常踩的雷）。
  - `quick-terminal-*` — 下拉式「quake 風」終端機，系統全域用
    `Cmd+`` 呼叫。

**快捷鍵**

| 快捷鍵 | 作用 |
|---|---|
| `Cmd+`` | 切換快速終端機（Ghostty 沒焦點也能叫出來） |
| `Cmd+T` / `Cmd+W` | 新 tab / 關閉當前視窗 |
| `Cmd+Alt+←/→` | 上一個 / 下一個 tab |
| `Cmd+D` / `Cmd+Shift+D` | 向右切 split / 向下切 split |
| `Cmd+Alt+H/J/K/L` | split 間移動（vim 風） |
| `Cmd+Return` | 放大當前 split |
| `Cmd+Shift+R` | 重新載入設定 |

**Shell integration** 在 Ghostty 直接啟動 zsh 當 login shell 時會
自動注入——`zshrc` 不用改，也不會跟 zinit / starship 衝突。

## Shell greeting

每次開互動式 shell 都會印一個滿版的 banner：

```
  ∩___∩     <隨機 quote>
 ( ・ω・)   早安, Sammy 👋
  づ づ     2026/04/17 週五
   ¯¯¯      Taipei 24° (23~29°) 🌧100% 局部多雲
────────────────────────────────────────
```

設定在 `~/.zshrc.local`：

```sh
export GREET_NAME="Sammy"
export GREET_CITY="Taipei"   # 空字串 = 關閉天氣
export GREET_LANG="zh"       # zh | en
```

**天氣**來自 [wttr.in](https://wttr.in)，透過 `bin/weather` 抓
（當下溫度 + 今日最低/最高 + 降雨機率 + 天氣狀況）。**一天快取一次**
在 `~/.cache/dotfile/`——一天第一次開 shell 時在背景非同步刷新，
網路不會卡到 shell 啟動。

**Quotes（語錄）**來源順序：

1. `~/.config/dotfile/quotes.txt`——你的個人收藏（**不會** tracked）。
   隨意建立——一行一句，`#` 開頭是註解。
2. repo 裡的 `quotes.txt`——沒有個人檔案時使用的英文 fallback。

## 本機覆寫

`~/.zshrc.local` 在 `zshrc` 最後被 source 進來。本機專用 env、
密鑰、PATH 調整、工作用 aliases 等等都放這裡。不會被 tracked。

## 多台機器同步

拉最新變更：

```sh
cd ~/.dotfiles && git pull
brew bundle --file=Brewfile --no-upgrade   # 如果 Brewfile 有改
```

推變更：

```sh
cd ~/.dotfiles
# 編輯檔案，然後:
git add -A && git commit -m "..." && git push
```
