#!/bin/sh
# ~/.config/tmux/goto-window.sh <index>
#
# "Fixed workspace slot" helper for the alt+<number> bindings in tmux.conf.
# Selects window <index> in the current session; if that slot is empty (you
# closed it), recreates a plain shell there so the numbering never drifts.
# Called via run-shell, so tmux points #{pane_current_path} at the caller.
#
# Absolute tmux path: run-shell inherits the tmux *server's* environment, which
# for a GUI-launched Ghostty may not include /opt/homebrew/bin.
set -eu

tmux=${TMUX_BIN:-/opt/homebrew/bin/tmux}
[ -x "$tmux" ] || tmux=$(command -v tmux)

idx=$1

if "$tmux" list-windows -F '#{window_index}' | grep -qx -- "$idx"; then
  "$tmux" select-window -t ":$idx"
else
  "$tmux" new-window -t ":$idx" -n "$idx" -c "$("$tmux" display-message -p '#{pane_current_path}')"
fi
