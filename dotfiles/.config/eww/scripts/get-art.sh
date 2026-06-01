#!/usr/bin/env bash
# get-art.sh — fetch album art URL/path from playerctl, cache locally

ART_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eww-art"
mkdir -p "$ART_DIR"

URL=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [[ -z "$URL" ]]; then
  echo "$HOME/.config/eww/assets/default-art.png"
  exit 0
fi

# Strip file:// prefix if local
if [[ "$URL" == file://* ]]; then
  echo "${URL#file://}"
  exit 0
fi

# Hash URL to get a stable cache filename
HASH=$(echo "$URL" | sha256sum | cut -c1-16)
CACHED="$ART_DIR/$HASH.png"

if [[ ! -f "$CACHED" ]]; then
  curl -s -o "$CACHED" "$URL" || {
    echo "$HOME/.config/eww/assets/default-art.png"
    exit 0
  }
fi

echo "$CACHED"
