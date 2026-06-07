#!/usr/bin/env bash
# ==============================================================================
#  get/lib/common.sh  —  Shared Library
#
#  Sourced by every distro installer. Provides:
#    · Color constants & logging helpers
#    · Package install engine with live per-package display
#    · Backup / dotfile helpers
#    · Post-install helpers
#    · Completion banner
#
#  Do NOT run this file directly.
# ==============================================================================

[[ -n "${_COMMON_LOADED:-}" ]] && return 0
readonly _COMMON_LOADED=1

# === Colors ===
R="\e[0m"; B="\e[1m"; D="\e[2m"
GREEN="\e[38;5;82m";   YELLOW="\e[38;5;226m"; RED="\e[38;5;196m"
CYAN="\e[38;5;51m";    BLUE="\e[38;5;75m";    WHITE="\e[38;5;255m"
GRAY="\e[38;5;240m";   AMBER="\e[38;5;214m"

# === Step / Package counters ===
STEP_CURRENT=0
STEP_TOTAL=0
PKG_CURRENT=0
PKG_TOTAL=0

# ==============================================================================
#  LOGGING
# ==============================================================================

_tag()       { echo -e "  ${GRAY}[${1}]${R}  ${2}"; }
log_info()   { _tag "${CYAN}${B} INFO ${R}" "$*"; }
log_success(){ _tag "${GREEN}${B}  OK  ${R}" "${GREEN}$*${R}"; }
log_warn()   { _tag "${YELLOW}${B} WARN ${R}" "${YELLOW}$*${R}"; }
log_skip()   { _tag "${GRAY}${B} SKIP ${R}" "${GRAY}$*${R}"; }
log_error()  {
  echo ""
  _tag "${RED}${B}ERROR${R}" "${RED}${B}$*${R}"
  echo -e "  ${GRAY}  └─ Log: ${LOG_FILE:-/tmp/install.log}${R}"
  echo ""
  exit 1
}

log_divider() {
  echo -e "  ${GRAY}──────────────────────────────────────────────────────────${R}"
}

log_step() {
  STEP_CURRENT=$(( STEP_CURRENT + 1 ))
  local num total
  printf -v num   "%02d" "$STEP_CURRENT"
  printf -v total "%02d" "$STEP_TOTAL"
  echo ""
  echo -e "  ${AMBER}${B}┌─────────────────────────────────────────────────────┐${R}"
  echo -e "  ${AMBER}${B}│  ${CYAN}Step ${num}/${total}  ${WHITE}${B}$*${R}"
  echo -e "  ${AMBER}${B}└─────────────────────────────────────────────────────┘${R}"
  echo ""
}

log_section() {
  echo ""
  echo -e "  ${AMBER}  ▸  ${D}${WHITE}$*${R}"
}

# ==============================================================================
#  PACKAGE DISPLAY ENGINE
# ==============================================================================

pkg_start() {
  PKG_TOTAL="$1"
  PKG_CURRENT=0
  local label="${2:-packages}"
  echo ""
  echo -e "  ${GRAY}  Installing ${PKG_TOTAL} ${label}...${R}"
  echo ""
  log_divider
}

pkg_show() {
  local name="$1" source="$2"
  PKG_CURRENT=$(( PKG_CURRENT + 1 ))
  local src_color="${CYAN}"
  case "$source" in
    aur)     src_color="${YELLOW}"  ;;
    apt)     src_color="${BLUE}"    ;;
    dnf)     src_color="${GREEN}"   ;;
    flatpak) src_color="${AMBER}"   ;;
    cargo)   src_color="${RED}"     ;;
  esac
  printf "  ${GRAY}[${src_color}${B}%-7s${R}${GRAY}]${R}  ${GRAY}(%2d/%2d)${R}  ${WHITE}%-42s${R}\n" \
    "$source" "$PKG_CURRENT" "$PKG_TOTAL" "$name"
}

pkg_done() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${GREEN}${B}  done  ${R}${GRAY}]${R}         ${GREEN}%-42s${R}  ${GREEN}✔${R}\n" "$1"
}

