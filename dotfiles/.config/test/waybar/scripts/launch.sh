#!/usr/bin/env bash

STATE="$HOME/.cache/waybar-current"
WAYBAR="$HOME/.config/waybar"

# Fallback if no state yet
if [[ ! -f "$STATE" ]]; then
  CFG="$WAYBAR/config.jsonc"
  CSS="$WAYBAR/style.css"
else
  IFS="|" read -r CFG CSS < "$STATE"
fi

pkill -x waybar
sleep 0.4
waybar -c "$CFG" -s "$CSS" &
pkill -x swaync 
swaync &