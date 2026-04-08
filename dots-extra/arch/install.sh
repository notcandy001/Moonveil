#!/usr/bin/env bash
# ==============================================================================
#  dots-extra/arch/install.sh  —  Moonveil Arch Linux Installer
#
#  Called by get/install.sh when an Arch-based distro is detected.
#  Supports: Arch, Manjaro, EndeavourOS, CachyOS, Garuda, Artix
#
#  Stack:
#    Compositor    →  Hyprland
#    Shell UI      →  CrescentShell (QuickShell/QML)
#    Terminal      →  Kitty
#    Editor        →  Neovim (NvChad)
#    Theming       →  matugen + pywal (Material You)
#    Notifications →  swaync (D-Bus backend, UI via CrescentShell)
#    Lock          →  hyprlock
#    Idle          →  hypridle
#    Monitor       →  btop + cava
#    Fetch         →  fastfetch
#
#  NOTE: waybar and rofi are NOT installed.
#        CrescentShell handles bar, launcher, control-center,
#        overview and notification surface entirely via QML.
#
#  Do NOT run directly — use get/install.sh
# ==============================================================================

set -Eeuo pipefail

# ── Parse args from get/install.sh ───────────────────────────────────────────
MV_LOG_FILE="/tmp/moonveil.log"
MV_REPO_ROOT=""
MV_COMMON_LIB=""
MV_VERSION="1.0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)         MV_LOG_FILE="$2";    shift 2 ;;
    --repo-root)   MV_REPO_ROOT="$2";  shift 2 ;;
    --common-lib)  MV_COMMON_LIB="$2"; shift 2 ;;
    --version)     MV_VERSION="$2";    shift 2 ;;
    *) shift ;;
  esac
done

export MV_LOG_FILE MV_REPO_ROOT MV_COMMON_LIB MV_VERSION

# ── Load shared library ───────────────────────────────────────────────────────
# Priority: --common-lib arg → local repo path → download
_resolve_common_lib() {
  # 1. Passed explicitly
  if [[ -n "$MV_COMMON_LIB" && -f "$MV_COMMON_LIB" ]]; then
    echo "$MV_COMMON_LIB"; return 0
  fi

  # 2. Local repo (dots-extra/arch/../../get/lib/common.sh)
  local this_dir
  this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local local_lib="${this_dir}/../../get/lib/common.sh"
  if [[ -f "$local_lib" ]]; then
    echo "$local_lib"; return 0
  fi

  # 3. Download
  local tmp
  tmp=$(mktemp /tmp/moonveil-common-XXXXXX.sh)
  curl -fsSL \
    "https://raw.githubusercontent.com/notcandy001/Moonveil/refs/heads/master/get/lib/common.sh" \
    -o "$tmp" 2>/dev/null || { echo "ERROR: cannot load common.sh" >&2; exit 1; }
  echo "$tmp"
}

# shellcheck source=../../get/lib/common.sh
source "$(_resolve_common_lib)"

# ── Paths ─────────────────────────────────────────────────────────────────────
readonly REPO_URL="https://github.com/notcandy001/Moonveil.git"
readonly AUR_REPO="https://aur.archlinux.org/yay-bin.git"
readonly INSTALL_DIR="$HOME/moonveil"
readonly BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"

# ── Step count ────────────────────────────────────────────────────────────────
MV_STEP_TOTAL=7

