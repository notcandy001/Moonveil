#!/bin/bash

set -e
set -u
set -o pipefail

# --------------------------------------------------
# Start Banner
# --------------------------------------------------

clear
cat << "EOF"

    __  ___                        _ __
   /  |/  /___  ____  ____  _   __(_) /__
  / /|_/ / __ \/ __ \/ __ \| | / / / / _ \
 / /  / / /_/ / /_/ / / / /| |/ / / /  __/
/_/  /_/\____/\____/_/ /_/ |___/_/_/\___/

Moonveil Hyprland Starter

EOF

echo

# --------------------------------------------------
# Safety
# --------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run this script as root."
  exit 1
fi

# --------------------------------------------------
# AUR Selection
# --------------------------------------------------

echo "Select AUR helper:"
echo "1) yay"
echo "2) paru"
echo
read -rp "Enter choice [1-2]: " aur_choice

case "$aur_choice" in
  1)
    aur_helper="yay"
    aur_repo="https://aur.archlinux.org/yay-bin.git"
    ;;
  2)
    aur_helper="paru"
    aur_repo="https://aur.archlinux.org/paru-bin.git"
    ;;
  *)
    echo "Invalid choice. Defaulting to yay."
    aur_helper="yay"
    aur_repo="https://aur.archlinux.org/yay-bin.git"
    ;;
esac

if ! command -v "$aur_helper" &>/dev/null; then
  echo ":: Installing $aur_helper"
  tmpdir=$(mktemp -d)
  git clone "$aur_repo" "$tmpdir/$aur_helper"
  (cd "$tmpdir/$aur_helper" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

# --------------------------------------------------
# Variables
# --------------------------------------------------

MOONVEIL_REPO="https://github.com/notcandy001/moonveil.git"
MOONSHELL_REPO="https://github.com/notcandy001/moonshell.git"
WALL_REPO="https://github.com/notcandy001/my-wal.git"

MOONVEIL_DIR="$HOME/moonveil"
MOONSHELL_DIR="$HOME/.config/moonshell"
WALL_DIR="$HOME/wallpaper"

# --------------------------------------------------
# Packages
# --------------------------------------------------

PACKAGES=(
  waybar rofi hyprlock wlogout swaync
  gnome-bluetooth-3.0 vte3 imagemagick
  power-profiles-daemon upower
  networkmanager network-manager-applet nm-connection-editor
  grim slurp nautilus pavucontrol wl-clipboard
  libnotify swww hyprpicker hyprshot
  zsh oh-my-zsh-git zsh-theme-powerlevel10k eza
  python python-gobject python-psutil python-watchdog
  python-pillow python-toml python-ijson python-numpy
  python-requests python-setproctitle
  python-fabric-git fabric-cli
  matugen-bin adw-gtk-theme lxappearance bibata-cursor-theme
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk
  noto-fonts-emoji otf-geist-mono ttf-geist-mono-nerd
  otf-codenewroman-nerd
  stow
)

echo ":: Installing packages"
"$aur_helper" -Syy --needed --noconfirm "${PACKAGES[@]}"

# --------------------------------------------------
# Clone / Update Repos
# --------------------------------------------------

[ -d "$MOONVEIL_DIR/.git" ] && \
  git -C "$MOONVEIL_DIR" pull || \
  git clone --depth=1 "$MOONVEIL_REPO" "$MOONVEIL_DIR"

[ -d "$MOONSHELL_DIR/.git" ] && \
  git -C "$MOONSHELL_DIR" pull || \
  git clone --depth=1 "$MOONSHELL_REPO" "$MOONSHELL_DIR"

[ -d "$WALL_DIR/.git" ] && \
  git -C "$WALL_DIR" pull || \
  git clone --depth=1 "$WALL_REPO" "$WALL_DIR"

# --------------------------------------------------
# Backup Existing Dotfiles
# --------------------------------------------------

BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo ":: Backing up existing dotfiles"

for path in "$HOME/.config" "$HOME/.local"; do
  [ -d "$path" ] && cp -r "$path" "$BACKUP_DIR/" || true
done

# --------------------------------------------------
# Deploy Dotfiles Using Stow (Professional Way)
# --------------------------------------------------

echo ":: Deploying dotfiles using GNU Stow"

cd "$MOONVEIL_DIR/dotfiles"
stow --target="$HOME" .config
stow --target="$HOME" .local

# --------------------------------------------------
# Shell Setup (Rename Properly)
# --------------------------------------------------

echo ":: Setting up Zsh configuration"

SHELL_DIR="$MOONVEIL_DIR/dotfiles/shell"

[ -f "$SHELL_DIR/zshrc" ] && cp "$SHELL_DIR/zshrc" "$HOME/.zshrc"
[ -f "$SHELL_DIR/p10k" ] && cp "$SHELL_DIR/p10k" "$HOME/.p10k.zsh"

# --------------------------------------------------
# Network
# --------------------------------------------------

if systemctl is-enabled --quiet iwd 2>/dev/null; then
  sudo systemctl disable --now iwd
fi

sudo systemctl enable NetworkManager --now

# --------------------------------------------------
# Wallpaper Selection
# --------------------------------------------------

echo ":: Launching wallpaper selector..."

if command -v rofi-wall &>/dev/null; then
  rofi-wall
fi

# 🔥 EDIT THIS IF YOUR CACHE LOCATION IS DIFFERENT
CURRENT_WALL="$HOME/.cache/current_wallpaper"
TARGET_LINK="$HOME/.current.wall"

[ -f "$CURRENT_WALL" ] && ln -sfn "$CURRENT_WALL" "$TARGET_LINK"

# --------------------------------------------------
# Final Screen
# --------------------------------------------------

sleep 1
clear

cat << "EOF"

    __  ___                        _ __
   /  |/  /___  ____  ____  _   __(_) /__
  / /|_/ / __ \/ __ \/ __ \| | / / / / _ \
 / /  / / /_/ / /_/ / / / /| |/ / / /  __/
/_/  /_/\____/\____/_/ /_/ |___/_/_/\___/

        Moonveil Installation Complete

Moonveil directory : ~/moonveil
Moonshell directory: ~/.config/moonshell
Wallpapers         : ~/wallpaper
Neovim config      : ~/.local/share/nvim
Binaries           : ~/.local/bin
Zsh config         : ~/.zshrc
Current wallpaper  : ~/current_wallpaper

Start bars         : Mod + Ctrl + W
Wallpaper menu     : Mod + Shift + W

EOF
