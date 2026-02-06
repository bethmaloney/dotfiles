#!/bin/bash
# Claude Code status line — piped JSON on stdin
# Colors match Catppuccin Mocha palette
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.cwd // empty' | xargs basename 2>/dev/null)
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

BRANCH=$(git -C "$(echo "$input" | jq -r '.cwd // "."')" branch --show-current 2>/dev/null)

# Catppuccin Mocha
DIM='\033[38;2;166;173;200m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
RESET='\033[0m'

# Context color: dim when low, yellow getting full, red when tight
if [ "$PCT" -ge 80 ] 2>/dev/null; then
  PCT_COLOR=$RED
elif [ "$PCT" -ge 50 ] 2>/dev/null; then
  PCT_COLOR=$YELLOW
else
  PCT_COLOR=$DIM
fi

SEP="${DIM} | ${RESET}"

parts=""
[ -n "$DIR" ] && parts="${DIM}${DIR}${RESET}"
[ -n "$BRANCH" ] && parts="${parts}${SEP}${DIM}${BRANCH}${RESET}"
parts="${parts}${SEP}${DIM}${MODEL}${RESET}"
parts="${parts}${SEP}${PCT_COLOR}${PCT}%${RESET}${DIM} context${RESET}"

echo -e "$parts"
