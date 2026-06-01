#!/usr/bin/env bash
# song-position.sh — current playback position as m:ss

POS=$(playerctl position 2>/dev/null)
if [[ -z "$POS" ]]; then echo "0:00"; exit 0; fi

POS_INT=${POS%.*}
MIN=$((POS_INT / 60))
SEC=$((POS_INT % 60))
printf "%d:%02d" "$MIN" "$SEC"
