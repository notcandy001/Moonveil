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

  # --- Core ---
  waybar
  rofi
  hyprlock
  wlogout
  swaync

  # --- System ---
  gnome-bluetooth-3.0
  vte3
  imagemagick
  power-profiles-daemon
  upower
  networkmanager
  network-manager-applet
  nm-connection-editor

  # --- Utilities ---
  grim
  slurp
  nautilus
  pavucontrol
  wl-clipboard
  libnotify
  swww
  hyprpicker
  hyprshot

  # --- Shell ---
  zsh
  oh-my-zsh-git
  zsh-theme-powerlevel10k
  eza

  # --- Python ---
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

  # --- Fabric ---
  python-fabric-git
  fabric-cli

  # --- Theming ---
  matugen-bin
  adw-gtk-theme
  lxappearance
  bibata-cursor-theme

  # --- Fonts ---
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  otf-geist-mono
  ttf-geist-mono-nerd
  otf-codenewroman-nerd
)

# --------------------------------------------------
# Safety
# --------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run this script as root."
  exit 1
fi

# --------------------------------------------------
# AUR helper
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
# Install packages
# --------------------------------------------------

echo ":: Installing packages"
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

SRC_CONFIG="$MOONVEIL_DIR/dotfiles/.config"
mkdir -p "$HOME/.config"

if [ -d "$SRC_CONFIG" ]; then
  for dir in "$SRC_CONFIG"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # do not overwrite moonshell
    [ "$name" = "moonshell" ] && continue

    ln -sfn "$dir" "$HOME/.config/$name"
  done
fi

# --------------------------------------------------
# Symlink bin/*
# --------------------------------------------------

echo ":: Linking Moonveil bin scripts"

SRC_BIN="$MOONVEIL_DIR/dotfiles/bin"
mkdir -p "$HOME/.local/bin"

if [ -d "$SRC_BIN" ]; then
  for file in "$SRC_BIN"/*; do
    [ -f "$file" ] || continue
    chmod +x "$file"
    ln -sfn "$file" "$HOME/.local/bin/$(basename "$file")"
  done
fi

# --------------------------------------------------
# Symlink Neovim
# --------------------------------------------------

SRC_NVIM="$MOONVEIL_DIR/dotfiles/share/nvim"
mkdir -p "$HOME/.local/share"

if [ -d "$SRC_NVIM" ]; then
  ln -sfn "$SRC_NVIM" "$HOME/.local/share/nvim"
fi

# --------------------------------------------------
# Zsh / P10k
# --------------------------------------------------

if [ -f "$MOONVEIL_DIR/shell/zshrc" ]; then
  ln -sfn "$MOONVEIL_DIR/shell/zshrc" "$HOME/.zshrc"
fi

if [ -f "$MOONVEIL_DIR/shell/p10k.zsh" ]; then
  ln -sfn "$MOONVEIL_DIR/shell/p10k.zsh" "$HOME/.p10k.zsh"
fi

# --------------------------------------------------
# Network
# --------------------------------------------------

if systemctl is-enabled --quiet iwd 2>/dev/null; then
  sudo systemctl disable --now iwd
fi

sudo systemctl enable NetworkManager --now

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "✅ Moonveil installed at ~/moonveil"
echo "✅ Moonshell installed at ~/.config/moonshell"
echo "✅ Configs linked from dotfiles/.config"
echo "✅ Scripts linked to ~/.local/bin (including moonveil-control-center)"
echo "ℹ️ Nothing auto-started"
echo "👉 Start bars manually using Mod ctrl + w  (Waybar / Moonshell)"
echo "👉 For wallpapers use Mod Shift + w "
