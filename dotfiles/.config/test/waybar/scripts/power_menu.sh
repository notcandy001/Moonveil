#!/usr/bin/env bash
# Waybar Power Menu — Hyprland + hyprlock + rofi
# Prompt is a single icon: ⏻

set -euo pipefail

# Icons
ICON_SUSPEND="⏾"
ICON_REBOOT=""
ICON_SHUTDOWN=""
ICON_LOGOUT=""

# Rofi command with JetBrainsMono Nerd Font Propo
ROFI_CMD="rofi -dmenu -p '⏻' -lines 4 \
  -theme-str 'window { font: \"JetBrainsMono Nerd Font Propo 12\"; } \
               listview { columns: 1; } \
               element { font: \"JetBrainsMono Nerd Font Propo 12\"; }'"

notify() {
  command -v notify-send >/dev/null && notify-send "Power" "$1"
}

rofi_menu() {
  printf "%s\n" "$1" | eval $ROFI_CMD
}

rofi_confirm() {
  printf "Yes\nNo\n" | rofi -dmenu -p "⏻ Confirm" -lines 2 \
  -theme-str 'window { font: "JetBrainsMono Nerd Font Propo 12"; } element { font: "JetBrainsMono Nerd Font Propo 12"; }'
}

# ---- Actions ----

do_suspend() {
  if command -v hyprlock >/dev/null; then
    hyprlock &
    sleep 0.25
  elif command -v swaylock >/dev/null; then
    swaylock -f &
    sleep 0.25
  fi
  systemctl suspend
}

do_reboot() {
  notify "Rebooting…"
  systemctl reboot
}

do_shutdown() {
  notify "Shutting down…"
  systemctl poweroff
}

do_logout() {
  if command -v hyprctl >/dev/null; then
    hyprctl dispatch exit || true
    return
  fi

  if command -v swaymsg >/dev/null; then
    swaymsg exit || true
    return
  fi

  notify "Logout not supported."
}

# ---- Menu (NO CANCEL) ----

CHOICES="$ICON_SUSPEND  Suspend
$ICON_REBOOT   Reboot
$ICON_SHUTDOWN Shutdown
$ICON_LOGOUT   Logout"

CHOICE=$(rofi_menu "$CHOICES" | tr -d '\r')

case "${CHOICE,,}" in
  *suspend*)  [[ $(rofi_confirm) == "Yes" ]] && do_suspend ;;
  *reboot*)   [[ $(rofi_confirm) == "Yes" ]] && do_reboot ;;
  *shutdown*) [[ $(rofi_confirm) == "Yes" ]] && do_shutdown ;;
  *logout*)   [[ $(rofi_confirm) == "Yes" ]] && do_logout ;;
  *) exit 0 ;;
esac
