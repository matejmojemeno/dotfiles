#!/usr/bin/env bash
# Claude Code status line:
#   dir  branch │ model │ ctx bar │ 5h plan usage │ session cost
input=$(cat)

vals=$(printf '%s' "$input" | jq -r '
  (.workspace.current_dir // .cwd // ""),
  (.model.display_name // "?"),
  (.context_window.total_input_tokens // 0),
  (.context_window.context_window_size // 0),
  (.rate_limits.five_hour.used_percentage // -1 | floor),
  (.rate_limits.five_hour.resets_at // ""),
  (.cost.total_cost_usd // 0)')
dir=$(sed -n 1p <<<"$vals")
model=$(sed -n 2p <<<"$vals")
used=$(sed -n 3p <<<"$vals")
total=$(sed -n 4p <<<"$vals")
h5_pct=$(sed -n 5p <<<"$vals")
h5_reset=$(sed -n 6p <<<"$vals")
cost=$(sed -n 7p <<<"$vals")

# Context-usage thresholds, in tokens (override via env if you like).
CTX_YELLOW=${CTX_YELLOW:-150000}
CTX_RED=${CTX_RED:-400000}

RST=$'\033[0m'
DIM=$'\033[38;5;243m'
DIR=$'\033[1;38;5;75m'    # bright blue, bold
BR=$'\033[38;5;176m'      # soft mauve
SEP="${DIM}│${RST}"

pct_color() {  # $1 = percent
  if   [ "$1" -ge 90 ]; then printf '\033[38;5;203m'   # red
  elif [ "$1" -ge 75 ]; then printf '\033[38;5;215m'   # orange
  elif [ "$1" -ge 50 ]; then printf '\033[38;5;179m'   # amber
  else                       printf '\033[38;5;114m'   # green
  fi
}

# Context color: absolute token thresholds, with a percentage backstop so a
# small window still turns red as it fills.
ctx_color() {  # $1 = used tokens, $2 = percent of window
  if   [ "$1" -ge "$CTX_RED" ]    || [ "$2" -ge 90 ]; then printf '\033[38;5;203m'  # red
  elif [ "$1" -ge "$CTX_YELLOW" ] || [ "$2" -ge 75 ]; then printf '\033[38;5;179m'  # yellow
  else                                                     printf '\033[38;5;114m'  # green
  fi
}

# Smooth 12-cell bar using eighth-blocks, wrapped in thin brackets.
bar() {  # $1 = percent
  local pct=$1 cells=12 eighths full part i out=""
  eighths=$(( pct * cells * 8 / 100 ))
  [ "$eighths" -gt $(( cells * 8 )) ] && eighths=$(( cells * 8 ))
  full=$(( eighths / 8 )); part=$(( eighths % 8 ))
  local parts=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
  for ((i=0;i<full;i++)); do out+="█"; done
  if [ "$part" -gt 0 ] && [ "$full" -lt "$cells" ]; then
    out+="${parts[$part]}"; full=$(( full + 1 ))
  fi
  for ((i=full;i<cells;i++)); do out+="·"; done
  printf '%s' "$out"
}

# Clock face reflecting how full the window is.
clock_glyph() {
  if   [ "$1" -ge 88 ]; then printf '●'
  elif [ "$1" -ge 62 ]; then printf '◕'
  elif [ "$1" -ge 38 ]; then printf '◑'
  elif [ "$1" -ge 12 ]; then printf '◔'
  else                       printf '○'
  fi
}

# Time until reset, from an ISO-8601 string or epoch seconds.
until_reset() {
  local at="$1" now epoch mins
  [ -z "$at" ] && return
  if [[ "$at" =~ ^[0-9]+$ ]]; then
    epoch="$at"
  else
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${at%%.*}" +%s 2>/dev/null) || \
    epoch=$(date -d "$at" +%s 2>/dev/null) || return
  fi
  now=$(date +%s)
  mins=$(( (epoch - now) / 60 ))
  [ "$mins" -lt 0 ] && return
  if [ "$mins" -ge 60 ]; then printf '%dh%02dm' $(( mins / 60 )) $(( mins % 60 ))
  else                        printf '%dm' "$mins"
  fi
}

dir_short="${dir/#$HOME/~}"
dir_short="${dir_short##*/}"

branch=""
if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
fi

# --- context window ---
ctx="${DIM}ctx —${RST}"
if [ "$total" -gt 0 ] 2>/dev/null; then
  pct=$(( used * 100 / total ))
  c=$(ctx_color "$used" "$pct")
  ctx=$(printf "%bctx%b %b▏%s▕%b %b%3d%%%b %b%dk/%dk%b" \
    "$DIM" "$RST" "$c" "$(bar "$pct")" "$RST" \
    "$c" "$pct" "$RST" \
    "$DIM" $(( used / 1000 )) $(( total / 1000 )) "$RST")
fi

# --- 5-hour plan usage ---
usage=""
if [ "$h5_pct" -ge 0 ] 2>/dev/null; then
  c=$(pct_color "$h5_pct")
  usage=$(printf "%b%s 5h %d%%%b" "$c" "$(clock_glyph "$h5_pct")" "$h5_pct" "$RST")
  r=$(until_reset "$h5_reset")
  [ -n "$r" ] && usage+=$(printf "%b ↻ %s%b" "$DIM" "$r" "$RST")
fi

# --- session cost ---
cost_str=""
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  cost_str=$(printf "%b\$%.2f%b" "$DIM" "$cost" "$RST")
fi

out="${DIR}${dir_short}${RST}"
[ -n "$branch" ]   && out+=" ${BR}⎇ ${branch}${RST}"
out+="  ${SEP}  ${DIM}${model}${RST}  ${SEP}  ${ctx}"
[ -n "$usage" ]    && out+="  ${SEP}  ${usage}"
[ -n "$cost_str" ] && out+="  ${SEP}  ${cost_str}"
printf '%s' "$out"
