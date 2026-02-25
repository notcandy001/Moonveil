#!/bin/bash

set -e
set -u
set -euo pipefai

# --------------------------------------------------
# Colors
# --------------------------------------------------

RESET="\e[0m"
BOLD="\e[1m"
PURPLE="\e[38;5;141m"
CYAN="\e[38;5;51m"
GREEN="\e[38;5;82m"
RED="\e[38;5;196m"

info() { echo -e "${CYAN}➜ $1${RESET}"; }
success() { echo -e "${GREEN}✔ $1${RESET}"; }
error() { echo -e "${RED}✘ $1${RESET}"; }

# --------------------------------------------------
# Banner
# --------------------------------------------------

clear
echo -e "${PURPLE}${BOLD}"
cat << "EOF"
   __  ___                        _ __
  /  |/  /___  ____  ____  _   __(_) /__
 / /|_/ / __ \/ __ \/ __ \| | / / / / _ \
/ /  / / /_/ / /_/ / / / /| |/ / / /  __/
/_/  /_/\____/\____/_/ /_/ |___/_/_/\___/

        Moonveil Installer for Arch Linux
EOF
echo -e "${RESET}"

# --------------------------------------------------
# Safety
# --------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
    error "Do not run as root."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    error "This installer is for Arch Linux only."
    exit 1
fi

# --------------------------------------------------
# Ask AUR Helper
# --------------------------------------------------

echo
echo "Select AUR helper:"
echo "1) yay"
echo "2) paru"
echo
read -rp "Enter choice [1-2]: " aur_choice

case "$aur_choice" in
  1)
    AUR="yay"
    AUR_REPO="https://aur.archlinux.org/yay-bin.git"
    ;;
  2)
    AUR="paru"
    AUR_REPO="https://aur.archlinux.org/paru-bin.git"
    ;;
  *)
    AUR="yay"
    AUR_REPO="https://aur.archlinux.org/yay-bin.git"
    ;;
esac

# --------------------------------------------------
# Install base-devel (CRITICAL FIX)
# --------------------------------------------------

info "Installing base-devel..."
sudo pacman -S --needed --noconfirm base-devel

# --------------------------------------------------
# Install AUR helper if missing
# --------------------------------------------------

if ! command -v "$AUR" &>/dev/null; then
    info "Installing $AUR..."
    tmpdir=$(mktemp -d)
    git clone "$AUR_REPO" "$tmpdir/$AUR"
    (cd "$tmpdir/$AUR" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# --------------------------------------------------
# Full System Upgrade (prevents dependency hell)
# --------------------------------------------------

info "Updating system..."
sudo pacman -Syu --noconfirm

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
  otf-codenewroman-nerd stow
)

info "Installing packages..."
"$AUR" -S --needed --noconfirm "${PACKAGES[@]}"

# --------------------------------------------------
# Clone Repos
# --------------------------------------------------

MOONVEIL_DIR="$HOME/moonveil"
WALL_DIR="$HOME/wallpaper"

info "Cloning Moonveil..."
[ -d "$MOONVEIL_DIR/.git" ] && git -C "$MOONVEIL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/moonveil.git "$MOONVEIL_DIR"

info "Cloning Wallpapers..."
[ -d "$WALL_DIR/.git" ] && git -C "$WALL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/my-wal.git "$WALL_DIR"

# --------------------------------------------------
# Backup
# --------------------------------------------------

read -rp "Create backup of existing configs? (y/n): " BACKUP

if [[ "$BACKUP" == "y" ]]; then
    BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.local" "$BACKUP_DIR/" 2>/dev/null || true
    success "Backup saved to $BACKUP_DIR"
fi

# --------------------------------------------------
# Safe Deploy Dotfiles
# --------------------------------------------------

info "Deploying dotfiles..."

cd "$MOONVEIL_DIR/dotfiles"

# Remove conflicting real directories before stow
for item in .config/*; do
    target="$HOME/$item"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        rm -rf "$target"
    fi
done

for item in .local/*; do
    target="$HOME/$item"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        rm -rf "$target"
    fi
done

stow --target="$HOME" .config
stow --target="$HOME" .local

# --------------------------------------------------
# Shell Setup
# --------------------------------------------------

SHELL_DIR="$MOONVEIL_DIR/dotfiles/shell"
[ -f "$SHELL_DIR/zshrc" ] && cp "$SHELL_DIR/zshrc" "$HOME/.zshrc"
[ -f "$SHELL_DIR/p10k" ] && cp "$SHELL_DIR/p10k" "$HOME/.p10k.zsh"

# --------------------------------------------------
# Wallpaper
# --------------------------------------------------

if command -v rofi-wall &>/dev/null; then
    rofi-wall
fi

CURRENT_WALL="$HOME/.cache/current_wallpaper"
TARGET_LINK="$HOME/current_wallpaper"
[ -f "$CURRENT_WALL" ] && ln -sfn "$CURRENT_WALL" "$TARGET_LINK"

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
success "Moonveil Installation Complete!"
echo "Moonveil directory : ~/moonveil"
echo "Wallpapers         : ~/wallpaper"
echo "Current wallpaper  : ~/current_wallpaper"
echo
echo "Start bars: Mod + Ctrl + W"
echo
