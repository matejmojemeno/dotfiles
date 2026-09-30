# dotfiles

Selected `~/.config` directories: `ghostty`, `tmux`, `zsh`, `karabiner`,
`claude`, `nvim` (submodule).

`.gitignore` denies everything by default and un-ignores only those paths —
`~/.config` also holds credentials (`gcloud`, `gh`, `github-copilot`), which
must never be committed. Add new configs by un-ignoring them explicitly.

## Setup on a new machine

`~/.config` already exists there, so fetch into it rather than cloning over it:

```bash
cd ~/.config
git init -b main
git remote add origin git@github.com:matejmojemeno/dotfiles.git
git fetch origin

# Take only what this machine needs:
git sparse-checkout init --cone
git sparse-checkout set ghostty tmux        # add zsh / nvim as wanted
git checkout main

git submodule update --init --recursive     # only if nvim was checked out
```

Later: `git sparse-checkout add nvim`.

Untracked directories already in `~/.config` are never touched by this.

## zsh bootstrap

zsh only finds `~/.config/zsh/.zshrc` if `ZDOTDIR` points at it. On this
machine that is set in `/etc/zshenv`, which is outside the repo — so on a new
machine, do:

```bash
echo 'export ZDOTDIR=$HOME/.config/zsh' >> ~/.zshenv
```

Plugins are managed by zinit, which self-installs on first shell start.

## Karabiner bootstrap

`karabiner/karabiner.json` is self-contained (caps lock → ctrl/esc, fn+f6 →
f16), but the file alone does nothing until the app is installed and granted
permissions:

```bash
brew install --cask karabiner-elements
```

1. Launch it once and grant **Input Monitoring** and **Accessibility** to
   `karabiner_grabber` and `karabiner_observer` (System Settings → Privacy &
   Security), and approve the **driver extension** under Login Items &
   Extensions → Driver Extensions. macOS requires a reboot for the driver.
2. **Quit Karabiner-Elements**, then check out `karabiner/karabiner.json`
   (a running Karabiner rewrites the file and would clobber it).
3. Relaunch. Verify the profile shows as "Default profile" and selected.

If the other machine has an ISO/JIS keyboard, change
`virtual_hid_keyboard.keyboard_type_v2` from `ansi`.

## Claude Code bootstrap

Claude Code reads its user settings from `~/.claude`, not `~/.config`, so link
the tracked files in:

```bash
mkdir -p ~/.claude
ln -s ~/.config/claude/settings.json ~/.claude/settings.json
ln -s ~/.config/claude/statusline.sh ~/.claude/statusline.sh
```

The status line needs `jq`. Only shareable preferences live here — keep
machine-specific hooks, permissions and auto-mode environment out of the
tracked `settings.json` (use `~/.claude/settings.local.json`-style local files
or edit `~/.claude/settings.json` directly on that machine instead of linking).

## Machine-local overrides

Both terminal configs load an optional, gitignored file last, so per-machine
values override the committed ones:

| Committed | Local override |
| --- | --- |
| `ghostty/config` | `ghostty/config.local` |
| `tmux/tmux.conf` | `tmux/tmux.local.conf` |

Things that usually belong there: `font-size`, and Ghostty's
`command = <path>/tmux new-session` (the committed path is Apple Silicon
Homebrew, `/opt/homebrew/bin/tmux`).

## Requirements

`tmux`, `neovim`, `ghostty`. Ghostty and neovim navigation are seamless via
`smart-splits.nvim` + the `@pane-is-vim` bindings in `tmux/tmux.conf`.
