#!/usr/bin/env bash
# Moonveil installer — Arch Linux & NixOS

set -Eeuo pipefail

REPO_URL="https://github.com/notcandy001/Moonveil.git"
INSTALL_DIR="$HOME/.local/src/Moonveil"
BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/moonveil-$(date +%Y%m%d-%H%M%S).log"

R="\e[0m"; B="\e[1m"
GREEN="\e[38;5;82m"; CYAN="\e[38;5;51m"
YELLOW="\e[38;5;226m"; RED="\e[38;5;196m"
GRAY="\e[38;5;240m"; WHITE="\e[38;5;255m"

ok()   { echo -e "  ${GREEN}✔${R}  $*"; }
info() { echo -e "  ${CYAN}·${R}  $*"; }
warn() { echo -e "  ${YELLOW}!${R}  $*"; }
die()  { echo -e "\n  ${RED}✖${R}  $*\n  ${GRAY}log: ${LOG_FILE}${R}\n"; exit 1; }
ask()  { echo -ne "\n  ${WHITE}${B}$*${R}  ${GRAY}[y/N]${R}  "; read -r _REPLY </dev/tty; echo ""; [[ "$_REPLY" =~ ^[Yy]$ ]]; }

has() { command -v "$1" >/dev/null 2>&1; }

exec > >(tee -a "$LOG_FILE") 2>&1

[[ "$EUID" -eq 0 ]] && die "Do not run as root."
has git  || die "git is required."
has curl || die "curl is required."


DISTRO="unknown"
if [[ -f /etc/os-release ]]; then
  source /etc/os-release
  case "${ID:-}" in
    arch|artix|cachyos|endeavouros|garuda|manjaro) DISTRO="arch"  ;;
    nixos)                                          DISTRO="nixos" ;;
  esac
  [[ "$DISTRO" == "unknown" && "${ID_LIKE:-}" == *arch* ]] && DISTRO="arch"
fi

[[ "$DISTRO" == "unknown" ]] && die "Unsupported distro. Only Arch Linux and NixOS are supported."

echo ""
info "Detected: ${DISTRO}"
info "Install dir: ${INSTALL_DIR}"
info "Log: ${LOG_FILE}"

ask "Start Moonveil installation?" || { echo -e "  Cancelled.\n"; exit 0; }

_clone_repo() {
  echo ""
  info "Cloning repository..."
  mkdir -p "$(dirname "$INSTALL_DIR")"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    local branch; branch=$(git -C "$INSTALL_DIR" rev-parse --abbrev-ref HEAD)
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
      git -C "$INSTALL_DIR" pull --ff-only >> "$LOG_FILE" 2>&1 || true
    fi
    ok "Repository updated → ${INSTALL_DIR}"
    return
  fi

  git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1 || die "Failed to clone repository."
  ok "Repository cloned → ${INSTALL_DIR}"
}

