#!/usr/bin/env bash
# ==================================================
# Moonveil Installer
# Author: Rahul (notcandy001)
# ==================================================

set -euo pipefail


#---------------Colors & UI-------------------------#
OK="$(tput setaf 2)[OK]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
ERR="$(tput setaf 1)[ERR]$(tput sgr0)"
RESET="$(tput sgr0)"


#---------------Config------------------------------#
REPO_URL="https://github.com/notcandy001/Moonveil.git"
INSTALL_DIR="$HOME/.moonveil"
GITHUB_DIR="$HOME/github"

CONFIG_DIRS=(
  hypr waybar rofi swaync kitty
  btop cava fastfetch gtk-3.0 wlogout
)


#---------------Helpers-----------------------------#
die()  { echo "${ERR} $1"; exit 1; }
msg()  { echo "${INFO} $1"; }
warn() { echo "${WARN} $1"; }


#---------------Distro Detection-------------------#
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  die "Cannot detect Linux distribution"
fi

case "$ID" in
  arch)
    INSTALL="sudo pacman -S --needed --noconfirm"
    ;;
  *)
    die "Moonveil currently supports Arch Linux only"
    ;;
esac


#---------------Git Check---------------------------#
if ! command -v git &>/dev/null; then
  msg "Git not found, installing"
  $INSTALL git || die "Failed to install git"
fi


#---------------Clone / Update----------------------#
clone_or_update() {
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    msg "Moonveil already installed, updating"
    git -C "$INSTALL_DIR" pull
  else
    msg "Cloning Moonveil"
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}


#---------------Pacman Packages--------------------#
install_packages() {
  msg "Installing pacman packages"

  $INSTALL \
    base-devel zsh unzip \
    hyprland waybar rofi kitty swaync hyprlock \
    grim slurp wl-clipboard \
    nautilus nwg-look lxappearance \
    adw-gtk-theme  \
    noto-fonts noto-fonts-emoji \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    otf-geist-mono-nerd \
    otf-codenewroman-nerd
}


#---------------Yay (AUR Helper)-------------------#
install_yay() {
  command -v yay &>/dev/null && return

  msg "Installing yay (AUR helper)"
  mkdir -p "$GITHUB_DIR"
  git clone https://aur.archlinux.org/yay.git "$GITHUB_DIR/yay"
  (cd "$GITHUB_DIR/yay" && makepkg -si --noconfirm)
}


#---------------AUR Packages-----------------------#
install_aur() {
  msg "Installing AUR packages"

  yay -S --needed --noconfirm \
    matugen-bin \
    papirus-icon-theme 
}


#---------------Symlinks----------------------------#
symlink_configs() {
  msg "Linking Moonveil configs"

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


#---------------Fonts (Repo Fonts)------------------#
install_fonts() {
  [[ -d "$INSTALL_DIR/fonts" ]] || return
  msg "Installing bundled fonts"
  mkdir -p "$HOME/.local/share/fonts"
  cp -r "$INSTALL_DIR/fonts/"* "$HOME/.local/share/fonts/"
  fc-cache -fv
}


#---------------Zsh Setup---------------------------#
setup_zsh() {
  msg "Setting up Zsh"

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
║   Moonveil Installer                 ║
║   Minimal • Aesthetic • Hyprland     ║
╚══════════════════════════════════════╝
EOF

clone_or_update
install_packages
install_yay
install_aur
install_fonts
symlink_configs
setup_zsh

echo
echo "${OK} Moonveil installed successfully"
echo "➡ Reboot or log out"
