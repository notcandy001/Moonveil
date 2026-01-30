#!/bin/bash

set -e
set -u
set -o pipefail

# --------------------------------------------------
# Repositories
# --------------------------------------------------

MOONVEIL_REPO="https://github.com/notcandy001/moonveil.git"
MOONSHELL_REPO="https://github.com/notcandy001/moonshell.git"

MOONVEIL_DIR="$HOME/moonveil"
MOONSHELL_DIR="$HOME/.config/moonshell"

# --------------------------------------------------
# Packages
# --------------------------------------------------

PACKAGES=(

  # ---- Core ----
  waybar
  rofi
  hyprlock
  wlogout
  swaync

  # ---- System ----
  gnome-bluetooth-3.0
  vte3
  imagemagick
  power-profiles-daemon
  upower
  networkmanager
  network-manager-applet
  nm-connection-editor

  # ---- Utilities ----
  grim
  slurp
  nautilus
  pavucontrol
  wl-clipboard
  libnotify
  swww
  awww-git

  # ---- Shell ----
  zsh
  oh-my-zsh-git
  zsh-theme-powerlevel10k
  eza

  # ---- Python / Fabric ----
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

  # ---- Theming ----
  matugen-bin
  adw-gtk-theme
  lxappearance
  bibata-cursor-theme

  # ---- Fonts ----
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  otf-geist-mono
  ttf-geist-mono-nerd
  otf-codenewroman-nerd 
)

# --------------------------------------------------
# Safety check
# --------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run this script as root."
  exit 1
fi

# --------------------------------------------------
# AUR helper detection
# --------------------------------------------------

aur_helper="yay"

if command -v paru &>/dev/null; then
  aur_helper="paru"
elif ! command -v yay &>/dev/null; then
  echo ":: Installing yay-bin"
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# --------------------------------------------------
# Install dependencies
# --------------------------------------------------

echo ":: Installing dependencies"
$aur_helper -Syy --needed --noconfirm "${PACKAGES[@]}" || true

# --------------------------------------------------
# Clone / Update Moonveil
# --------------------------------------------------

if [ -d "$MOONVEIL_DIR/.git" ]; then
  echo ":: Updating Moonveil"
  git -C "$MOONVEIL_DIR" pull
else
  echo ":: Cloning Moonveil"
  git clone --depth=1 "$MOONVEIL_REPO" "$MOONVEIL_DIR"
fi

# --------------------------------------------------
# Clone / Update Moonshell
# --------------------------------------------------

if [ -d "$MOONSHELL_DIR/.git" ]; then
  echo ":: Updating Moonshell"
  git -C "$MOONSHELL_DIR" pull
else
  echo ":: Cloning Moonshell"
  git clone --depth=1 "$MOONSHELL_REPO" "$MOONSHELL_DIR"
fi

# --------------------------------------------------
# Symlink Moonveil .config/*
# --------------------------------------------------

echo ":: Linking Moonveil config directories"

mkdir -p "$HOME/.config"

if [ -d "$MOONVEIL_DIR/.config" ]; then
  for dir in "$MOONVEIL_DIR/.config/"*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # do NOT touch moonshell
    if [ "$name" = "moonshell" ]; then
      continue
    fi

    ln -sfn "$dir" "$HOME/.config/$name"
  done
fi

# --------------------------------------------------
# Symlinks (Moonveil bin / share / shell)
# --------------------------------------------------

echo ":: Linking Moonveil files"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share"

# bin/*
if [ -d "$MOONVEIL_DIR/bin" ]; then
  for file in "$MOONVEIL_DIR/bin/"*; do
    [ -f "$file" ] || continue
    chmod +x "$file"
    ln -sfn "$file" "$HOME/.local/bin/$(basename "$file")"
  done
fi

# share/nvim
if [ -d "$MOONVEIL_DIR/share/nvim" ]; then
  ln -sfn "$MOONVEIL_DIR/share/nvim" "$HOME/.local/share/nvim"
fi

# zsh + p10k
if [ -f "$MOONVEIL_DIR/shell/zshrc" ]; then
  ln -sfn "$MOONVEIL_DIR/shell/zshrc" "$HOME/.zshrc"
fi

if [ -f "$MOONVEIL_DIR/shell/p10k.zsh" ]; then
  ln -sfn "$MOONVEIL_DIR/shell/p10k.zsh" "$HOME/.p10k.zsh"
fi

# --------------------------------------------------
# Network setup
# --------------------------------------------------

if systemctl is-enabled --quiet iwd 2>/dev/null; then
  sudo systemctl disable --now iwd
fi

sudo systemctl enable NetworkManager --now

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "✅ Moonveil installed in ~/moonveil"
echo "✅ Moonshell installed in ~/.config/moonshell"
echo "✅ Moonveil configs linked into ~/.config"
echo "ℹ️ No bar was auto-started"
echo "👉 Choose and launch your bar manually"
echo "👉 For wallpaer use mood shift+w key "
echo "👉 For waybar & moonbar use mood ctrl+w key" 
