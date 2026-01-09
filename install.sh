#!/usr/bin/env bash
# ==================================================
# Moonveil Installer (Arch Linux)
# Made by Rahul
# ==================================================

set -e

# ================= CONFIG =================
DOTFILES_REPO="https://github.com/notcandy001/Moonveil"
DOTFILES_DIR="$HOME/.moonveil"
GITHUB_DIR="$HOME/github"

WALLPAPER_REPO="https://github.com/notcandy001/my-wal"
WALLPAPER_DIR="$HOME/wallpaper"

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ================= UTILS =================
info()  { echo -e "\e[1;34m[INFO]\e[0m $1"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERR]\e[0m $1"; exit 1; }

# ================= CHECK ARCH =================
check_arch() {
  command -v pacman &>/dev/null || error "This installer is Arch Linux only."
}

# ================= BACKUP =================
backup_configs() {
  info "Backing up existing configs to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp -r ~/.config "$BACKUP_DIR" 2>/dev/null || true
  cp ~/.zshrc "$BACKUP_DIR" 2>/dev/null || true
}

# ================= PACMAN =================
install_packages() {
  info "Installing pacman dependencies"
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
  command -v yay &>/dev/null && { warn "yay already installed"; return; }

  info "Installing yay"
  mkdir -p "$GITHUB_DIR"
  cd "$GITHUB_DIR"

  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
}

# ================= AUR =================
install_aur_packages() {
  info "Installing AUR packages"
  yay -S --needed --noconfirm \
    matugen \
    google-chrome \
    papirus-icon-theme
}

# ================= THEMES =================
apply_theme() {
  info "Applying GTK / icon theme"
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" || true
  gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" || true
}

# ================= ZSH =================
install_ohmyzsh() {
  [[ -d "$HOME/.oh-my-zsh" ]] && { warn "oh-my-zsh already installed"; return; }
  info "Installing oh-my-zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_p10k() {
  info "Installing Powerlevel10k"
  git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
}

# ================= DOTFILES =================
clone_dotfiles() {
  [[ -d "$DOTFILES_DIR" ]] && { warn "Moonveil already cloned"; return; }
  info "Cloning Moonveil"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

symlink_configs() {
  info "Symlinking configs"
  mkdir -p ~/.config ~/.local/bin

  for dir in hypr waybar rofi swaync kitty; do
    ln -sf "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
  done

  ln -sf "$DOTFILES_DIR/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
}

# ================= FONTS =================
install_fonts() {
  info "Installing fonts"
  mkdir -p ~/.local/share/fonts
  cp -r "$DOTFILES_DIR/fonts/"* ~/.local/share/fonts/ 2>/dev/null || true
  fc-cache -fv
}

# ================= WALLPAPERS =================
install_wallpapers() {
  if [[ -d "$WALLPAPER_DIR/.git" ]]; then
    warn "Wallpaper collection already exists"
    return
  fi

  info "Installing Moonveil wallpaper collection"
  git clone "$WALLPAPER_REPO" "$WALLPAPER_DIR"
}

# ================= MAIN =================
main() {
  check_arch

  clear
  echo "╔══════════════════════════════════════╗"
  echo "║           Moonveil Installer          ║"
  echo "║            Made by Rahul              ║"
  echo "╚══════════════════════════════════════╝"
  echo

  read -rp "Do you want to install Moonveil? [y/n]: " install_choice
  [[ "$install_choice" != "y" && "$install_choice" != "Y" ]] && {
    echo "Installation cancelled."
    exit 0
  }

  read -rp "Backup existing configs? [y/n]: " backup_choice
  [[ "$backup_choice" == "y" || "$backup_choice" == "Y" ]] && backup_configs

  read -rp "Install Moonveil wallpaper collection? [y/n]: " wp_choice

  info "Starting Moonveil installation..."

  install_packages
  install_yay
  install_aur_packages
  apply_theme
  install_ohmyzsh
  install_p10k
  clone_dotfiles
  install_fonts
  symlink_configs

  [[ "$wp_choice" == "y" || "$wp_choice" == "Y" ]] && install_wallpapers

  echo
  info "Moonveil installation complete!"
  echo "✨ Made by Rahul"
  echo "➡ Log out & log back in (or reboot)."
}

main