pkg_skip() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${GRAY}${B}  skip  ${R}${GRAY}]${R}         ${GRAY}%-42s  already installed${R}\n" "$1"
}

pkg_fail() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${RED}${B}  fail  ${R}${GRAY}]${R}         ${RED}%-42s  ✘ check log${R}\n" "$1"
}

# install_pkg <name> <source> <check_fn> <install_fn> [extra args...]
install_pkg() {
  local name="$1" source="$2" check_fn="$3" install_fn="$4"
  shift 4

  pkg_show "$name" "$source"

  if "$check_fn" "$name" 2>/dev/null; then
    pkg_skip "$name"
    return 0
  fi

  if "$install_fn" "$name" "$@" >> "${LOG_FILE:-/tmp/install.log}" 2>&1; then
    pkg_done "$name"
  else
    pkg_fail "$name"
    log_warn "Package '${name}' failed — continuing (check log)"
  fi
}

# ==============================================================================
#  BACKUP + DOTFILES
# ==============================================================================

backup_configs() {
  local backup_dir="$1"
  local -a dirs=()
  [[ -d "$HOME/.config" ]] && dirs+=("$HOME/.config")
  [[ -d "$HOME/.local"  ]] && dirs+=("$HOME/.local")

  if [[ ${#dirs[@]} -eq 0 ]]; then
    log_skip "Nothing to back up"
    return
  fi

  mkdir -p "$backup_dir"
  for d in "${dirs[@]}"; do
    local name; name=$(basename "$d")
    log_info "  ~/.${name}  →  backup"
    cp -r "$d" "${backup_dir}/${name}" 2>/dev/null || true
  done
  log_success "Backup: ${backup_dir}"
}

# ==============================================================================
#  POST-INSTALL HELPERS
# ==============================================================================

set_shell_zsh() {
  local zsh_bin
  zsh_bin=$(command -v zsh 2>/dev/null || true)
  if [[ -z "$zsh_bin" ]]; then
    log_warn "zsh not found — skipping shell change"
    return
  fi
  if [[ "$SHELL" == "$zsh_bin" ]]; then
    log_success "Default shell already zsh"
    return
  fi
  log_info "Setting default shell → zsh"
  if chsh -s "$zsh_bin" 2>/dev/null; then
    log_success "Default shell set to zsh"
  else
    log_warn "chsh failed — run manually: chsh -s \$(which zsh)"
  fi
}

rebuild_font_cache() {
  log_info "Rebuilding font cache..."
  fc-cache -fv >> "${LOG_FILE:-/tmp/install.log}" 2>&1 || true
  log_success "Font cache rebuilt"
}

enable_service() {
  local svc="$1"
  if systemctl list-unit-files "${svc}.service" &>/dev/null; then
    log_info "Enabling ${svc}..."
    sudo systemctl enable --now "$svc" >> "${LOG_FILE:-/tmp/install.log}" 2>&1 || true
    log_success "${svc} enabled"
  fi
}

configure_services() {
  if has_cmd systemctl; then
    if systemctl is-enabled --quiet iwd 2>/dev/null || systemctl is-active --quiet iwd 2>/dev/null; then
      log_warn "Disabling iwd (conflicts with NetworkManager)..."
      sudo systemctl stop iwd
      sudo systemctl disable iwd
    fi
    enable_service "NetworkManager"
    enable_service "bluetooth"
    enable_service "power-profiles-daemon"

  elif has_cmd rc-service; then
    log_info "Configuring OpenRC services..."
    rc-update show | grep -q "iwd" && {
      sudo rc-service iwd stop 2>/dev/null || true
      sudo rc-update del iwd default 2>/dev/null || true
    }
    sudo rc-update add NetworkManager default 2>/dev/null || true
    sudo rc-service NetworkManager start 2>/dev/null || true
    sudo rc-update add bluetooth default 2>/dev/null || true
    sudo rc-service bluetooth start 2>/dev/null || true

  elif has_cmd sv; then
    log_info "Configuring runit services..."
    local SV_DIR="/var/service"
    [[ -L "$SV_DIR/iwd" ]] && sudo rm "$SV_DIR/iwd"
    [[ -d "/etc/sv/NetworkManager" && ! -L "$SV_DIR/NetworkManager" ]] && sudo ln -s /etc/sv/NetworkManager "$SV_DIR/"
    [[ -d "/etc/sv/bluetooth"     && ! -L "$SV_DIR/bluetooth"      ]] && sudo ln -s /etc/sv/bluetooth "$SV_DIR/"
  else
    log_warn "Unknown init system. Enable NetworkManager and Bluetooth manually."
  fi
}

# ==============================================================================
#  COMPLETION BANNER
# ==============================================================================

print_complete() {
  local version="${1:-}" backup_dir="${2:-~/.backup}" log="${3:-/tmp/install.log}"

  clear
  echo ""
  echo -e "${AMBER}${B}"
  cat << "EOF"
  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██╗██╗
  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██║██║
  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██║██║
  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║██║
  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║███████╗
  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝╚══════╝
EOF
  echo -e "${R}"
  echo -e "  ${GREEN}${B}  ✔  Installation Complete!${R}  ${GRAY}v${version}${R}"
  echo ""
  echo -e "  ${AMBER}${B}──  Locations${R}"
  echo -e "  ${GRAY}     Dotfiles     ${R}  ${WHITE}~/moonveil${R}"
  echo -e "  ${GRAY}     Config       ${R}  ${WHITE}~/.config  &  ~/.local${R}"
  echo -e "  ${GRAY}     Backup       ${R}  ${WHITE}${backup_dir}${R}"
  echo -e "  ${GRAY}     Log          ${R}  ${WHITE}${log}${R}"
  echo ""
  echo -e "  ${AMBER}${B}──  Stack${R}"
  echo -e "  ${GRAY}     Compositor  ${R}  ${WHITE}Hyprland${R}"
  echo -e "  ${GRAY}     Shell UI    ${R}  ${WHITE}QuickShell (QML)${R}"
  echo -e "  ${GRAY}     Terminal    ${R}  ${WHITE}Kitty${R}"
  echo -e "  ${GRAY}     Editor      ${R}  ${WHITE}Neovim${R}"
  echo -e "  ${GRAY}     Theming     ${R}  ${WHITE}matugen + pywal${R}"
  echo -e "  ${GRAY}     Notifs      ${R}  ${WHITE}swaync${R}"
  echo ""
  echo -e "  ${AMBER}${B}──  Keybinds${R}"
  echo -e "  ${GRAY}     Super + Space   ${R}  ${WHITE}App Launcher${R}"
  echo -e "  ${GRAY}     Super + A       ${R}  ${WHITE}Control Center${R}"
  echo -e "  ${GRAY}     Super + N       ${R}  ${WHITE}Notifications${R}"
  echo -e "  ${GRAY}     Super + Tab     ${R}  ${WHITE}Overview${R}"
  echo -e "  ${GRAY}     Super + L       ${R}  ${WHITE}Lock Screen${R}"
  echo -e "  ${GRAY}     Super + W       ${R}  ${WHITE}Wallpaper / Theme${R}"
  echo -e "  ${GRAY}     Super + Return  ${R}  ${WHITE}Terminal (Kitty)${R}"
  echo -e "  ${GRAY}     Super + E       ${R}  ${WHITE}File Manager (Nautilus)${R}"
  echo ""
  log_divider
  echo ""
  echo -e "  ${YELLOW}${B}  ⚠  Log out and select Hyprland from your display manager.${R}"
  echo -e "  ${GRAY}     Or launch with:  ${WHITE}Hyprland${R}"
  echo ""
  echo -e "  ${GRAY}  ${BLUE}https://github.com/notcandy001/Moonveil${R}  ${GRAY}· Star the repo! ⭐${R}"
  echo ""
}