# ── Sudo keepalive ────────────────────────────────────────────────────────────
SUDO_PID=""
_start_sudo_keepalive() {
  sudo -v || mv_error "Sudo authentication failed."
  ( while true; do sudo -n true; sleep 50; done ) &
  SUDO_PID=$!
}
_stop_sudo_keepalive() {
  [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null || true
}
trap '_stop_sudo_keepalive' EXIT INT TERM

# ── Package helpers ───────────────────────────────────────────────────────────
_pacman_installed() { pacman -Qi "$1" &>/dev/null; }
_pacman_install()   { sudo pacman -S --needed --noconfirm "$1"; }
_aur_installed()    { pacman -Qi "$1" &>/dev/null; }
_aur_install()      { yay -S --needed --noconfirm --removemake --cleanafter "$1"; }

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 1 — SUDO + SYSTEM UPDATE
# ══════════════════════════════════════════════════════════════════════════════

_step_update() {
  mv_step "System Update"

  mv_info "Requesting sudo..."
  _start_sudo_keepalive
  mv_success "Sudo active"

  mv_info "Running pacman -Syu..."
  echo ""
  sudo pacman -Syu --noconfirm
  echo ""
  mv_success "System is up to date"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 2 — CORE PACKAGES
# ══════════════════════════════════════════════════════════════════════════════

_step_core() {
  mv_step "Core Dependencies"

  local -a pkgs=(
    base-devel
    git
    curl
    wget
    unzip
    zsh
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    networkmanager
    network-manager-applet
    nm-connection-editor
    power-profiles-daemon
    upower
    fastfetch
    polkit-gnome
  )

  mv_pkg_start "${#pkgs[@]}" "core packages via pacman"
  for pkg in "${pkgs[@]}"; do
    mv_install_pkg "$pkg" "pacman" _pacman_installed _pacman_install
  done

  echo ""
  mv_success "Core packages ready"

  mv_info "Enabling NetworkManager..."
  sudo systemctl enable --now NetworkManager >> "$MV_LOG_FILE" 2>&1 || true
  mv_success "NetworkManager enabled"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 3 — AUR HELPER (yay)
# ══════════════════════════════════════════════════════════════════════════════

_step_aur_helper() {
  mv_step "AUR Helper  (yay)"

  if command -v yay &>/dev/null; then
    mv_success "yay already installed — $(yay --version | head -1)"
    return
  fi

  mv_info "Cloning yay-bin from AUR..."
  local tmp; tmp=$(mktemp -d)

  git clone "$AUR_REPO" "$tmp/yay" >> "$MV_LOG_FILE" 2>&1 \
    || { rm -rf "$tmp"; mv_error "Failed to clone yay."; }

  mv_info "Building with makepkg..."
  pushd "$tmp/yay" > /dev/null
  makepkg -si --noconfirm >> "$MV_LOG_FILE" 2>&1 \
    || { popd > /dev/null; rm -rf "$tmp"; mv_error "Failed to build yay."; }
  popd > /dev/null
  rm -rf "$tmp"

  mv_success "yay installed — $(yay --version | head -1)"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 4 — MOONVEIL PACKAGES
#
#  No waybar, no rofi.
#  CrescentShell (QuickShell/QML) handles:
#    · Panel / taskbar
#    · App launcher
#    · Control center   (moonveil-control-center in dots/.local/bin)
#    · Notification UI  (wraps swaync over D-Bus)
#    · Overview / window switcher
# ══════════════════════════════════════════════════════════════════════════════

_step_packages() {
  mv_step "Moonveil Packages"

  # Format: "name|source"
  local -a pkgs=(
    # ── Hyprland stack ───────────────────────────────────
    "hyprland|pacman"
    "xdg-desktop-portal-hyprland|pacman"
    "xdg-desktop-portal-gtk|pacman"
    "xdg-utils|pacman"
    "xwayland|pacman"
    "hyprlock|pacman"
    "hypridle|pacman"
    "hyprpaper|pacman"

    # ── CrescentShell — full shell UI via QML ────────────
    "quickshell-git|aur"

    # ── Notifications D-Bus backend ──────────────────────
    "swaync|aur"

    # ── Screenshot ───────────────────────────────────────
    "grim|pacman"
    "slurp|pacman"
    "swappy|pacman"

    # ── Clipboard ────────────────────────────────────────
    "wl-clipboard|pacman"
    "cliphist|pacman"

    # ── Color picker (control-center) ────────────────────
    "hyprpicker|aur"

    # ── Terminal ─────────────────────────────────────────
    "kitty|pacman"

    # ── Editor — NvChad config lives in dots/.local/share/nvim
    "neovim|pacman"
    "luarocks|pacman"
    "stylua|pacman"

    # ── File manager ─────────────────────────────────────
    "nautilus|pacman"
    "ffmpegthumbnailer|pacman"
    "gvfs|pacman"
    "gvfs-mtp|pacman"

    # ── Audio ────────────────────────────────────────────
    "pipewire|pacman"
    "pipewire-alsa|pacman"
    "pipewire-pulse|pacman"
    "wireplumber|pacman"
    "pavucontrol|pacman"
    "pamixer|pacman"

    # ── Media controls (MPRIS widget in CrescentShell) ───
    "playerctl|pacman"

    # ── Brightness (CrescentShell slider) ────────────────
    "brightnessctl|pacman"

    # ── Bluetooth ────────────────────────────────────────
    "bluez|pacman"
    "bluez-utils|pacman"
    "gnome-bluetooth-3.0|pacman"

    # ── Visualizer ───────────────────────────────────────
    "cava|aur"

    # ── System monitor ───────────────────────────────────
    "btop|pacman"

    # ── Theming — walset-backend uses matugen + pywal ────
    "matugen|aur"
    "python-pywal|aur"
    "imagemagick|pacman"
    "adw-gtk-theme|aur"
    "bibata-cursor-theme|aur"
    "nwg-look|aur"

    # ── Icons & GTK ──────────────────────────────────────
    "papirus-icon-theme|pacman"
    "lxappearance|pacman"

    # ── Notifications library ────────────────────────────
    "libnotify|pacman"

    # ── Fonts ────────────────────────────────────────────
    "ttf-jetbrains-mono-nerd|pacman"
    "noto-fonts|pacman"
    "noto-fonts-cjk|pacman"
    "noto-fonts-emoji|pacman"
    "otf-geist-mono|aur"
    "ttf-geist-mono-nerd|aur"
    "otf-geist-mono-nerd|aur"
    "otf-codenewroman-nerd|aur"
    "ttf-libre-barcode|aur"

    # ── CLI utilities ────────────────────────────────────
    "eza|pacman"
    "bat|pacman"
    "ripgrep|pacman"
    "fd|pacman"
    "jq|pacman"
    "yazi|pacman"
  )

  mv_pkg_start "${#pkgs[@]}" "Moonveil packages (pacman + AUR)"

  local prev_group=""
  for entry in "${pkgs[@]}"; do
    local pkg="${entry%%|*}"
    local src="${entry##*|}"

    local group=""
    case "$pkg" in
      hyprland|xdg-desktop-portal*|xdg-utils|xwayland|hyprlock|hypridle|hyprpaper)
                                                     group="Hyprland Compositor" ;;
      quickshell*)                                   group="CrescentShell (QuickShell)" ;;
      swaync)                                        group="Notifications Backend" ;;
      grim|slurp|swappy)                             group="Screenshot" ;;
      wl-clipboard|cliphist|hyprpicker)              group="Clipboard & Color" ;;
      kitty)                                         group="Terminal" ;;
      neovim|luarocks|stylua)                        group="Editor (Neovim + NvChad)" ;;
      nautilus|ffmpegthumbnailer|gvfs*)              group="File Manager" ;;
      pipewire*|wireplumber|pavucontrol|pamixer)     group="Audio (Pipewire)" ;;
      playerctl)                                     group="Media Controls" ;;
      brightnessctl)                                 group="Brightness" ;;
      bluez*|gnome-bluetooth*)                       group="Bluetooth" ;;
      cava)                                          group="Visualizer" ;;
      btop)                                          group="System Monitor" ;;
      matugen|python-pywal|imagemagick|adw-gtk*|bibata*|nwg-look)
                                                     group="Theming (Material You)" ;;
      papirus-icon-theme|lxappearance)               group="Icons & GTK" ;;
      libnotify)                                     group="Notifications Library" ;;
      ttf-*|noto-*|otf-*)                            group="Fonts" ;;
      eza|bat|ripgrep|fd|jq|yazi)                    group="CLI Utilities" ;;
    esac

    if [[ -n "$group" && "$group" != "$prev_group" ]]; then
      mv_section "$group"
      prev_group="$group"
    fi

    local check_fn src_fn
    if [[ "$src" == "pacman" ]]; then
      check_fn="_pacman_installed"; src_fn="_pacman_install"
    else
      check_fn="_aur_installed"; src_fn="_aur_install"
    fi

    mv_install_pkg "$pkg" "$src" "$check_fn" "$src_fn"
  done

  echo ""
  mv_divider
  mv_success "All packages installed"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 5 — CLONE REPO
