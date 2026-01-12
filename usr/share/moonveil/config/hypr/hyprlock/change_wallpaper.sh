#!/bin/bash

# Only works if you use SWWW for your wallpapers

SWWW_DIR="$HOME/.cache/swww/"
HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"

# Get a Monitor Cache File
FIRST_FILE=$(find "$SWWW_DIR" -type f | head -n 1)

# Check if SWWW file exists
if [ -n "$FIRST_FILE" ] && [ -f "$FIRST_FILE" ]; then
    WALLPAPER=$(sed -n '2p' "$FIRST_FILE")

    sed -i "s|^\(\$wallpaper[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER # (screenshot or /path/to/your/wallpaper.jpg)|" "$HYPRLOCK"
    echo "Wallpaper path updated to $WALLPAPER"
    exit 0
fi

# Error
echo "Fehler: kein Wallpaper gefunden."
exit 1
