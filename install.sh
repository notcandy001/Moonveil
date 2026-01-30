#!/bin/bash

set -e
set -u
set -o pipefail

# -----------------------------
# Repo URLs
# -----------------------------

MOONVEIL_REPO="https://github.com/notcandy001/moonveil.git"
MOONSHELL_REPO="https://github.com/notcandy001/moonshell.git"

MOONVEIL_DIR="$HOME/.config/"
MOONSHELL_DIR="$HOME/.config/moonshell"

# -----------------------------
# Unified Dependency List
# (pacman + AUR together)
# -----------------------------

PACKAGES=(
  # Core
  hyprland
  waybar
  rofi
  hyprlock
  wlogout
  swaync

  # System
  gnome-bluetooth-3.0
  vte3
  imagemagick
  power-profiles-daemon
  upower
  networkmanager
  network-manager-applet
  nm-connection-editor

  # Utilities
  grim
  slurp
  nautilus
  pavucontrol
  wl-clipboard
  libnotify

  # Shell
  zsh
  oh-my-zsh-git
  zsh-theme-powerlevel10k
  eza

  # Python / Fabric
  python
  python-gobject
  python-psutil
  python-watchdog
  python-pillow
  python-toml
  python-ijson
  python-numpy
  python-requests
  python-setproctitle
  python-fabric-git
  fabric-cli

  # Theming
  matugen-bin
  adw-gtk-theme
  lxappearance
  bibata-cursor-theme

  # Fonts
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  otf-geist-mono
  ttf-geist-mono-nerd
)

# -----------------------------
# Safety Check
# -----------------------------

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run this script as root."
  exit 1
fi

# -----------------------------
# AUR Helper Detection
# -----------------------------

aur_helper="yay"

if command -v paru &>/dev/null; then
  aur_helper="paru"
elif ! command -v yay &>/dev/null; then
  echo "Installing yay-bin..."
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# -----------------------------
# Install Dependencies
# -----------------------------

echo "Installing dependencies..."
$aur_helper -Syy --needed --noconfirm "${PACKAGES[@]}" || true

# -----------------------------
# Clone / Update Moonveil
# -----------------------------

if [ -d "$MOONVEIL_DIR" ]; then
  echo "Updating Moonveil..."
  git -C "$MOONVEIL_DIR" pull
else
  echo "Cloning Moonveil..."
  git clone --depth=1 "$MOONVEIL_REPO" "$MOONVEIL_DIR"
fi

# -----------------------------
# Clone / Update Moonshell
# -----------------------------

if [ -d "$MOONSHELL_DIR" ]; then
  echo "Updating Moonshell..."
  git -C "$MOONSHELL_DIR" pull
else
  echo "Cloning Moonshell..."
  git clone --depth=1 "$MOONSHELL_REPO" "$MOONSHELL_DIR"
fi

# -----------------------------
# Network Services
# -----------------------------

if systemctl is-enabled --quiet iwd 2>/dev/null; then
  sudo systemctl disable --now iwd
fi

sudo systemctl enable NetworkManager --now

# -----------------------------
# Final Message
# -----------------------------

echo
echo "✅ Moonveil installed."
echo "ℹ️ Moonshell installed as support component."
echo "⚠️ No bar or shell has been auto-started."
echo "👉 Configure and launch manually from Hyprland."
echo
