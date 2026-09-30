#!/bin/sh
# ~/.config/tmux/ghostty-session.sh
#
# Ghostty's `command` — see ~/.config/ghostty/config.
#
# The workspace slots live in one long-lived session ($BASE, default "main")
# holding SLOTS generic full-screen windows numbered 1..SLOTS. It is created on
# first launch and then reused: quitting Ghostty only detaches, so nvim/claude/
# shells in the slots keep running and are right where you left them next time.
# (The tmux server is a daemon independent of Ghostty; it dies on reboot or
# `tmux kill-server`.)
#
# Each Ghostty window attaches through its own *grouped* session, which shares
# the slot windows but tracks its own current window — so two Ghostty windows
# can sit on different slots instead of mirroring each other. Those throwaway
# view sessions are pruned here on launch.
set -eu

tmux=${TMUX_BIN:-/opt/homebrew/bin/tmux}
[ -x "$tmux" ] || tmux=$(command -v tmux)

BASE=${TMUX_BASE_SESSION:-main}
SLOTS=${TMUX_SLOTS:-6}

# 1. the persistent session, with every slot present
"$tmux" has-session -t "=$BASE" 2>/dev/null || "$tmux" new-session -d -s "$BASE" -n 1
i=1
while [ "$i" -le "$SLOTS" ]; do
  "$tmux" list-windows -t "=$BASE" -F '#{window_index}' | grep -qx -- "$i" ||
    "$tmux" new-window -d -t "$BASE:$i" -n "$i"
  i=$((i + 1))
done

# 2. drop view sessions left behind by Ghostty windows that are gone
"$tmux" list-sessions -F '#{session_name} #{session_attached} #{session_group}' |
  while read -r name attached group; do
    if [ "$name" != "$BASE" ] && [ "$group" = "$BASE" ] && [ "$attached" = "0" ]; then
      "$tmux" kill-session -t "=$name" || true
    fi
  done

# 3. this Ghostty window's private view of the shared slots
view="$BASE-$$"
"$tmux" new-session -d -t "=$BASE" -s "$view"
exec "$tmux" attach-session -t "=$view"
