# my-tmux-conf

Personal tmux configuration (Catppuccin Mocha theme, vi copy mode, mouse support and a
system-wide unified clipboard).

## Install

```sh
git clone git@github.com:August-Arana/my-tmux-conf.git ~/.config/my-tmux-conf
ln -s ~/.config/my-tmux-conf/.tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# inside tmux: prefix + I  (install plugins)
```

Dependencies: `xclip` (or, preferably on Wayland, `wl-clipboard`).

> `.tmux.conf` is the active config. `tmux.conf` / `tmux.conf.bak` are older snapshots.

## Keybindings

Prefix: **`Ctrl-a`**

| Key | Action |
|-----|--------|
| `prefix /` / `prefix \|` | Vertical split (`\|` = 40 cols) |
| `prefix -` / `prefix _` | Horizontal split (`_` = 5 rows) |
| `prefix c` | New window in current path |
| `prefix s` | Popup shell in current path |
| `prefix C-p` / `prefix C-n` | Previous / next window |
| `prefix h/j/k/l` | Select pane |
| `prefix H/J/K/L` | Resize pane by 10 |
| `C-h/j/k/l` | Move between panes (passes through to Neovim when focused) |
| `prefix y` | Enter copy mode (scrolling up) |
| `prefix p` | Paste the **system clipboard** |
| `prefix r` | Reload config |

Copy mode (vi): `v` starts the selection, `y` copies and exits.

## Unified clipboard

**One rule everywhere:** anything copied in tmux goes to **both** system selections:

- **CLIPBOARD** → what `Ctrl+V` / `Ctrl+Shift+V` / right-click pastes.
- **PRIMARY** → what middle-click pastes.

The Neovim config ([nvim_config](https://github.com/August-Arana/nvim_config)) follows the same
rule, so tmux, Neovim and the rest of the desktop share a single clipboard.

### Mouse

| Action | Result |
|--------|--------|
| Drag to select | Copies to CLIPBOARD + PRIMARY on release |
| Double / triple click | Copies word / line to CLIPBOARD + PRIMARY |
| Middle click | Pastes system PRIMARY |
| Right click | Pastes system CLIPBOARD (replaces tmux's default menu) |
| Alt + right click | tmux pane menu (split, zoom, swap, kill…) |
| Shift + mouse | Bypasses tmux; Alacritty's native selection |

If the pane runs an app that captures the mouse (e.g. Neovim), middle/right clicks are passed
to that app instead.

### How it works

- `set -s copy-command scripts/clip-copy.sh` — every `copy-pipe*` (keyboard `y`, mouse drag,
  double/triple click) pipes the selection into this script, which writes it to CLIPBOARD and
  PRIMARY.
- `set -g set-clipboard off` — a single copy path; no duplicated OSC52 write to the terminal.
- Pasting (`prefix p`, middle/right click) runs `scripts/clip-paste.sh primary|clipboard`, loads
  the result into a temporary tmux buffer and pastes it with bracketed paste.
- Both scripts use `wl-copy` / `wl-paste` when running on Wayland with `wl-clipboard` installed,
  and fall back to `xclip` otherwise.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/clip-copy.sh` | stdin → system CLIPBOARD + PRIMARY |
| `scripts/clip-paste.sh [clipboard\|primary]` | Prints a system selection |
| `scripts/cpu_usage.sh`, `mem_usage.sh`, `network_speed.sh` | Status bar widgets |
| `scripts/tmux-git-status.sh` | Git branch/status of the active pane |
