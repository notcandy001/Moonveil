#!/usr/bin/env bash
# ==============================================================================
#  get/lib/common.sh  —  Moonveil Shared Library
#
#  Sourced by every distro installer. Provides:
#    · Color constants
#    · Logging helpers (mv_info, mv_success, mv_warn, mv_error, mv_step, ...)
#    · Package install engine with live per-package display
#    · Backup / dotfile helpers
#    · Post-install helpers
#    · Completion banner
#
#  Do NOT run this file directly.
# ==============================================================================

# ── Guard against double-sourcing ─────────────────────────────────────────────
[[ -n "${_MV_COMMON_LOADED:-}" ]] && return 0
readonly _MV_COMMON_LOADED=1

# ── Colors ────────────────────────────────────────────────────────────────────
R="\e[0m"; B="\e[1m"; D="\e[2m"
PURPLE="\e[38;5;141m"; LPURPLE="\e[38;5;183m"
CYAN="\e[38;5;51m";    GREEN="\e[38;5;82m"
RED="\e[38;5;196m";    YELLOW="\e[38;5;226m"
WHITE="\e[38;5;255m";  GRAY="\e[38;5;240m"
BLUE="\e[38;5;75m"

# ── Step counter (set by each distro installer) ───────────────────────────────
MV_STEP_CURRENT=0
MV_STEP_TOTAL=0

# ── Package counters ──────────────────────────────────────────────────────────
MV_PKG_CURRENT=0
MV_PKG_TOTAL=0

# ══════════════════════════════════════════════════════════════════════════════
#  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

mv_tag()     { echo -e "  ${GRAY}[${1}]${R}  ${2}"; }
mv_info()    { mv_tag "${CYAN}${B} INFO ${R}" "$*"; }
mv_success() { mv_tag "${GREEN}${B}  OK  ${R}" "${GREEN}$*${R}"; }
mv_warn()    { mv_tag "${YELLOW}${B} WARN ${R}" "${YELLOW}$*${R}"; }
mv_skip()    { mv_tag "${GRAY}${B} SKIP ${R}" "${GRAY}$*${R}"; }

mv_error() {
  echo ""
  mv_tag "${RED}${B}ERROR${R}" "${RED}${B}$*${R}"
  echo -e "  ${GRAY}  └─ Log: ${MV_LOG_FILE:-/tmp/moonveil.log}${R}"
  echo ""
  exit 1
}

mv_divider() {
  echo -e "  ${GRAY}──────────────────────────────────────────────────────────${R}"
}

# Numbered step header
mv_step() {
  MV_STEP_CURRENT=$(( MV_STEP_CURRENT + 1 ))
  local num total
  printf -v num   "%02d" "$MV_STEP_CURRENT"
  printf -v total "%02d" "$MV_STEP_TOTAL"
  echo ""
  echo -e "  ${PURPLE}${B}┌─────────────────────────────────────────────────────┐${R}"
  echo -e "  ${PURPLE}${B}│  ${LPURPLE}Step ${num}/${total}  ${WHITE}${B}$*${R}"
  echo -e "  ${PURPLE}${B}└─────────────────────────────────────────────────────┘${R}"
  echo ""
}

# Sub-section label inside a step
mv_section() {
  echo ""
  echo -e "  ${PURPLE}  ▸  ${D}${WHITE}$*${R}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  PACKAGE DISPLAY ENGINE
# ══════════════════════════════════════════════════════════════════════════════

mv_pkg_start() {
  MV_PKG_TOTAL="$1"
  MV_PKG_CURRENT=0
  local label="${2:-packages}"
  echo ""
  echo -e "  ${GRAY}  Installing ${MV_PKG_TOTAL} ${label}...${R}"
  echo ""
  echo -e "  ${CYAN}${B}[ pacman ]${R}${GRAY}  Official repos  ${R}  ${YELLOW}${B}[  aur   ]${R}${GRAY}  AUR  ${R}  ${BLUE}${B}[  apt   ]${R}${GRAY}  Debian  ${R}  ${GREEN}${B}[  dnf   ]${R}${GRAY}  Fedora${R}"
  echo ""
  mv_divider
}

mv_pkg_show() {
  local name="$1" source="$2"
  MV_PKG_CURRENT=$(( MV_PKG_CURRENT + 1 ))
  local src_color="${CYAN}"
  case "$source" in
    aur)     src_color="${YELLOW}"  ;;
    apt)     src_color="${BLUE}"    ;;
    dnf)     src_color="${GREEN}"   ;;
    flatpak) src_color="${LPURPLE}" ;;
  esac
  printf "  ${GRAY}[${src_color}${B}%-7s${R}${GRAY}]${R}  ${GRAY}(%2d/%2d)${R}  ${WHITE}%-42s${R}\n" \
    "$source" "$MV_PKG_CURRENT" "$MV_PKG_TOTAL" "$name"
}

