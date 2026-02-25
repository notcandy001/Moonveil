#!/usr/bin/env bash
set -Eeuo pipefail

# ==================================================
# Moonveil Installer (Final Production Version)
# Arch Linux Only
# ==================================================

RESET="\e[0m"
BOLD="\e[1m"
PURPLE="\e[38;5;141m"
CYAN="\e[38;5;51m"
GREEN="\e[38;5;82m"
RED="\e[38;5;196m"

info() { echo -e "${CYAN}➜ $1${RESET}"; }
success() { echo -e "${GREEN}✔ $1${RESET}"; }
error() { echo -e "${RED}✘ $1${RESET}"; }

clear
echo -e "${PURPLE}${BOLD}"
cat << "EOF"
   __  ___                        _ __
  /  |/  /___  ____  ____  _   __(_) /__
 / /|_/ / __ \/ __ \/ __ \| | / / / / _ \
/ /  / / /_/ / /_/ / / / /| |/ / / /  __/
/_/  /_/\____/\____/_/ /_/ |___/_/_/\___/

        Moonveil Installer
EOF
echo -e "${RESET}"

# --------------------------------------------------
# Safety
# --------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
    error "Do NOT run as root."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    error "Arch Linux required."
    exit 1
fi

# --------------------------------------------------
# Update System
# --------------------------------------------------

info "Updating system..."
sudo pacman -Syu --noconfirm

# --------------------------------------------------
# Core Dependencies
# --------------------------------------------------

info "Installing core dependencies..."
sudo pacman -S --needed --noconfirm \
  base-devel git curl wget unzip go zsh \
  networkmanager network-manager-applet nm-connection-editor \
  power-profiles-daemon upower \
  fastfetch

sudo systemctl enable NetworkManager
sudo systemctl enable power-profiles-daemon

# --------------------------------------------------
# Choose AUR Helper
# --------------------------------------------------

echo
echo "Select AUR helper:"
echo "1) yay"
echo "2) paru"
echo
read -rp "Enter choice [1-2]: " aur_choice

case "$aur_choice" in
  2)
    AUR="paru"
    AUR_REPO="https://aur.archlinux.org/paru-bin.git"
    ;;
  *)
    AUR="yay"
    AUR_REPO="https://aur.archlinux.org/yay-bin.git"
    ;;
esac

if ! command -v "$AUR" &>/dev/null; then
    info "Installing $AUR..."
    tmpdir=$(mktemp -d)
    git clone "$AUR_REPO" "$tmpdir/$AUR"
    (cd "$tmpdir/$AUR" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# --------------------------------------------------
# Install Moonveil Stack
# --------------------------------------------------

info "Installing Moonveil packages..."

"$AUR" -S --needed --noconfirm \
  hyprland xdg-desktop-portal-hyprland \
  waybar rofi hyprlock wlogout swaync \
  grim slurp wl-clipboard hyprpicker hyprshot swww \
  nautilus pavucontrol libnotify gnome-bluetooth-3.0 vte3 \
  imagemagick \
  python python-gobject python-psutil python-watchdog \
  python-pillow python-toml python-ijson python-numpy \
  python-requests python-setproctitle \
  python-fabric-git fabric-cli \
  matugen-bin adw-gtk-theme lxappearance bibata-cursor-theme \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk \
  noto-fonts-emoji otf-geist-mono \
  ttf-geist-mono-nerd otf-codenewroman-nerd \
  eza

# --------------------------------------------------
# Clone Repositories
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
# Backup Existing Config
# --------------------------------------------------

info "Creating backup..."
BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -r "$HOME/.config" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$HOME/.local" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$HOME/.zshrc" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$HOME/.p10k.zsh" "$BACKUP_DIR/" 2>/dev/null || true

success "Backup saved to $BACKUP_DIR"

# --------------------------------------------------
# Replace Configs
# --------------------------------------------------

info "Deploying configs..."

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local"

CONFIGS=(hypr waybar rofi swaync)

for cfg in "${CONFIGS[@]}"; do
    rm -rf "$HOME/.config/$cfg"
done

cp -r "$MOONVEIL_DIR/dotfiles/.config/"* "$HOME/.config/"
cp -r "$MOONVEIL_DIR/dotfiles/.local/"* "$HOME/.local/"

success "Configs deployed."

# --------------------------------------------------
# Install Shell Files (. prefix)
# --------------------------------------------------

info "Installing shell configuration..."

SHELL_DIR="$MOONVEIL_DIR/dotfiles/shell"

if [ -d "$SHELL_DIR" ]; then
    [ -f "$SHELL_DIR/zshrc" ] && cp "$SHELL_DIR/zshrc" "$HOME/.zshrc"
    [ -f "$SHELL_DIR/p10k.zsh" ] && cp "$SHELL_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    success "Shell configuration installed."
fi

# --------------------------------------------------
# Install Oh My Posh (Clone + Build in HOME)
# --------------------------------------------------

info "Installing Oh My Posh..."

OMP_DIR="$HOME/oh-my-posh"

if [ -d "$OMP_DIR/.git" ]; then
    git -C "$OMP_DIR" pull
else
    git clone --depth=1 https://github.com/JanDeDobbeleer/oh-my-posh.git "$OMP_DIR"
fi

cd "$OMP_DIR"
go build -o "$OMP_DIR/oh-my-posh"

success "Oh My Posh ready in ~/oh-my-posh"

# --------------------------------------------------
# Install Oh My Zsh + Powerlevel10k
# --------------------------------------------------

info "Installing Oh My Zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

info "Installing Powerlevel10k..."

P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

if [ -d "$P10K_DIR/.git" ]; then
    git -C "$P10K_DIR" pull
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# --------------------------------------------------
# Set ZSH as Default Shell
# --------------------------------------------------

if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

# --------------------------------------------------
# Run rofi-wall (If GUI Active)
# --------------------------------------------------

info "Attempting to launch rofi-wall..."

if command -v rofi-wall &>/dev/null; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        rofi-wall || info "rofi-wall exited."
    else
        info "No graphical session detected. Run 'rofi-wall' after login."
    fi
else
    info "rofi-wall not found."
fi

# --------------------------------------------------
# Finish
# --------------------------------------------------

echo
success "Moonveil Installed Successfully!"
echo "AUR Helper : $AUR"
echo "Backup     : $BACKUP_DIR"
echo "Oh My Posh : ~/oh-my-posh"
echo "Powerlevel10k installed"
echo
echo "Reboot system."
echo
