#!/usr/bin/env bash
# ==================================================
# Moonveil Installer For (Arch Linux)
# Author: Rahul
# ==================================================

set -euo pipefail


#---------------Config------------------------------#
REPO_URL="https://github.com/notcandy001/Moonveil"
INSTALL_DIR="$HOME/.moonveil"
GITHUB_DIR="$HOME/github"

CONFIG_DIRS=(
  hypr waybar rofi swaync kitty
  btop cava fastfetch gtk-3.0 wlogout
)


#---------------UI Helpers--------------------------#
info()  { echo -e "\e[1;34m[INFO]\e[0m $1"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERR]\e[0m $1"; exit 1; }


#---------------Checks------------------------------#
command -v pacman &>/dev/null || error "Arch Linux only."


#---------------Clone Repo--------------------------#
clone_repo() {
  info "Cloning Moonveil → $INSTALL_DIR"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Moonveil already exists, pulling updates"
    git -C "$INSTALL_DIR" pull
  else
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}


#---------------Pacman Packages---------------------#
install_packages() {
  info "Installing required packages"

  sudo pacman -S --needed --noconfirm \
    base-devel git zsh unzip \
    hyprland waybar rofi kitty swaync hyprlock \
    grim slurp wl-clipboard \
    nautilus nautilus-share nautilus-image-converter \
    adw-gtk3 nwg-look lxappearance \
    noto-fonts noto-fonts-emoji \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
}


#---------------Yay---------------------------------#
install_yay() {
  command -v yay &>/dev/null && return
  info "Installing yay"

  mkdir -p "$GITHUB_DIR"
  git clone https://aur.archlinux.org/yay.git "$GITHUB_DIR/yay"
  (cd "$GITHUB_DIR/yay" && makepkg -si --noconfirm)
}


#---------------AUR Packages------------------------#
install_aur_packages() {
  info "Installing AUR packages"

  yay -S --needed --noconfirm \
    matugen papirus-icon-theme google-chrome || \
    warn "Some AUR packages failed"
}


#---------------Symlinks----------------------------#
symlink_configs() {
  info "Symlinking Moonveil configs"

  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  for dir in "${CONFIG_DIRS[@]}"; do
    [[ -d "$INSTALL_DIR/.config/$dir" ]] || continue
    rm -rf "$HOME/.config/$dir"
    ln -s "$INSTALL_DIR/.config/$dir" "$HOME/.config/$dir"
  done

  ln -sf "$INSTALL_DIR/.zshrc" "$HOME/.zshrc"
  ln -sf "$INSTALL_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
  ln -sf "$INSTALL_DIR/bin/"* "$HOME/.local/bin/" || true
}


#---------------Fonts-------------------------------#
install_fonts() {
  [[ -d "$INSTALL_DIR/fonts" ]] || return
  info "Installing fonts"

  mkdir -p "$HOME/.local/share/fonts"
  cp -r "$INSTALL_DIR/fonts/"* "$HOME/.local/share/fonts/"
  fc-cache -fv
}


#---------------Zsh Setup---------------------------#
install_zsh() {
  info "Setting up Zsh"

  [[ -d "$HOME/.oh-my-zsh" ]] || \
    RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || true

  chsh -s "$(command -v zsh)" || true
}


#---------------Main--------------------------------#
clear
cat <<EOF
╔══════════════════════════════════════╗
║  Moonveil Installer                  ║
║           Made by Rahul              ║
╚══════════════════════════════════════╝
EOF

clone_repo
install_packages
install_yay
install_aur_packages
install_fonts
symlink_configs
install_zsh

echo
info "Moonveil installed successfully"
echo "➡ Log out or reboot"
