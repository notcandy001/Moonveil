#!/usr/bin/env bash
set -Eeuo pipefail

# ==================================================
# Moonveil Installer (Ubuntu / Debian Edition)
# ==================================================

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
# Detect Distro
# --------------------------------------------------

source /etc/os-release

case "$ID" in
    ubuntu|zorin|linuxmint)
        DISTRO_NAME="$NAME"
        ;;
    debian)
        DISTRO_NAME="Debian"
        ;;
    *)
        print_error "Unsupported distribution."
        exit 1
        ;;
esac

# --------------------------------------------------
# Banner
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
# Prompts
# --------------------------------------------------

show_banner
read -rp "Proceed with installation? (y/n): " proceed
[[ "$proceed" != "y" ]] && exit 0

read -rp "Create backup before install? (y/n): " backup_choice

# --------------------------------------------------
# Hyprland Install
# --------------------------------------------------

if ! command -v Hyprland &>/dev/null; then
    if [[ "$ID" != "debian" ]]; then
        print_info "Installing Hyprland via PPA..."
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
sudo apt update && sudo apt upgrade -y

print_info "Installing required packages..."

sudo apt install -y \
    waybar rofi network-manager network-manager-gnome \
    pavucontrol wl-clipboard grim slurp \
    zsh neovim \
    python3 python3-pip python3-psutil python3-watchdog \
    python3-pil python3-requests \
    imagemagick lxappearance \
    fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
    curl git unzip

# --------------------------------------------------
# Nerd Fonts
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
# Clone Repositories
# --------------------------------------------------

MOONVEIL_DIR="$HOME/moonveil"
WALL_DIR="$HOME/wallpaper"
MOONSHELL_DIR="$HOME/.config/moonshell"

print_info "Cloning Moonveil..."
[ -d "$MOONVEIL_DIR/.git" ] && git -C "$MOONVEIL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/moonveil.git "$MOONVEIL_DIR"

print_info "Cloning Wallpapers..."
[ -d "$WALL_DIR/.git" ] && git -C "$WALL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/my-wal.git "$WALL_DIR"

print_info "Cloning Moonshell..."
mkdir -p "$HOME/.config"
[ -d "$MOONSHELL_DIR/.git" ] && git -C "$MOONSHELL_DIR" pull || \
git clone --depth=1 https://github.com/notcandy001/moonshell.git "$MOONSHELL_DIR"

# --------------------------------------------------
# Backup
# --------------------------------------------------

if [[ "$backup_choice" == "y" ]]; then
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

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local"

cp -r "$MOONVEIL_DIR/dotfiles/.config/"* "$HOME/.config/"
cp -r "$MOONVEIL_DIR/dotfiles/.local/"* "$HOME/.local/"

# --------------------------------------------------
# Oh My Zsh + Powerlevel10k
# --------------------------------------------------

print_info "Installing Oh My Zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

print_info "Installing Powerlevel10k..."

git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git \
"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || true

SHELL_DIR="$MOONVEIL_DIR/dotfiles/shell"
[ -f "$SHELL_DIR/zshrc" ] && cp "$SHELL_DIR/zshrc" "$HOME/.zshrc"
[ -f "$SHELL_DIR/p10k.zsh" ] && cp "$SHELL_DIR/p10k.zsh" "$HOME/.p10k.zsh"

if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

# --------------------------------------------------
# Wallpaper Symlink
# --------------------------------------------------

CURRENT_WALL="$HOME/.cache/current_wallpaper"
TARGET_LINK="$HOME/current_wall"

[ -f "$CURRENT_WALL" ] && ln -sfn "$CURRENT_WALL" "$TARGET_LINK"

# --------------------------------------------------
# Auto Launch rofi-wall (if graphical session active)
# --------------------------------------------------

print_info "Attempting to launch rofi-wall..."

if command -v rofi-wall &>/dev/null; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        rofi-wall || print_info "rofi-wall exited."
    else
        print_info "No graphical session detected. Run 'rofi-wall' after login."
    fi
else
    print_info "rofi-wall not found. Skipping."
fi

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
Fonts installed    : ~/.local/share/fonts
Zsh config         : ~/.zshrc
Current wallpaper  : ~/current_wall

Log out and select Hyprland from your display manager.

EOF
