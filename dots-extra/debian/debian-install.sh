#!/usr/bin/env bash
# ==============================================================================
#  dots-extra/debian/install.sh  —  Moonveil Debian/Ubuntu Installer
#
#  Supports: Debian, Ubuntu, Pop!_OS, Linux Mint, Zorin, Elementary
#
#  NOTE: Hyprland on Debian/Ubuntu requires Ubuntu 24.04+ or Debian Trixie+.
#        A compatible kernel (6.1+) is strongly recommended.
#
#  Do NOT run directly — use get/install.sh
# ==============================================================================

set -Eeuo pipefail

# ── Parse args passed by get/install.sh ──────────────────────────────────────
MV_LOG_FILE="/tmp/moonveil.log"
MV_REPO_ROOT=""
MV_COMMON_LIB=""
MV_VERSION="1.0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)        MV_LOG_FILE="$2";   shift 2 ;;
    --repo-root)  MV_REPO_ROOT="$2";  shift 2 ;;
    --common-lib) MV_COMMON_LIB="$2"; shift 2 ;;
    --version)    MV_VERSION="$2";    shift 2 ;;
    *) shift ;;
  esac
done

export MV_LOG_FILE MV_REPO_ROOT MV_COMMON_LIB MV_VERSION

# ── Load shared library ───────────────────────────────────────────────────────
_resolve_common_lib() {
  # 1. Passed explicitly
  if [[ -n "${MV_COMMON_LIB:-}" && -f "$MV_COMMON_LIB" ]]; then
    echo "$MV_COMMON_LIB"; return 0
  fi

  # 2. Local repo — skip when running from a downloaded tmp file
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && "$src" != /tmp/* ]]; then
    local this_dir
    this_dir="$(cd "$(dirname "$src")" && pwd)"
    local local_lib="${this_dir}/../../get/lib/common.sh"
    if [[ -f "$local_lib" ]]; then
      echo "$local_lib"; return 0
    fi
  fi

  # 3. Download
  local tmp
  tmp=$(mktemp /tmp/moonveil-common-XXXXXX.sh)
  if curl -fsSL \
      "https://raw.githubusercontent.com/notcandy001/Moonveil/refs/heads/master/get/lib/common.sh" \
      -o "$tmp" 2>/dev/null; then
    echo "$tmp"; return 0
  fi

  echo "ERROR: cannot load common.sh — pass --common-lib or check your internet" >&2
  exit 1
}

_common_lib=$(_resolve_common_lib)
# shellcheck source=../../get/lib/common.sh
source "$_common_lib"

# ── Paths ─────────────────────────────────────────────────────────────────────
readonly REPO_URL="https://github.com/notcandy001/Moonveil.git"
readonly INSTALL_DIR="$HOME/moonveil"
readonly BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"

MV_STEP_TOTAL=6

# ── Sudo keepalive ────────────────────────────────────────────────────────────
SUDO_PID=""
_start_sudo_keepalive() {
  sudo -v || mv_error "Sudo authentication failed."
  ( while true; do sudo -n true; sleep 50; done ) &
  SUDO_PID=$!
}
_stop_sudo_keepalive() {
  [[ -n "${SUDO_PID:-}" ]] && kill "$SUDO_PID" 2>/dev/null || true
}
trap '_stop_sudo_keepalive' EXIT INT TERM

# ── Package helpers ───────────────────────────────────────────────────────────
_apt_installed() { dpkg -s "$1" &>/dev/null; }
_apt_install()   { sudo apt-get install -y "$1"; }

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 1 — SUDO + SYSTEM UPDATE
# ══════════════════════════════════════════════════════════════════════════════

_step_update() {
  mv_step "System Update"
  _start_sudo_keepalive
  mv_info "Running apt update && upgrade..."
  echo ""
  sudo apt-get update && sudo apt-get upgrade -y
  echo ""
  mv_success "System is up to date"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 2 — CORE PACKAGES
# ══════════════════════════════════════════════════════════════════════════════

_step_core() {
  mv_step "Core Dependencies"

  local -a pkgs=(
    build-essential git curl wget unzip
    zsh
    network-manager
    policykit-1-gnome
    fastfetch
  )

  mv_pkg_start "${#pkgs[@]}" "core packages via apt"
  for pkg in "${pkgs[@]}"; do
    mv_install_pkg "$pkg" "apt" _apt_installed _apt_install
  done

  echo ""
  sudo systemctl enable --now NetworkManager >> "$MV_LOG_FILE" 2>&1 || true
  mv_success "Core packages ready"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 3 — HYPRLAND + CRESCENTSHELL PACKAGES
# ══════════════════════════════════════════════════════════════════════════════

_step_packages() {
  mv_step "Moonveil Packages"

  mv_info "Adding Hyprland PPA (Ubuntu-based only)..."
  if command -v add-apt-repository &>/dev/null; then
    sudo add-apt-repository -y ppa:hyprland-ubuntu/hyprland >> "$MV_LOG_FILE" 2>&1 || true
    sudo apt-get update >> "$MV_LOG_FILE" 2>&1 || true
  fi

  local -a pkgs=(
    # Hyprland stack
    "hyprland|apt"
    "xdg-desktop-portal-hyprland|apt"
    "xdg-desktop-portal-gtk|apt"
    "xdg-utils|apt"
    "xwayland|apt"
    "hyprlock|apt"
    "hypridle|apt"
    "hyprpaper|apt"
    # Notifications backend
    "swaync|apt"
    # Screenshot
    "grim|apt"
    "slurp|apt"
    "swappy|apt"
    # Clipboard
    "wl-clipboard|apt"
    "cliphist|apt"
    # Terminal
    "kitty|apt"
    # Editor
    "neovim|apt"
    "luarocks|apt"
    # File manager
    "nautilus|apt"
    "ffmpegthumbnailer|apt"
    "gvfs|apt"
    "gvfs-mtp|apt"
    # Audio
    "pipewire|apt"
    "pipewire-alsa|apt"
    "pipewire-pulse|apt"
    "wireplumber|apt"
    "pavucontrol|apt"
    "pamixer|apt"
    "playerctl|apt"
    "brightnessctl|apt"
    # Bluetooth
    "bluez|apt"
    "bluez-tools|apt"
    "gnome-bluetooth-3|apt"
    # Monitor + visualizer
    "btop|apt"
    "cava|apt"
    # Theming
    "imagemagick|apt"
    "nwg-look|apt"
    "lxappearance|apt"
    "papirus-icon-theme|apt"
    "libnotify-bin|apt"
    # Fonts
    "fonts-noto|apt"
    "fonts-noto-cjk|apt"
    "fonts-noto-color-emoji|apt"
    # CLI
    "eza|apt"
    "bat|apt"
    "ripgrep|apt"
    "fd-find|apt"
    "jq|apt"
    "yazi|apt"
  )

  mv_pkg_start "${#pkgs[@]}" "Moonveil packages via apt"

  local prev_group=""
  for entry in "${pkgs[@]}"; do
    local pkg="${entry%%|*}"
    local src="${entry##*|}"
    local group=""

    case "$pkg" in
      hyprland|xdg-desktop-portal*|xdg-utils|xwayland|hyprlock|hypridle|hyprpaper)
                                                         group="Hyprland Compositor" ;;
      swaync)                                            group="Notifications Backend" ;;
      grim|slurp|swappy)                                 group="Screenshot" ;;
      wl-clipboard|cliphist)                             group="Clipboard" ;;
      kitty)                                             group="Terminal" ;;
      neovim|luarocks)                                   group="Editor" ;;
      nautilus|ffmpegthumbnailer|gvfs*)                  group="File Manager" ;;
      pipewire*|wireplumber|pavucontrol|pamixer|playerctl|brightnessctl)
                                                         group="Audio & Media" ;;
      bluez*|gnome-bluetooth*)                           group="Bluetooth" ;;
      btop|cava)                                         group="Monitor & Visualizer" ;;
      imagemagick|nwg-look|lxappearance|papirus*|libnotify*)
                                                         group="Theming" ;;
      fonts-*)                                           group="Fonts" ;;
      eza|bat|ripgrep|fd-find|jq|yazi)                   group="CLI Utilities" ;;
    esac

    if [[ -n "$group" && "$group" != "$prev_group" ]]; then
      mv_section "$group"
      prev_group="$group"
    fi

    mv_install_pkg "$pkg" "$src" _apt_installed _apt_install
  done

  # matugen — cargo (no apt package)
  mv_section "matugen (cargo)"
  if ! command -v matugen &>/dev/null; then
    if ! command -v cargo &>/dev/null; then
      mv_info "Installing Rust toolchain..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y >> "$MV_LOG_FILE" 2>&1 || mv_warn "Rust install failed"
      # shellcheck source=/dev/null
      source "$HOME/.cargo/env" 2>/dev/null || true
    fi
    cargo install matugen >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "matugen install failed — run manually: cargo install matugen"
    mv_success "matugen installed"
  else
    mv_skip "matugen already installed"
  fi

  # pywal — pip
  mv_section "pywal (pip)"
  if ! command -v wal &>/dev/null; then
    pip3 install --user pywal >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "pywal install failed — run manually: pip3 install --user pywal"
    mv_success "pywal installed"
  else
    mv_skip "pywal already installed"
  fi

  echo ""
  mv_divider
  mv_success "All packages installed"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 4 — CLONE REPO
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
#  STEP 5 — BACKUP + DOTFILES
# ══════════════════════════════════════════════════════════════════════════════

_step_dotfiles() {
  mv_step "Backup & Dotfiles"

  mv_section "Backing up existing configs"
  mv_backup_configs "$BACKUP_DIR"

  echo ""
  mv_section "Applying ~/.config"
  if [[ -d "${INSTALL_DIR}/dots/.config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "${INSTALL_DIR}/dots/.config/"* "$HOME/.config/"
    mv_success "~/.config applied"
  else
    mv_warn "dots/.config not found in repo — skipping"
  fi

  mv_section "Applying ~/.local"
  if [[ -d "${INSTALL_DIR}/dots/.local" ]]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    cp -r "${INSTALL_DIR}/dots/.local/"* "$HOME/.local/"
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \;
    mv_success "~/.local applied  (binaries marked executable)"
  else
    mv_warn "dots/.local not found in repo — skipping"
  fi

  mv_section "Applying shell configs"
  local shell_dir="${INSTALL_DIR}/dots/shell"
  [[ -f "${shell_dir}/zshrc"    ]] && cp "${shell_dir}/zshrc"    "$HOME/.zshrc"    && mv_success "~/.zshrc"
  [[ -f "${shell_dir}/p10k.zsh" ]] && cp "${shell_dir}/p10k.zsh" "$HOME/.p10k.zsh" && mv_success "~/.p10k.zsh"

  if [[ -f "${INSTALL_DIR}/dots/keybinds.toml" ]]; then
    cp "${INSTALL_DIR}/dots/keybinds.toml" "$HOME/.config/keybinds.toml"
    mv_success "~/.config/keybinds.toml"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 6 — POST-INSTALL
# ══════════════════════════════════════════════════════════════════════════════

_step_post() {
  mv_step "Post-install Setup"

  mv_set_shell_zsh

  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ ! -d "$p10k_dir" ]]; then
    mv_info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$p10k_dir" >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "p10k clone failed — run manually later"
    mv_success "Powerlevel10k installed"
  else
    mv_skip "Powerlevel10k already present"
  fi

  if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    mv_success "~/.local/bin added to PATH in .zshrc"
  else
    mv_skip "~/.local/bin already in PATH"
  fi

  mv_enable_service "bluetooth"
  mv_rebuild_font_cache
}

# ══════════════════════════════════════════════════════════════════════════════
#  WELCOME PROMPT
# ══════════════════════════════════════════════════════════════════════════════

_welcome() {
  echo -e "  ${WHITE}${B}Debian/Ubuntu — Moonveil installer${R}"
  echo ""
  echo -e "  ${YELLOW}  Note: Hyprland requires Ubuntu 24.04+ or Debian Trixie+${R}"
  echo -e "  ${GRAY}  A kernel 6.1+ is strongly recommended.${R}"
  echo ""
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  System update + Hyprland PPA${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Core dependencies + all Moonveil packages via apt${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  matugen (cargo)  +  pywal (pip)${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Moonveil dotfiles  →  ~/.config  ~/.local  ~/.zshrc${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  Post-install setup: zsh, p10k, fonts, services${R}"
  echo ""
  echo -e "  ${YELLOW}  Existing configs will be backed up before anything changes.${R}"
  echo -e "  ${GRAY}  Backup  →  ${BACKUP_DIR}${R}"
  echo -e "  ${GRAY}  Log     →  ${MV_LOG_FILE}${R}"
  echo ""
  mv_divider
  echo ""
  echo -ne "  ${CYAN}${B}➜  Start Debian installation? [y/N]${R}  "
  read -r REPLY </dev/tty
  echo ""

  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}  Cancelled.${R}"
    echo ""
    exit 0
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
  _step_packages
  _step_clone
  _step_dotfiles
  _step_post
  _stop_sudo_keepalive
  trap - EXIT
  mv_print_complete "$MV_VERSION" "$BACKUP_DIR" "$MV_LOG_FILE"
}

main "$@"
