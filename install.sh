#!/usr/bin/env bash
# ==================================================
# Moonveil Installer (Arch Linux)
# Made by Rahul
# ==================================================

set -euo pipefail

# ================= USER OPTIONS =================
BACKUP="${BACKUP:-false}"
WALLPAPERS="${WALLPAPERS:-false}"
ZSH_DEFAULT="${ZSH_DEFAULT:-false}"

# ================= CONFIG =================
INSTALLER_VERSION="1.2.0"

DOTFILES_REPO="https://github.com/notcandy001/Moonveil"
DOTFILES_DIR="$HOME/.moonveil"
GITHUB_DIR="$HOME/github"

WALLPAPER_REPO="https://github.com/notcandy001/my-wal"
WALLPAPER_DIR="$HOME/wallpaper"

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIRS=(hypr waybar rofi swaync kitty)

# ================= UI =================
info()  { echo -e "\e[1;34m[INFO]\e[0m $1"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERR]\e[0m $1"; exit 1; }

# ================= CHECKS =================
command -v pacman &>/dev/null || error "Arch Linux only."

# ================= BACKUP =================
backup_configs() {
  info "Backing up configs → $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR/.config"

  for dir in "${CONFIG_DIRS[@]}"; do
    [[ -d "$HOME/.config/$dir" ]] && \
      cp -r "$HOME/.config/$dir" "$BACKUP_DIR/.config/"
  done

  [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP_DIR/"
}

# ================= PACMAN =================
install_packages() {
  info "Installing pacman packages"
  sudo pacman -S --needed --noconfirm \
    base-devel git zsh unzip \
    hyprland waybar rofi kitty swaync hyprlock \
    grim slurp wl-clipboard \
    nautilus nautilus-share nautilus-image-converter \
    adw-gtk3 nwg-look lxappearance \
    noto-fonts noto-fonts-emoji \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
}

# ================= YAY =================
install_yay() {
  command -v yay &>/dev/null && return
  info "Installing yay"

  mkdir -p "$GITHUB_DIR"
  git clone https://aur.archlinux.org/yay.git "$GITHUB_DIR/yay"
  (cd "$GITHUB_DIR/yay" && makepkg -si --noconfirm)
}

# ================= AUR =================
install_aur_packages() {
  info "Installing AUR packages"
  yay -S --needed --noconfirm \
    matugen google-chrome papirus-icon-theme || \
    warn "Some AUR packages failed"
}

# ================= THEMES =================
apply_theme() {
  info "Applying GTK theme"
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" || true
  gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" || true
}

# ================= ZSH =================
install_zsh_extras() {
  [[ -d "$HOME/.oh-my-zsh" ]] || \
    RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || true

  [[ "$ZSH_DEFAULT" == "true" ]] && chsh -s "$(command -v zsh)" || true
}

# ================= DOTFILES =================
clone_dotfiles() {
  [[ -d "$DOTFILES_DIR" ]] || git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

symlink_configs() {
  info "Symlinking configs"
  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  for dir in "${CONFIG_DIRS[@]}"; do
    rm -rf "$HOME/.config/$dir"
    ln -s "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
  done

  ln -sf "$DOTFILES_DIR/bin/"* "$HOME/.local/bin/" || true
}

# ================= FONTS =================
install_fonts() {
  [[ -d "$DOTFILES_DIR/fonts" ]] || return
  info "Installing fonts"
  mkdir -p "$HOME/.local/share/fonts"
  cp -r "$DOTFILES_DIR/fonts/"* "$HOME/.local/share/fonts/"
  fc-cache -fv
}

# ================= WALLPAPERS =================
install_wallpapers() {
  [[ "$WALLPAPERS" == "true" ]] || return
  [[ -d "$WALLPAPER_DIR/.git" ]] || \
    git clone "$WALLPAPER_REPO" "$WALLPAPER_DIR"
}

# ================= MAIN =================
clear
cat <<EOF
╔══════════════════════════════════════╗
║  Moonveil Installer                  ║
║           Made by Rahul              ║
╚══════════════════════════════════════╝
EOF

[[ "$BACKUP" == "true" ]] && backup_configs

install_packages
install_yay
install_aur_packages
apply_theme
install_zsh_extras
clone_dotfiles
install_fonts
symlink_configs
install_wallpapers

echo
info "Moonveil installed successfully"
echo "✨ Made by Rahul"
echo "➡ Log out or reboot"