# ══════════════════════════════════════════════════════════════════════════════

_step_clone() {
  mv_step "Moonveil Repository"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    mv_warn "~/moonveil already exists — pulling latest..."
    if git -C "$INSTALL_DIR" pull --ff-only >> "$MV_LOG_FILE" 2>&1; then
      mv_success "Repository updated"
    else
      mv_warn "Fast-forward failed — using existing checkout"
    fi
  else
    mv_info "Cloning into ~/moonveil..."
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$MV_LOG_FILE" 2>&1 \
      || mv_error "Failed to clone repository."
    mv_success "Repository cloned → ~/moonveil"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 6 — BACKUP + DOTFILES
#
#  Repo layout applied:
#    dots/.config/         →  ~/.config/
#      hypr/               →  Hyprland config
#      quickshell/
#        CrescentShell/    →  QML shell (bar, launcher, control-center, etc.)
#      kitty/
#      nvim/
#      btop/
#      cava/
#      fastfetch/
#      gtk-3.0/ gtk-4.0/
#      matugen/
#      swaync/
#      wal/
#      control-center/
#
#    dots/.local/
#      bin/
#        moonveil-control-center   →  QS control-center launcher
#        walset-backend            →  matugen/pywal wallpaper setter
#      share/nvim/                 →  NvChad plugin cache (lazy/mason)
#
#    dots/shell/
#      zshrc      →  ~/.zshrc
#      p10k.zsh   →  ~/.p10k.zsh
#
#    dots/keybinds.toml  →  ~/.config/keybinds.toml
# ══════════════════════════════════════════════════════════════════════════════

_step_dotfiles() {
  mv_step "Backup & Dotfiles"

  # ── Backup ──────────────────────────────────────────────────────────────────
  mv_section "Backing up existing configs"
  mv_backup_configs "$BACKUP_DIR"

  # ── .config ─────────────────────────────────────────────────────────────────
  echo ""
  mv_section "Applying ~/.config"
  if [[ -d "${INSTALL_DIR}/dots/.config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "${INSTALL_DIR}/dots/.config/"* "$HOME/.config/"
    mv_success "~/.config applied"
  else
    mv_warn "dots/.config not found in repo — skipping"
  fi

  # ── .local ──────────────────────────────────────────────────────────────────
  mv_section "Applying ~/.local"
  if [[ -d "${INSTALL_DIR}/dots/.local" ]]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    cp -r "${INSTALL_DIR}/dots/.local/"* "$HOME/.local/"
    # Make binaries executable
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \;
    mv_success "~/.local applied  (binaries marked executable)"
  else
    mv_warn "dots/.local not found in repo — skipping"
  fi

  # ── Shell ────────────────────────────────────────────────────────────────────
  mv_section "Applying shell configs"
  local shell_dir="${INSTALL_DIR}/dots/shell"
  [[ -f "${shell_dir}/zshrc"   ]] && cp "${shell_dir}/zshrc"   "$HOME/.zshrc"    && mv_success "~/.zshrc"
  [[ -f "${shell_dir}/p10k.zsh" ]] && cp "${shell_dir}/p10k.zsh" "$HOME/.p10k.zsh" && mv_success "~/.p10k.zsh"

  # ── keybinds.toml ────────────────────────────────────────────────────────────
  if [[ -f "${INSTALL_DIR}/dots/keybinds.toml" ]]; then
    cp "${INSTALL_DIR}/dots/keybinds.toml" "$HOME/.config/keybinds.toml"
    mv_success "~/.config/keybinds.toml"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 7 — POST-INSTALL
# ══════════════════════════════════════════════════════════════════════════════

_step_post() {
  mv_step "Post-install Setup"

  # Default shell → zsh
  mv_set_shell_zsh

  # Powerlevel10k (zshrc uses p10k prompt)
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ ! -d "$p10k_dir" ]]; then
    mv_info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$p10k_dir" >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "p10k clone failed — run manually: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $p10k_dir"
    mv_success "Powerlevel10k installed"
  else
    mv_skip "Powerlevel10k already present"
  fi

  # Ensure ~/.local/bin is in PATH
  if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    mv_success "~/.local/bin added to PATH in .zshrc"
  else
    mv_skip "~/.local/bin already in PATH"
  fi

  # Services
  mv_enable_service "power-profiles-daemon"
  mv_enable_service "bluetooth"

  # Font cache
  mv_rebuild_font_cache
}

# ══════════════════════════════════════════════════════════════════════════════
#  WELCOME PROMPT
# ══════════════════════════════════════════════════════════════════════════════

_welcome() {
  echo -e "  ${WHITE}${B}What will be installed:${R}"
  echo ""
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  System update                    pacman -Syu${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Core dependencies          16     git, zsh, NetworkManager…${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  AUR helper                        yay-bin${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Hyprland + CrescentShell   55     pacman + AUR${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Moonveil dotfiles                 ~/.config  ~/.local  ~/.zshrc${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Post-install setup                zsh, p10k, fonts, services${R}"
  echo ""
  echo -e "  ${PURPLE}  Shell UI:  ${WHITE}CrescentShell (QuickShell/QML)${R}"
  echo -e "  ${GRAY}  → bar, launcher, control-center, overview, notifications — all QML${R}"
  echo -e "  ${GRAY}  → waybar and rofi are intentionally NOT installed${R}"
  echo ""
  echo -e "  ${YELLOW}  Existing configs will be backed up before anything changes.${R}"
  echo -e "  ${GRAY}  Backup  →  ${BACKUP_DIR}${R}"
  echo -e "  ${GRAY}  Log     →  ${MV_LOG_FILE}${R}"
  echo ""
  mv_divider
  echo ""
  echo -ne "  ${CYAN}${B}➜  Start Arch installation? [y/N]${R}  "
  read -r REPLY
  echo ""

  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}  Cancelled.${R}"; echo ""; exit 0
  fi
  mv_success "Starting installation — sit back! ☽"
  sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
  _welcome
  _step_update
  _step_core
  _step_aur_helper
  _step_packages
  _step_clone
  _step_dotfiles
  _step_post
  _stop_sudo_keepalive
  trap - EXIT
  mv_print_complete "$MV_VERSION" "$BACKUP_DIR" "$MV_LOG_FILE"
}

main "$@"
