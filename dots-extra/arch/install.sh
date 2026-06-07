#!/usr/bin/env bash
# Arch Linux installer — use get/install.sh to run this

set -Eeuo pipefail

# === Parse args ===
LOG_FILE="/tmp/install.log"
REPO_ROOT=""
COMMON_LIB=""
VERSION="1.0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)        LOG_FILE="$2";   shift 2 ;;
    --repo-root)  REPO_ROOT="$2";  shift 2 ;;
    --common-lib) COMMON_LIB="$2"; shift 2 ;;
    --version)    VERSION="$2";    shift 2 ;;
    *) shift ;;
  esac
done

export LOG_FILE REPO_ROOT COMMON_LIB VERSION

# === Load shared library ===
_resolve_common_lib() {
  if [[ -n "${COMMON_LIB:-}" && -f "$COMMON_LIB" ]]; then
    echo "$COMMON_LIB"; return 0
  fi
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && "$src" != /tmp/* ]]; then
    local local_lib
    local_lib="$(cd "$(dirname "$src")" && pwd)/../../get/lib/common.sh"
    [[ -f "$local_lib" ]] && echo "$local_lib" && return 0
  fi
  local tmp
  tmp=$(mktemp /tmp/install-common-XXXXXX.sh)
  curl -fsSL \
    "https://raw.githubusercontent.com/notcandy001/Moonveil/refs/heads/master/get/lib/common.sh" \
    -o "$tmp" 2>/dev/null && echo "$tmp" && return 0
  echo "ERROR: cannot load common.sh" >&2; exit 1
}

# shellcheck source=../../get/lib/common.sh
source "$(_resolve_common_lib)"

# === Paths ===
readonly REPO_URL="https://github.com/notcandy001/Moonveil.git"
readonly REPO_NAME="Moonveil"
readonly INSTALL_DIR="$HOME/.local/src/${REPO_NAME}"
readonly BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"

STEP_TOTAL=7

# === Sudo keepalive ===
SUDO_PID=""
_start_sudo_keepalive() {
  sudo -v || log_error "Sudo authentication failed."
  ( while true; do sudo -n true; sleep 50; done ) &
  SUDO_PID=$!
}
_stop_sudo_keepalive() {
  [[ -n "${SUDO_PID:-}" ]] && kill "$SUDO_PID" 2>/dev/null || true
}
trap '_stop_sudo_keepalive' EXIT INT TERM

# === Package helpers ===
has_cmd()        { command -v "$1" >/dev/null 2>&1; }
has_theme()      { [[ -d "/usr/share/themes/$1" ]] || [[ -d "$HOME/.themes/$1" ]]; }
has_font()       { fc-list 2>/dev/null | grep -qi "$1"; }
_pac_installed() { pacman -Qi "$1" &>/dev/null; }
_pac_install()   { sudo pacman -S --needed --noconfirm "$1"; }
_aur_installed() { pacman -Qi "$1" &>/dev/null; }
_aur_install()   { yay -S --needed --noconfirm --removemake --cleanafter "$1"; }

declare -A BINARY_CHECK=(
  ["quickshell-git"]="qs"
  ["kitty"]="kitty"
  ["brightnessctl"]="brightnessctl"
  ["ddcutil"]="ddcutil"
  ["grim"]="grim"
  ["slurp"]="slurp"
  ["jq"]="jq"
  ["playerctl"]="playerctl"
  ["matugen"]="matugen"
  ["btop"]="btop"
  ["neovim"]="nvim"
  ["yazi"]="yazi"
  ["eza"]="eza"
  ["bat"]="bat"
  ["ripgrep"]="rg"
)

declare -A THEME_CHECK=(
  ["adw-gtk3"]="adw-gtk3"
)

_should_skip() {
  local pkg="$1"
  if [[ -n "${BINARY_CHECK[$pkg]:-}" ]] && has_cmd "${BINARY_CHECK[$pkg]}"; then return 0; fi
  if [[ -n "${THEME_CHECK[$pkg]:-}" ]] && has_theme "${THEME_CHECK[$pkg]}"; then return 0; fi
  return 1
}

# === STEP 1 — SYSTEM UPDATE ===

_step_update() {
  log_step "System Update"
  log_info "Requesting sudo..."
  _start_sudo_keepalive
  log_success "Sudo active"
  log_info "Running pacman -Syu..."
  echo ""
  sudo pacman -Syu --noconfirm
  echo ""
  log_success "System is up to date"
}

# === STEP 2 — CORE PACKAGES ===

_step_core() {
  log_step "Core Dependencies"

  local -a pkgs=(
    base-devel git curl wget unzip
    zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
    networkmanager network-manager-applet nm-connection-editor
    power-profiles-daemon upower
    fastfetch polkit-gnome
  )

  pkg_start "${#pkgs[@]}" "core packages via pacman"
  for pkg in "${pkgs[@]}"; do
    install_pkg "$pkg" "pacman" _pac_installed _pac_install
  done

  echo ""
  log_info "Enabling NetworkManager..."
  sudo systemctl enable --now NetworkManager >> "$LOG_FILE" 2>&1 || true
  log_success "Core packages ready"
}

# === STEP 3 — AUR HELPER ===

_step_aur_helper() {
  log_step "AUR Helper (yay)"

  if has_cmd yay; then
    log_success "yay already installed — $(yay --version | head -1)"
    return
  fi

  log_info "Cloning yay-bin..."
  local tmp; tmp=$(mktemp -d)
  git clone "https://aur.archlinux.org/yay-bin.git" "$tmp/yay" >> "$LOG_FILE" 2>&1 \
    || { rm -rf "$tmp"; log_error "Failed to clone yay."; }

  log_info "Building with makepkg..."
  pushd "$tmp/yay" > /dev/null
  makepkg -si --noconfirm >> "$LOG_FILE" 2>&1 \
    || { popd > /dev/null; rm -rf "$tmp"; log_error "Failed to build yay."; }
  popd > /dev/null
  rm -rf "$tmp"

  log_success "yay installed — $(yay --version | head -1)"
}

# === STEP 4 — PACKAGES ===

_step_packages() {
  log_step "Dependencies"

  local -a pkgs=(
    "hyprland|pacman"
    "xdg-desktop-portal-hyprland|pacman"
    "xdg-desktop-portal-gtk|pacman"
    "xdg-utils|pacman"
    "xwayland|pacman"
    "hyprlock|pacman"
    "hypridle|pacman"
    "hyprpaper|pacman"
    "quickshell-git|aur"
    "swaync|aur"
    "grim|pacman"
    "slurp|pacman"
    "swappy|pacman"
    "wl-clipboard|pacman"
    "cliphist|pacman"
    "hyprpicker|aur"
    "kitty|pacman"
    "neovim|pacman"
    "luarocks|pacman"
    "stylua|pacman"
    "nautilus|pacman"
    "ffmpegthumbnailer|pacman"
    "gvfs|pacman"
    "gvfs-mtp|pacman"
    "pipewire|pacman"
    "pipewire-alsa|pacman"
    "pipewire-pulse|pacman"
    "wireplumber|pacman"
    "pavucontrol|pacman"
    "pamixer|pacman"
    "playerctl|pacman"
    "brightnessctl|pacman"
    "bluez|pacman"
    "bluez-utils|pacman"
    "gnome-bluetooth-3.0|pacman"
    "btop|pacman"
    "cava|pacman"
    "matugen|aur"
    "python-pywal|aur"
    "imagemagick|pacman"
    "adw-gtk3|aur"
    "bibata-cursor-theme|aur"
    "nwg-look|pacman"
    "papirus-icon-theme|pacman"
    "lxappearance|pacman"
    "libnotify|pacman"
    "ttf-jetbrains-mono-nerd|pacman"
    "ttf-nerd-fonts-symbols|pacman"
    "noto-fonts|pacman"
    "noto-fonts-cjk|pacman"
    "noto-fonts-emoji|pacman"
    "otf-font-awesome|pacman"
    "eza|pacman"
    "bat|pacman"
    "ripgrep|pacman"
    "fd|pacman"
    "jq|pacman"
    "yazi|pacman"
  )

  pkg_start "${#pkgs[@]}" "packages"

  local prev_group=""
  for entry in "${pkgs[@]}"; do
    local pkg="${entry%%|*}"
    local src="${entry##*|}"
    local group=""

    case "$pkg" in
      hyprland|xdg-desktop-portal*|xdg-utils|xwayland|hyprlock|hypridle|hyprpaper)
                                                   group="Hyprland" ;;
      quickshell*)                                 group="QuickShell" ;;
      swaync)                                      group="Notifications" ;;
      grim|slurp|swappy)                           group="Screenshot" ;;
      wl-clipboard|cliphist|hyprpicker)            group="Clipboard" ;;
      kitty)                                       group="Terminal" ;;
      neovim|luarocks|stylua)                      group="Editor" ;;
      nautilus|ffmpegthumbnailer|gvfs*)            group="File Manager" ;;
      pipewire*|wireplumber|pavucontrol|pamixer)   group="Audio" ;;
      playerctl|brightnessctl)                     group="Media & Brightness" ;;
      bluez*|gnome-bluetooth*)                     group="Bluetooth" ;;
      btop|cava)                                   group="Monitor" ;;
      matugen|python-pywal|imagemagick|adw-gtk*|bibata*|nwg-look|papirus*|lxappearance|libnotify)
                                                   group="Theming" ;;
      ttf-*|noto-*|otf-*)                          group="Fonts" ;;
      eza|bat|ripgrep|fd|jq|yazi)                  group="CLI Utilities" ;;
    esac

    if [[ -n "$group" && "$group" != "$prev_group" ]]; then
      log_section "$group"
      prev_group="$group"
    fi

    local check_fn src_fn
    if [[ "$src" == "pacman" ]]; then
      check_fn="_pac_installed"; src_fn="_pac_install"
    else
      check_fn="_aur_installed"; src_fn="_aur_install"
    fi

    if _should_skip "$pkg"; then
      pkg_show "$pkg" "$src"
      pkg_skip "$pkg"
    else
      install_pkg "$pkg" "$src" "$check_fn" "$src_fn"
    fi
  done

  echo ""
  log_divider
  log_success "All packages installed"
}

# === STEP 5 — CLONE REPO ===

_step_clone() {
  log_step "Repository"

  mkdir -p "$(dirname "$INSTALL_DIR")"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    log_info "Checking repository status..."
    git -C "$INSTALL_DIR" fetch origin

    local BRANCH
    BRANCH=$(git -C "$INSTALL_DIR" rev-parse --abbrev-ref HEAD)

    if [[ "$BRANCH" != "master" && "$BRANCH" != "main" ]]; then
      log_warn "On branch '$BRANCH' — skipping update."
      return
    fi

    local HAS_CHANGES=0
    [[ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]] && HAS_CHANGES=1
    [[ -n "$(git -C "$INSTALL_DIR" log "origin/${BRANCH}..HEAD" 2>/dev/null)" ]] && HAS_CHANGES=1

    if [[ "$HAS_CHANGES" -eq 1 ]]; then
      log_warn "Local changes detected — this will DISCARD them."
      echo -ne "  Continue? [y/N]  "
      read -r REPLY </dev/tty
      [[ ! "$REPLY" =~ ^[Yy]$ ]] && { log_warn "Update aborted."; return; }
      git -C "$INSTALL_DIR" reset --hard "origin/${BRANCH}" >> "$LOG_FILE" 2>&1
    else
      git -C "$INSTALL_DIR" pull --ff-only >> "$LOG_FILE" 2>&1 || true
    fi

    log_success "Repository updated → ${INSTALL_DIR}"
    return
  fi

  if [[ -d "$INSTALL_DIR" ]]; then
    log_warn "$INSTALL_DIR exists but is not a git repo — re-initializing..."
    local tmp_dir; tmp_dir=$(mktemp -d)
    find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -exec mv -t "$tmp_dir" {} +
    rm -rf "$INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1 \
      || log_error "Failed to clone repository."
    cp -rn "$tmp_dir"/* "$INSTALL_DIR/" 2>/dev/null || true
    rm -rf "$tmp_dir"
  else
    log_info "Cloning into ${INSTALL_DIR}..."
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1 \
      || log_error "Failed to clone repository."
  fi

  log_success "Repository ready → ${INSTALL_DIR}"
}

# === STEP 6 — BACKUP + DOTFILES ===

_step_dotfiles() {
  log_step "Backup & Dotfiles"

  log_section "Backing up existing configs"
  backup_configs "$BACKUP_DIR"

  echo ""
  log_section "Applying ~/.config"
  if [[ -d "${INSTALL_DIR}/dots/.config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "${INSTALL_DIR}/dots/.config/"* "$HOME/.config/"
    log_success "~/.config applied"
  else
    log_warn "dots/.config not found — skipping"
  fi

  log_section "Applying ~/.local"
  if [[ -d "${INSTALL_DIR}/dots/.local" ]]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    cp -r "${INSTALL_DIR}/dots/.local/"* "$HOME/.local/"
    find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \;
    log_success "~/.local applied"
  else
    log_warn "dots/.local not found — skipping"
  fi

  log_section "Applying shell configs"
  local shell_dir="${INSTALL_DIR}/dots/shell"
  [[ -f "${shell_dir}/zshrc"    ]] && cp "${shell_dir}/zshrc"    "$HOME/.zshrc"    && log_success "~/.zshrc"
  [[ -f "${shell_dir}/p10k.zsh" ]] && cp "${shell_dir}/p10k.zsh" "$HOME/.p10k.zsh" && log_success "~/.p10k.zsh"
  [[ -f "${INSTALL_DIR}/dots/keybinds.toml" ]] && \
    cp "${INSTALL_DIR}/dots/keybinds.toml" "$HOME/.config/keybinds.toml" && \
    log_success "~/.config/keybinds.toml"
}

# === STEP 7 — POST-INSTALL ===

_step_post() {
  log_step "Post-install Setup"

  set_shell_zsh

  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ ! -d "$p10k_dir" ]]; then
    log_info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$p10k_dir" >> "$LOG_FILE" 2>&1 \
      || log_warn "p10k clone failed — run manually later"
    log_success "Powerlevel10k installed"
  else
    log_skip "Powerlevel10k already present"
  fi

  if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    log_success "~/.local/bin added to PATH"
  else
    log_skip "~/.local/bin already in PATH"
  fi

  configure_services
  rebuild_font_cache
}

# === WELCOME ===

_welcome() {
  echo -e "  ${WHITE}${B}Arch Linux installer${R}"
  echo ""
  echo -e "  ${GRAY}  ◆  System update                    pacman -Syu${R}"
  echo -e "  ${GRAY}  ◆  Core dependencies                git, zsh, NetworkManager...${R}"
  echo -e "  ${GRAY}  ◆  AUR helper                       yay-bin${R}"
  echo -e "  ${GRAY}  ◆  Hyprland + QuickShell            pacman + AUR${R}"
  echo -e "  ${GRAY}  ◆  Dotfiles                         ~/.config  ~/.local  ~/.zshrc${R}"
  echo -e "  ${GRAY}  ◆  Post-install                     zsh, p10k, fonts, services${R}"
  echo ""
  echo -e "  ${GRAY}  Repo  →  ${WHITE}${INSTALL_DIR}${R}"
  echo -e "  ${YELLOW}  Existing configs will be backed up before anything changes.${R}"
  echo -e "  ${GRAY}  Backup  →  ${BACKUP_DIR}${R}"
  echo -e "  ${GRAY}  Log     →  ${LOG_FILE}${R}"
  echo ""
  log_divider
  echo ""
  echo -ne "  ${CYAN}${B}➜  Start installation? [y/N]${R}  "
  read -r REPLY </dev/tty
  echo ""
  [[ ! "$REPLY" =~ ^[Yy]$ ]] && { echo -e "  ${YELLOW}  Cancelled.${R}"; echo ""; exit 0; }
  log_success "Starting installation..."
  sleep 0.5
}

# === MAIN ===

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
  print_complete "$VERSION" "$BACKUP_DIR" "$LOG_FILE"
}

main "$@"
