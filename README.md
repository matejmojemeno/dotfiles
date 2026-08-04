# dotfiles

Selected `~/.config` directories: `ghostty`, `tmux`, `zsh`, `nvim` (submodule).

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