_apply_dotfiles() {
  echo ""
  info "Backing up existing configs → ${BACKUP_DIR}"
  mkdir -p "$BACKUP_DIR"
  [[ -d "$HOME/.config" ]] && cp -r "$HOME/.config" "$BACKUP_DIR/config" 2>/dev/null || true
  [[ -d "$HOME/.local"  ]] && cp -r "$HOME/.local"  "$BACKUP_DIR/local"  2>/dev/null || true
  ok "Backup done"

  echo ""
  info "Applying dotfiles..."

  if [[ -d "$INSTALL_DIR/dots/.config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$INSTALL_DIR/dots/.config/"* "$HOME/.config/"
    ok "~/.config"
  fi

  if [[ -d "$INSTALL_DIR/dots/.local" ]]; then
    mkdir -p "$HOME/.local"
    cp -r "$INSTALL_DIR/dots/.local/"* "$HOME/.local/"
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \; 2>/dev/null || true
    ok "~/.local"
  fi

  local shell_dir="$INSTALL_DIR/dots/shell"
  [[ -f "$shell_dir/zshrc"    ]] && cp "$shell_dir/zshrc"    "$HOME/.zshrc"    && ok "~/.zshrc"
  [[ -f "$shell_dir/p10k.zsh" ]] && cp "$shell_dir/p10k.zsh" "$HOME/.p10k.zsh" && ok "~/.p10k.zsh"
}

_arch_install() {
 
  echo ""
  info "Authenticating sudo..."
  sudo -v || die "Sudo authentication failed."
  
  echo ""
  info "Updating system..."
  sudo pacman -Syu --noconfirm

  echo ""
  info "Installing core dependencies..."
  sudo pacman -S --needed --noconfirm \
    base-devel git curl wget unzip \
    zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
    networkmanager network-manager-applet \
    power-profiles-daemon upower \
    fastfetch polkit-gnome

  sudo systemctl enable --now NetworkManager >> "$LOG_FILE" 2>&1 || true

 
  echo ""
  local AUR=""
  if has yay; then
    AUR="yay"; info "yay already installed"
  elif has paru; then
    AUR="paru"; info "paru already installed"
  else
    info "Installing yay..."
    local tmp; tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay" >> "$LOG_FILE" 2>&1 \
      || { rm -rf "$tmp"; die "Failed to clone yay."; }
    pushd "$tmp/yay" > /dev/null
    makepkg -si --noconfirm >> "$LOG_FILE" 2>&1 \
      || { popd > /dev/null; rm -rf "$tmp"; die "Failed to build yay."; }
    popd > /dev/null
    rm -rf "$tmp"
    AUR="yay"
    ok "yay installed"
  fi

  
  echo ""
  if has rodctl; then
    info "rodctl already installed"
  else
    info "Installing rodctl..."
    curl -fsSL https://raw.githubusercontent.com/notcandy001/rodctl/main/install.sh | bash \
      || die "Failed to install rodctl."
    ok "rodctl installed"
  fi

  
  echo ""
  info "Installing packages..."

  echo ""
  info "  pacman packages..."
  sudo pacman -S --needed --noconfirm \
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    xdg-utils xwayland hyprlock hypridle hyprpaper \
    grim slurp swappy wl-clipboard cliphist \
    kitty neovim luarocks stylua \
    nautilus ffmpegthumbnailer gvfs gvfs-mtp \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    pavucontrol pamixer playerctl brightnessctl ddcutil \
    bluez bluez-utils gnome-bluetooth-3.0 \
    btop cava imagemagick \
    nwg-look papirus-icon-theme lxappearance libnotify \
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
    noto-fonts noto-fonts-cjk noto-fonts-emoji otf-font-awesome \
    eza bat ripgrep fd jq yazi

  echo ""
  info "  AUR packages..."
  $AUR -S --needed --noconfirm --removemake --cleanafter \
    quickshell-git swaync hyprpicker \
    matugen python-pywal \
    adw-gtk3 bibata-cursor-theme

  ok "All packages installed"

  
  _clone_repo
  _apply_dotfiles

  
  echo ""
  info "Post-install..."

  local zsh_bin; zsh_bin=$(command -v zsh 2>/dev/null || true)
  if [[ -n "$zsh_bin" && "$SHELL" != "$zsh_bin" ]]; then
    chsh -s "$zsh_bin" 2>/dev/null && ok "Default shell → zsh" \
      || warn "chsh failed — run: chsh -s \$(which zsh)"
  fi

  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ ! -d "$p10k_dir" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" \
      >> "$LOG_FILE" 2>&1 && ok "Powerlevel10k installed" || warn "p10k failed — install manually"
  fi

  grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null \
    || { echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"; ok "~/.local/bin in PATH"; }

  for svc in NetworkManager bluetooth power-profiles-daemon; do
    systemctl list-unit-files "${svc}.service" &>/dev/null \
      && ! systemctl is-enabled --quiet "$svc" 2>/dev/null \
      && sudo systemctl enable --now "$svc" >> "$LOG_FILE" 2>&1 && ok "${svc} enabled" || true
  done

  fc-cache -fv >> "$LOG_FILE" 2>&1 && ok "Font cache rebuilt"
}


_nixos_install() {
  _clone_repo

  echo ""
  info "Applying flake..."

  if has nixos-rebuild; then
    sudo nixos-rebuild switch --flake "${INSTALL_DIR}#moonveil" \
      || warn "nixos-rebuild failed — trying home-manager..."
  fi

  if ! has home-manager; then
    info "Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager \
      >> "$LOG_FILE" 2>&1
    nix-channel --update >> "$LOG_FILE" 2>&1
    nix-shell '<home-manager>' -A install >> "$LOG_FILE" 2>&1 \
      || die "Failed to install home-manager."
  fi

  home-manager switch --flake "${INSTALL_DIR}#user" \
    || warn "home-manager switch had errors — check log."

  echo ""
  if has rodctl; then
    info "rodctl already installed"
  else
    info "Installing rodctl..."
    curl -L get.roderic.me/rodtl | sh  \
      || warn "rodctl install failed — install manually from github.com/notcandy001/rodctl"
    ok "rodctl installed"
  fi

  _apply_dotfiles
}

case "$DISTRO" in
  arch)  _arch_install  ;;
  nixos) _nixos_install ;;
esac

echo ""
ok "Done. Log out and select Hyprland, or run: Hyprland"
echo -e "  ${GRAY}log: ${LOG_FILE}${R}"
echo ""
