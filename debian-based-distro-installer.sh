#!/bin/bash

set -euo pipefail

# --------------------------------------------------
# Colors
# --------------------------------------------------

RESET="\e[0m"
BOLD="\e[1m"

PURPLE="\e[38;5;141m"
PINK="\e[38;5;213m"
CYAN="\e[38;5;51m"
GREEN="\e[38;5;82m"
RED="\e[38;5;196m"
GRAY="\e[38;5;240m"

print_success() { echo -e "${GREEN}✔ $1${RESET}"; }
print_error() { echo -e "${RED}✘ $1${RESET}"; }
print_info() { echo -e "${CYAN}➜ $1${RESET}"; }

# --------------------------------------------------
# Detect Distro (Early for Banner)
# --------------------------------------------------

if grep -qi "ubuntu" /etc/os-release; then
    DISTRO_NAME="Ubuntu"
    DISTRO_ID="ubuntu"
elif grep -qi "zorin" /etc/os-release; then
    DISTRO_NAME="Zorin"
    DISTRO_ID="zorin"
elif grep -qi "linuxmint" /etc/os-release; then
    DISTRO_NAME="Linux Mint"
    DISTRO_ID="linuxmint"
elif grep -qi "debian" /etc/os-release; then
    DISTRO_NAME="Debian"
    DISTRO_ID="debian"
else
    echo -e "${RED}Unsupported distribution.${RESET}"
    exit 1
fi

# --------------------------------------------------
# Moonveil Banner
# --------------------------------------------------

show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << EOF
    __  ___                        _ __
   /  |/  /___  ____  ____  _   __(_) /__
  / /|_/ / __ \/ __ \/ __ \| | / / / / _ \
 / /  / / /_/ / /_/ / / / /| |/ / / /  __/
/_/  /_/\____/\____/_/ /_/ |___/_/_/\___/

      Moonveil Installer for ${DISTRO_NAME}
EOF
    echo -e "${RESET}"
}

# --------------------------------------------------
# Toggle UI
# --------------------------------------------------

prompt_yes_no() {
    local prompt="$1"
    local selected=0

    while true; do
        show_banner
        echo
        echo -e "${PURPLE}${BOLD}$prompt${RESET}"
        echo
        if [ $selected -eq 0 ]; then
            echo -e "   ${PINK}[ Yes ]${RESET}    ${GRAY}No${RESET}"
        else
            echo -e "   ${GRAY}Yes${RESET}    ${PINK}[ No ]${RESET}"
        fi
        echo
        echo -e "${GRAY}← → toggle • Enter submit${RESET}"

        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            [[ $key == "[C" ]] && selected=1
            [[ $key == "[D" ]] && selected=0
        elif [[ $key == "" ]]; then
            break
        fi
    done

    return $selected
}

# --------------------------------------------------
# Start Prompts
# --------------------------------------------------

prompt_yes_no "Do you want to proceed with the installation?"
if [ $? -eq 1 ]; then
    show_banner
    print_error "Installation cancelled."
    exit 0
fi

prompt_yes_no "Do you want to create a backup before installation?"
BACKUP_CHOICE=$?

# --------------------------------------------------
# Hyprland Install
# --------------------------------------------------

if ! command -v Hyprland &>/dev/null; then
    if [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "zorin" || "$DISTRO_ID" == "linuxmint" ]]; then
        print_info "Installing Hyprland via official PPA..."
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:hyprland-dev/hyprland
        sudo apt update
        sudo apt install -y hyprland
    else
        print_error "Hyprland auto-install not supported on Debian."
        exit 1
    fi
fi

# --------------------------------------------------
# Update & Install Packages
# --------------------------------------------------

print_info "Updating system..."
sudo apt update
sudo apt upgrade -y

print_info "Installing required packages..."
sudo apt install -y \
    waybar rofi network-manager network-manager-gnome \
    pavucontrol wl-clipboard grim slurp \
    zsh neovim \
    python3 python3-pip python3-psutil python3-watchdog \
    python3-pil python3-requests \
    imagemagick lxappearance \
    fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
    curl git stow unzip

# --------------------------------------------------
# Install Nerd Fonts
# --------------------------------------------------

print_info "Installing Nerd Fonts..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

install_font () {
    NAME=$1
    URL=$2
    TMP_ZIP=$(mktemp)
    curl -L "$URL" -o "$TMP_ZIP"
    unzip -o "$TMP_ZIP" -d "$FONT_DIR/$NAME" >/dev/null
    rm "$TMP_ZIP"
}

install_font "GeistMono" \
"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/GeistMono.zip"

install_font "CodeNewRoman" \
"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CodeNewRoman.zip"

install_font "JetBrainsMono" \
"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

fc-cache -fv >/dev/null
print_success "Fonts installed"

# --------------------------------------------------
# Clone Moonveil & Wallpapers
# --------------------------------------------------

MOONVEIL_DIR="$HOME/moonveil"
WALL_DIR="$HOME/wallpaper"

print_info "Cloning Moonveil..."
[ -d "$MOONVEIL_DIR/.git" ] && git -C "$MOONVEIL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/moonveil.git "$MOONVEIL_DIR"

print_info "Cloning Wallpapers..."
[ -d "$WALL_DIR/.git" ] && git -C "$WALL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/my-wal.git "$WALL_DIR"

# --------------------------------------------------
# Backup (Optional)
# --------------------------------------------------

if [ $BACKUP_CHOICE -eq 0 ]; then
    BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.local" "$BACKUP_DIR/" 2>/dev/null || true
    print_success "Backup created at $BACKUP_DIR"
fi

# --------------------------------------------------
# Deploy Dotfiles
# --------------------------------------------------

print_info "Deploying dotfiles..."
cd "$MOONVEIL_DIR/dotfiles"
stow --target="$HOME" .config
stow --target="$HOME" .local

# Shell
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

# -------------------------------------------------
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
Wallpapers         : ~/wallpaper
Neovim config      : ~/.local/share/nvim
Fonts installed    : ~/.local/share/fonts
Zsh config         : ~/.zshrc
Current wallpaper  : ~/current_wallpaper

Log out and select Hyprland from your display manager.

EFO