mv_pkg_done() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${GREEN}${B}  done  ${R}${GRAY}]${R}         ${GREEN}%-42s${R}  ${GREEN}✔${R}\n" "$1"
}

mv_pkg_skip() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${GRAY}${B}  skip  ${R}${GRAY}]${R}         ${GRAY}%-42s  already installed${R}\n" "$1"
}

mv_pkg_fail() {
  tput cuu1 2>/dev/null || true; tput el 2>/dev/null || true
  printf "  ${GRAY}[${RED}${B}  fail  ${R}${GRAY}]${R}         ${RED}%-42s  ✘ check log${R}\n" "$1"
}

# ══════════════════════════════════════════════════════════════════════════════
#  GENERIC INSTALL WRAPPER
# ══════════════════════════════════════════════════════════════════════════════

# mv_install_pkg <name> <source> <check_fn> <install_fn>
mv_install_pkg() {
  local name="$1" source="$2" check_fn="$3" install_fn="$4"
  shift 4

  mv_pkg_show "$name" "$source"

  if "$check_fn" "$name" 2>/dev/null; then
    mv_pkg_skip "$name"
    return 0
  fi

  if "$install_fn" "$name" "$@" >> "${MV_LOG_FILE:-/tmp/moonveil.log}" 2>&1; then
    mv_pkg_done "$name"
  else
    mv_pkg_fail "$name"
    mv_warn "Package '${name}' failed — continuing (check log)"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  BACKUP + DOTFILES
# ══════════════════════════════════════════════════════════════════════════════

mv_backup_configs() {
  local backup_dir="$1"
  local -a dirs=()
  [[ -d "$HOME/.config" ]] && dirs+=("$HOME/.config")
  [[ -d "$HOME/.local"  ]] && dirs+=("$HOME/.local")

  if [[ ${#dirs[@]} -eq 0 ]]; then
    mv_skip "Nothing to back up"
    return
  fi

  mkdir -p "$backup_dir"
  for d in "${dirs[@]}"; do
    local name; name=$(basename "$d")
    mv_info "  ~/.${name}  →  backup"
    cp -r "$d" "${backup_dir}/${name}" 2>/dev/null || true
  done
  mv_success "Backup: ${backup_dir}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  POST-INSTALL HELPERS
# ══════════════════════════════════════════════════════════════════════════════

mv_set_shell_zsh() {
  local zsh_bin
  zsh_bin=$(command -v zsh 2>/dev/null || true)
  if [[ -z "$zsh_bin" ]]; then
    mv_warn "zsh not found — skipping shell change"
    return
  fi
  if [[ "$SHELL" == "$zsh_bin" ]]; then
    mv_success "Default shell already zsh"
    return
  fi
  mv_info "Setting default shell → zsh"
  if chsh -s "$zsh_bin" 2>/dev/null; then
    mv_success "Default shell set to zsh"
  else
    mv_warn "chsh failed — run manually: chsh -s \$(which zsh)"
  fi
}

mv_rebuild_font_cache() {
  mv_info "Rebuilding font cache..."
  fc-cache -fv >> "${MV_LOG_FILE:-/tmp/moonveil.log}" 2>&1 || true
  mv_success "Font cache rebuilt"
}

mv_enable_service() {
  local svc="$1"
  if systemctl list-unit-files "${svc}.service" &>/dev/null; then
    mv_info "Enabling ${svc}..."
    sudo systemctl enable --now "$svc" >> "${MV_LOG_FILE:-/tmp/moonveil.log}" 2>&1 || true
    mv_success "${svc} enabled"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETION BANNER
# ══════════════════════════════════════════════════════════════════════════════

mv_print_complete() {
  local version="${1:-}"
  local backup_dir="${2:-~/.moonveil-backup}"
  local log="${3:-/tmp/moonveil.log}"

  clear
  echo ""
  echo -e "${GREEN}${B}"
  cat << "EOF"
  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██╗██╗
  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██║██║
  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██║██║
  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║██║
  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║███████╗
  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝╚══════╝
EOF
  echo -e "${R}"
  echo -e "  ${GREEN}${B}  ✔  Installation Complete!${R}  ${GRAY}☽  Moonveil v${version}${R}"
  echo ""

  echo -e "  ${PURPLE}${B}──  Locations${R}"
  echo -e "  ${GRAY}     Moonveil     ${R}  ${WHITE}~/moonveil${R}"
  echo -e "  ${GRAY}     Dotfiles     ${R}  ${WHITE}~/.config  &  ~/.local${R}"
  echo -e "  ${GRAY}     Backup       ${R}  ${WHITE}${backup_dir}${R}"
  echo -e "  ${GRAY}     Log          ${R}  ${WHITE}${log}${R}"
  echo ""

  echo -e "  ${PURPLE}${B}──  Environment${R}"
  echo -e "  ${GRAY}     Compositor  ${R}  ${WHITE}Hyprland${R}"
  echo -e "  ${GRAY}     Shell UI    ${R}  ${WHITE}CrescentShell  ${GRAY}(QuickShell/QML)${R}"
  echo -e "  ${GRAY}     Terminal    ${R}  ${WHITE}Kitty${R}"
  echo -e "  ${GRAY}     Editor      ${R}  ${WHITE}Neovim  ${GRAY}(NvChad)${R}"
  echo -e "  ${GRAY}     Theming     ${R}  ${WHITE}matugen + pywal  ${GRAY}(Material You)${R}"
  echo -e "  ${GRAY}     Notifs      ${R}  ${WHITE}swaync  ${GRAY}(via CrescentShell)${R}"
  echo ""

  echo -e "  ${PURPLE}${B}──  CrescentShell Keybinds${R}"
  echo -e "  ${GRAY}     Super + Space   ${R}  ${WHITE}App Launcher${R}"
  echo -e "  ${GRAY}     Super + A       ${R}  ${WHITE}Control Center${R}"
  echo -e "  ${GRAY}     Super + N       ${R}  ${WHITE}Notifications${R}"
  echo -e "  ${GRAY}     Super + Tab     ${R}  ${WHITE}Overview / Window Switcher${R}"
  echo -e "  ${GRAY}     Super + L       ${R}  ${WHITE}Lock Screen (hyprlock)${R}"
  echo -e "  ${GRAY}     Super + W       ${R}  ${WHITE}Wallpaper / Color Scheme${R}"
  echo -e "  ${GRAY}     Super + Return  ${R}  ${WHITE}Terminal (Kitty)${R}"
  echo -e "  ${GRAY}     Super + E       ${R}  ${WHITE}File Manager (Nautilus)${R}"
  echo ""
  echo -e "  ${GRAY}  ☽  Full keybinds: ${WHITE}~/.config/keybinds.toml${R}"
  echo ""

  mv_divider
  echo ""
  echo -e "  ${YELLOW}${B}  ⚠  Log out and select Hyprland from your display manager.${R}"
  echo -e "  ${GRAY}     Or launch with:  ${WHITE}Hyprland${R}"
  echo ""
  echo -e "  ${GRAY}  ${BLUE}https://github.com/notcandy001/Moonveil${R}  ${GRAY}· Star the repo! ⭐${R}"
  echo ""
}
