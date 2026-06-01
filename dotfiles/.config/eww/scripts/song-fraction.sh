#!/usr/bin/env bash
# song-fraction.sh — playback progress 0-100 for eww scale

POS=$(playerctl position 2>/dev/null)
LEN=$(playerctl metadata mpris:length 2>/dev/null)

if [[ -z "$POS" || -z "$LEN" || "$LEN" == "0" ]]; then echo "0"; exit 0; fi

LEN_SEC=$(echo "scale=3; $LEN / 1000000" | bc)
FRAC=$(echo "scale=2; ($POS / $LEN_SEC) * 100" | bc)
echo "${FRAC%.*}"
