#!/usr/bin/env bash
# ==============================================================================
#  dots-extra/fedora/install.sh  —  Moonveil Fedora Installer
#
#  Called by get/install.sh when a Fedora-based distro is detected.
#  Supports: Fedora, Nobara, RHEL, AlmaLinux, Rocky
#
#  Do NOT run directly — use get/install.sh
# ==============================================================================

set -Eeuo pipefail

# ── Parse args ────────────────────────────────────────────────────────────────
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
_resolve_common_lib() {
  [[ -n "${MV_COMMON_LIB:-}" && -f "$MV_COMMON_LIB" ]] && { echo "$MV_COMMON_LIB"; return; }
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && "$src" != /tmp/* ]]; then
    local this_dir; this_dir="$(cd "$(dirname "$src")" && pwd)"
    local local_lib="${this_dir}/../../get/lib/common.sh"
    [[ -f "$local_lib" ]] && { echo "$local_lib"; return; }
  fi
  local tmp; tmp=$(mktemp /tmp/moonveil-common-XXXXXX.sh)
  if curl -fsSL \
      "https://raw.githubusercontent.com/notcandy001/Moonveil/refs/heads/master/get/lib/common.sh" \
      -o "$tmp" 2>/dev/null; then
    echo "$tmp"; return
  fi
  echo "ERROR: cannot load common.sh — pass --common-lib or check your internet" >&2
  exit 1
}
_common_lib=$(_resolve_common_lib)
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
  [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null || true
}
trap '_stop_sudo_keepalive' EXIT INT TERM

# ── Package helpers ───────────────────────────────────────────────────────────
_dnf_installed() { rpm -q "$1" &>/dev/null; }
_dnf_install()   { sudo dnf install -y "$1"; }

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 1 — SUDO + SYSTEM UPDATE
# ══════════════════════════════════════════════════════════════════════════════

_step_update() {
  mv_step "System Update"
  _start_sudo_keepalive

  mv_info "Enabling RPM Fusion repos..."
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    >> "$MV_LOG_FILE" 2>&1 || mv_warn "RPM Fusion already enabled or failed — continuing"

  mv_info "Running dnf upgrade..."
  echo ""
  sudo dnf upgrade -y
  echo ""
  mv_success "System is up to date"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 2 — CORE PACKAGES
# ══════════════════════════════════════════════════════════════════════════════

_step_core() {
  mv_step "Core Dependencies"

  local -a pkgs=(
    "@development-tools"
    git curl wget unzip
    zsh
    NetworkManager
    polkit-gnome
    fastfetch
  )

  mv_pkg_start "${#pkgs[@]}" "core packages via dnf"
  for pkg in "${pkgs[@]}"; do
    mv_install_pkg "$pkg" "dnf" _dnf_installed _dnf_install
  done

  sudo systemctl enable --now NetworkManager >> "$MV_LOG_FILE" 2>&1 || true
  mv_success "Core packages ready"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 3 — HYPRLAND + CRESCENTSHELL PACKAGES
# ══════════════════════════════════════════════════════════════════════════════

_step_packages() {
  mv_step "Moonveil Packages"

  # Copr for Hyprland on Fedora
  mv_info "Enabling solopasha/hyprland copr..."
  sudo dnf copr enable -y solopasha/hyprland >> "$MV_LOG_FILE" 2>&1 \
    || mv_warn "copr enable failed — Hyprland packages may not be available"
  sudo dnf update -y >> "$MV_LOG_FILE" 2>&1 || true

  local -a pkgs=(
    # Hyprland stack
    "hyprland|dnf"
    "xdg-desktop-portal-hyprland|dnf"
    "xdg-desktop-portal-gtk|dnf"
    "xdg-utils|dnf"
    "xwayland|dnf"
    "hyprlock|dnf"
    "hypridle|dnf"
    "hyprpaper|dnf"
    # Notifications backend
    "swaync|dnf"
    # Screenshot
    "grim|dnf"
    "slurp|dnf"
    "swappy|dnf"
    # Clipboard
    "wl-clipboard|dnf"
    "cliphist|dnf"
    # Terminal
    "kitty|dnf"
    # Editor
    "neovim|dnf"
    "luarocks|dnf"
    # File manager
    "nautilus|dnf"
    "ffmpegthumbnailer|dnf"
    "gvfs|dnf"
    "gvfs-mtp|dnf"
    # Audio
    "pipewire|dnf"
    "pipewire-alsa|dnf"
    "pipewire-pulseaudio|dnf"
    "wireplumber|dnf"
    "pavucontrol|dnf"
    "pamixer|dnf"
    "playerctl|dnf"
    "brightnessctl|dnf"
    # Bluetooth
    "bluez|dnf"
    "bluez-tools|dnf"
    "gnome-bluetooth|dnf"
    # Monitor / visualizer
    "btop|dnf"
    "cava|dnf"
    # Theming
    "ImageMagick|dnf"
    "lxappearance|dnf"
    "papirus-icon-theme|dnf"
    "libnotify|dnf"
    # Fonts
    "google-noto-fonts-common|dnf"
    "google-noto-emoji-fonts|dnf"
    "google-noto-cjk-fonts|dnf"
    # CLI
    "eza|dnf"
    "bat|dnf"
    "ripgrep|dnf"
    "fd-find|dnf"
    "jq|dnf"
    "yazi|dnf"
  )

  mv_pkg_start "${#pkgs[@]}" "Moonveil packages via dnf"

  local prev_group=""
  for entry in "${pkgs[@]}"; do
    local pkg="${entry%%|*}"; local src="${entry##*|}"
    local group=""
    case "$pkg" in
      hyprland|xdg-desktop-portal*|xdg-utils|xwayland|hyprlock|hypridle|hyprpaper) group="Hyprland Compositor" ;;
      swaync)                                   group="Notifications Backend" ;;
      grim|slurp|swappy)                        group="Screenshot" ;;
      wl-clipboard|cliphist)                    group="Clipboard" ;;
      kitty)                                    group="Terminal" ;;
      neovim|luarocks)                          group="Editor" ;;
      nautilus|ffmpegthumbnailer|gvfs*)         group="File Manager" ;;
      pipewire*|wireplumber|pavucontrol|pamixer|playerctl|brightnessctl) group="Audio & Media" ;;
      bluez*|gnome-bluetooth*)                  group="Bluetooth" ;;
      btop|cava)                                group="Monitor & Visualizer" ;;
      ImageMagick|lxappearance|papirus*|libnotify*) group="Theming" ;;
      google-noto-*)                            group="Fonts" ;;
      eza|bat|ripgrep|fd-find|jq|yazi)          group="CLI Utilities" ;;
    esac
    [[ -n "$group" && "$group" != "$prev_group" ]] && { mv_section "$group"; prev_group="$group"; }
    mv_install_pkg "$pkg" "$src" _dnf_installed _dnf_install
  done

  # QuickShell — build from source on Fedora (no copr yet)
  mv_section "CrescentShell (QuickShell — build from source)"
  if ! command -v quickshell &>/dev/null; then
    mv_info "Building QuickShell from source..."
    local qs_tmp; qs_tmp=$(mktemp -d)
    git clone https://github.com/quickshell-mirror/quickshell.git "$qs_tmp" >> "$MV_LOG_FILE" 2>&1 \
      || { mv_warn "QuickShell clone failed — install manually"; rm -rf "$qs_tmp"; }
    if [[ -d "$qs_tmp" ]]; then
      sudo dnf install -y cmake qt6-qtbase-devel qt6-qtdeclarative-devel \
        qt6-qtwayland-devel pipewire-devel >> "$MV_LOG_FILE" 2>&1 || true
      cmake -S "$qs_tmp" -B "$qs_tmp/build" -DCMAKE_BUILD_TYPE=Release >> "$MV_LOG_FILE" 2>&1
      cmake --build "$qs_tmp/build" -j"$(nproc)" >> "$MV_LOG_FILE" 2>&1
      sudo cmake --install "$qs_tmp/build" >> "$MV_LOG_FILE" 2>&1
      rm -rf "$qs_tmp"
      mv_success "QuickShell built and installed"
    fi
  else
    mv_skip "QuickShell already installed"
  fi

  # matugen via cargo
  mv_section "matugen (cargo)"
  if ! command -v matugen &>/dev/null; then
    sudo dnf install -y cargo >> "$MV_LOG_FILE" 2>&1 || true
    cargo install matugen >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "matugen install failed — run: cargo install matugen"
    mv_success "matugen installed"
  else
    mv_skip "matugen already installed"
  fi

  # pywal via pip
  mv_section "pywal (pip)"
  if ! command -v wal &>/dev/null; then
    pip3 install --user pywal >> "$MV_LOG_FILE" 2>&1 \
      || mv_warn "pywal install failed — run: pip3 install --user pywal"
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
    mv_warn "~/moonveil exists — pulling..."
    git -C "$INSTALL_DIR" pull --ff-only >> "$MV_LOG_FILE" 2>&1 \
      && mv_success "Updated" || mv_warn "Using existing checkout"
  else
    mv_info "Cloning into ~/moonveil..."
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$MV_LOG_FILE" 2>&1 \
      || mv_error "Failed to clone."
    mv_success "Cloned → ~/moonveil"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 5 — BACKUP + DOTFILES
# ══════════════════════════════════════════════════════════════════════════════

_step_dotfiles() {
  mv_step "Backup & Dotfiles"
  mv_section "Backing up"; mv_backup_configs "$BACKUP_DIR"; echo ""
  mv_section "Applying ~/.config"
  [[ -d "${INSTALL_DIR}/dots/.config" ]] \
    && { mkdir -p "$HOME/.config"; cp -r "${INSTALL_DIR}/dots/.config/"* "$HOME/.config/"; mv_success "~/.config applied"; } \
    || mv_warn "dots/.config not found"
  mv_section "Applying ~/.local"
  if [[ -d "${INSTALL_DIR}/dots/.local" ]]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    cp -r "${INSTALL_DIR}/dots/.local/"* "$HOME/.local/"
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \;
    mv_success "~/.local applied"
  else
    mv_warn "dots/.local not found"
  fi
  mv_section "Shell configs"
  local s="${INSTALL_DIR}/dots/shell"
  [[ -f "$s/zshrc"    ]] && cp "$s/zshrc"    "$HOME/.zshrc"    && mv_success "~/.zshrc"
  [[ -f "$s/p10k.zsh" ]] && cp "$s/p10k.zsh" "$HOME/.p10k.zsh" && mv_success "~/.p10k.zsh"
  [[ -f "${INSTALL_DIR}/dots/keybinds.toml" ]] \
    && cp "${INSTALL_DIR}/dots/keybinds.toml" "$HOME/.config/keybinds.toml" \
    && mv_success "~/.config/keybinds.toml"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 6 — POST-INSTALL
# ══════════════════════════════════════════════════════════════════════════════

_step_post() {
  mv_step "Post-install Setup"
  mv_set_shell_zsh
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  [[ ! -d "$p10k_dir" ]] \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >> "$MV_LOG_FILE" 2>&1 \
    && mv_success "p10k installed" || mv_skip "p10k present"
  grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null \
    || { echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"; mv_success "~/.local/bin in PATH"; }
  mv_enable_service "bluetooth"
  mv_rebuild_font_cache
}

# ══════════════════════════════════════════════════════════════════════════════
_welcome() {
  echo -e "  ${WHITE}${B}Fedora/Nobara — Moonveil installer${R}"; echo ""
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  RPM Fusion repos will be enabled${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  solopasha/hyprland copr will be enabled${R}"
  echo -e "  ${GRAY}  ${PURPLE}◆${R}${GRAY}  QuickShell built from source (no copr yet)${R}"; echo ""
  echo -e "  ${GRAY}  Backup  →  ${BACKUP_DIR}${R}"
  echo -e "  ${GRAY}  Log     →  ${MV_LOG_FILE}${R}"; echo ""
  mv_divider; echo ""
  echo -ne "  ${CYAN}${B}➜  Start Fedora installation? [y/N]${R}  "
  read -r REPLY </dev/tty; echo ""
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}  Cancelled.${R}"; exit 0
  fi
  mv_success "Starting — sit back! ☽"; sleep 0.5
}

main() {
  _welcome
  _step_update; _step_core; _step_packages
  _step_clone; _step_dotfiles; _step_post
  _stop_sudo_keepalive; trap - EXIT
  mv_print_complete "$MV_VERSION" "$BACKUP_DIR" "$MV_LOG_FILE"
}
main "$@"
