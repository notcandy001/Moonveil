#!/usr/bin/env bash
# cava-read.sh — read one line from cava FIFO and output as block chars

FIFO="${XDG_RUNTIME_DIR:-/tmp}/cava-eww.fifo"

if [[ ! -p "$FIFO" ]]; then
  echo "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
  exit 0
fi

# Read one snapshot line from fifo (non-blocking)
LINE=$(timeout 0.1 head -n1 "$FIFO" 2>/dev/null)

if [[ -z "$LINE" ]]; then
  echo "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
  exit 0
fi

# Convert semicolon-separated values to block chars
BARS=""
IFS=';' read -ra VALS <<< "$LINE"
CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
for VAL in "${VALS[@]}"; do
  if [[ -n "$VAL" && "$VAL" -ge 0 ]] 2>/dev/null; then
    IDX=$((VAL * 7 / 1000))
    [[ $IDX -gt 7 ]] && IDX=7
    [[ $IDX -lt 0 ]] && IDX=0
    BARS+="${CHARS[$IDX]}"
  fi
done

echo "$BARS"
