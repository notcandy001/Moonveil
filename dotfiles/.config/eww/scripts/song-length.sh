#!/usr/bin/env bash
# song-length.sh — total track length as m:ss

LEN=$(playerctl metadata mpris:length 2>/dev/null)
if [[ -z "$LEN" ]]; then echo "0:00"; exit 0; fi

# mpris:length is in microseconds
LEN_SEC=$((LEN / 1000000))
MIN=$((LEN_SEC / 60))
SEC=$((LEN_SEC % 60))
printf "%d:%02d" "$MIN" "$SEC"
