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
WALLPAPER_DIR="$HOME/Pictures/Moonveil"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ================= UTILS =================
ask() {
  while true; do
    read -rp "$1 [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

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
  info "Installing Moonveil wallpapers"
  mkdir -p "$WALLPAPER_DIR"
  cp -r "$DOTFILES_DIR/wallpapers/"* "$WALLPAPER_DIR/"
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

  ask "Backup existing configs?" && backup_configs
  ask "Install pacman dependencies?" && install_packages
  ask "Install yay (AUR helper)?" && install_yay
  ask "Install AUR packages (matugen, chrome, icons)?" && install_aur_packages && apply_theme
  ask "Install oh-my-zsh?" && install_ohmyzsh
  ask "Install Powerlevel10k?" && install_p10k

  clone_dotfiles
  install_fonts
  symlink_configs

  ask "Install Moonveil wallpaper collection?" && install_wallpapers

  echo
  info "Moonveil installation complete!"
  echo "✨ Made by Rahul"
  echo "➡ Log out & log back in (or reboot)."
}

main
