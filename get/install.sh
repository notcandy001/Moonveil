#!/usr/bin/env bash
# ==============================================================================
#
#  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██╗██╗
#  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██║██║
#  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██║██║
#  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║██║
#  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║███████╗
#  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝╚══════╝
#
# ==============================================================================

set -Eeuo pipefail

# ── Version ───────────────────────────────────────────────────────────────────
readonly MV_VERSION="1.0.0"
readonly MV_REPO="https://github.com/notcandy001/moonveil"
readonly MV_RAW="https://raw.githubusercontent.com/notcandy001/moonveil/master"

# ── Paths ─────────────────────────────────────────────────────────────────────
# When cloned locally, SCRIPT_DIR = <repo>/get/
# When piped via curl, we download everything on the fly
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Log ───────────────────────────────────────────────────────────────────────
readonly LOG_FILE="/tmp/moonveil-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ── Colors ────────────────────────────────────────────────────────────────────
R="\e[0m"; B="\e[1m"; D="\e[2m"
PURPLE="\e[38;5;141m"; LPURPLE="\e[38;5;183m"
CYAN="\e[38;5;51m";    GREEN="\e[38;5;82m"
RED="\e[38;5;196m";    YELLOW="\e[38;5;226m"
WHITE="\e[38;5;255m";  GRAY="\e[38;5;240m"
BLUE="\e[38;5;75m"

# ── Helpers ───────────────────────────────────────────────────────────────────
tag()     { echo -e "  ${GRAY}[${1}]${R}  ${2}"; }
info()    { tag "${CYAN}${B} INFO ${R}" "$*"; }
success() { tag "${GREEN}${B}  OK  ${R}" "${GREEN}$*${R}"; }
warn()    { tag "${YELLOW}${B} WARN ${R}" "${YELLOW}$*${R}"; }
error()   {
  echo ""
  tag "${RED}${B}ERROR${R}" "${RED}${B}$*${R}"
  echo -e "  ${GRAY}  └─ Log: ${LOG_FILE}${R}"
  echo ""
  exit 1
}
divider() { echo -e "  ${GRAY}──────────────────────────────────────────────────────────${R}"; }

# ── Cleanup on interrupt ──────────────────────────────────────────────────────
_cleanup() {
  echo ""
  echo -e "  ${YELLOW}${B}  Interrupted.${R}  ${GRAY}Log: ${LOG_FILE}${R}"
  echo ""
  exit 130
}
trap _cleanup INT TERM

# ══════════════════════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════════════════════

_banner() {
  clear
  echo ""
  echo -e "${PURPLE}${B}"
  cat << "EOF"
  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██╗██╗
  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██║██║
  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██║██║
  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║██║
  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║███████╗
  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝╚══════╝
EOF
  echo -e "${R}"
  echo -e "  ${LPURPLE}  A quiet, moonlit Hyprland environment${R}"
  echo -e "  ${GRAY}  ${BLUE}${MV_REPO}${R}  ${GRAY}·  v${MV_VERSION}${R}"
  echo ""
  divider
  echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  SYSTEM CHECKS
# ══════════════════════════════════════════════════════════════════════════════

_check_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    error "Do not run as root. Use your normal user account."
  fi
  success "Running as user: $(whoami)"
}

_check_internet() {
  info "Checking internet connection..."
  if ! ping -c1 -W3 github.com &>/dev/null; then
    error "No internet connection. Please connect and retry."
  fi
  success "Internet OK"
}

_check_wayland() {
  if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${XDG_SESSION_TYPE:-}" ]]; then
    warn "Could not detect Wayland session. Moonveil requires Wayland/Hyprland."
    warn "If you are in a TTY this is expected — continuing."
  else
    success "Session type: ${XDG_SESSION_TYPE:-wayland}"
  fi
}

_check_disk() {
  local free_kb free_gb
  free_kb=$(df --output=avail "$HOME" | tail -1)
  free_gb=$(( free_kb / 1024 / 1024 ))
  if [[ "$free_gb" -lt 5 ]]; then
    warn "Low disk space: ~${free_gb} GB free — 5 GB+ recommended"
  else
    success "Disk space: ~${free_gb} GB free"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  DISTRO DETECTION
# ══════════════════════════════════════════════════════════════════════════════

_detect_distro() {
  local id="" id_like=""

  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  elif command -v lsb_release &>/dev/null; then
    id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  fi

  case "$id" in
    arch|artix|cachyos|endeavouros|garuda|manjaro) echo "arch"   ;;
    debian|ubuntu|linuxmint|pop|elementary|zorin|kali|parrot|raspbian) echo "debian" ;;
    fedora|rhel|centos|almalinux|rocky|nobara)     echo "fedora" ;;
    *)
      case "$id_like" in
        *arch*)            echo "arch"   ;;
        *debian*|*ubuntu*) echo "debian" ;;
        *fedora*|*rhel*)   echo "fedora" ;;
        *)                 echo "unsupported" ;;
      esac
      ;;
  esac
}

_print_distro_info() {
  local family="$1"
  local distro_name="${PRETTY_NAME:-${NAME:-Unknown}}"

  echo -e "  ${WHITE}${B}System Information${R}"
  echo ""
  echo -e "  ${GRAY}  Distro     ${R}  ${WHITE}${distro_name}${R}"
  echo -e "  ${GRAY}  Family     ${R}  ${WHITE}${family}${R}"
  echo -e "  ${GRAY}  Kernel     ${R}  ${WHITE}$(uname -r)${R}"
  echo -e "  ${GRAY}  Arch       ${R}  ${WHITE}$(uname -m)${R}"
  echo -e "  ${GRAY}  User       ${R}  ${WHITE}$(whoami)${R}"
  echo -e "  ${GRAY}  Log        ${R}  ${WHITE}${LOG_FILE}${R}"
  echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  SCRIPT LOADER
#
#  Priority:
#    1. Local clone  →  <repo>/dots-extra/<distro>/install.sh
#    2. Remote       →  download from GitHub raw
# ══════════════════════════════════════════════════════════════════════════════

_load_distro_script() {
  local family="$1"

  # ── Try local clone first ──────────────────────────────────────────────────
  local local_path="${REPO_ROOT}/dots-extra/${family}/install.sh"
  if [[ -f "$local_path" ]]; then
    echo "$local_path"
    return 0
  fi

  # ── Download from GitHub ───────────────────────────────────────────────────
  local url="${MV_RAW}/dots-extra/${family}/install.sh"
  local tmp
  tmp=$(mktemp /tmp/moonveil-${family}-XXXXXX.sh)

  info "Downloading dots-extra/${family}/install.sh..."
  if curl -fsSL "$url" -o "$tmp" 2>/dev/null; then
    chmod +x "$tmp"

    # Also try to download common.sh alongside it
    _ensure_common_lib
    echo "$tmp"
    return 0
  fi

  error "Could not load dots-extra/${family}/install.sh (local not found, download failed)."
}

# Ensure get/lib/common.sh is available; download if needed
_ensure_common_lib() {
  local lib_local="${REPO_ROOT}/get/lib/common.sh"
  if [[ -f "$lib_local" ]]; then
    export MV_COMMON_LIB="$lib_local"
    return 0
  fi

  local lib_tmp
  lib_tmp=$(mktemp /tmp/moonveil-common-XXXXXX.sh)
  local url="${MV_RAW}/get/lib/common.sh"

  if curl -fsSL "$url" -o "$lib_tmp" 2>/dev/null; then
    export MV_COMMON_LIB="$lib_tmp"
    return 0
  fi

  error "Could not load get/lib/common.sh"
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
  _banner

  # ── System checks ───────────────────────────────────────────────────────────
  echo -e "  ${PURPLE}${B}━━  System Checks${R}"
  echo ""
  _check_root
  _check_internet
  _check_wayland
  _check_disk
  echo ""

  # ── Detect distro ───────────────────────────────────────────────────────────
  echo -e "  ${PURPLE}${B}━━  Detecting Distribution${R}"
  echo ""

  local family
  family=$(_detect_distro)

  [[ -f /etc/os-release ]] && source /etc/os-release || true
  _print_distro_info "$family"

  # ── Ensure common lib path is exported ──────────────────────────────────────
  _ensure_common_lib

  # ── Route ───────────────────────────────────────────────────────────────────
  case "$family" in

    arch)
      success "Detected: Arch-based  →  dots-extra/arch/install.sh"
      echo ""
      local script
      script=$(_load_distro_script "arch")
      exec bash "$script" \
        --log        "$LOG_FILE"     \
        --repo-root  "$REPO_ROOT"    \
        --common-lib "$MV_COMMON_LIB" \
        --version    "$MV_VERSION"
      ;;

    debian)
      success "Detected: Debian-based  →  dots-extra/debian/install.sh"
      echo ""
      local script
      script=$(_load_distro_script "debian")
      exec bash "$script" \
        --log        "$LOG_FILE"     \
        --repo-root  "$REPO_ROOT"    \
        --common-lib "$MV_COMMON_LIB" \
        --version    "$MV_VERSION"
      ;;

    fedora)
      success "Detected: Fedora-based  →  dots-extra/fedora/install.sh"
      echo ""
      local script
      script=$(_load_distro_script "fedora")
      exec bash "$script" \
        --log        "$LOG_FILE"     \
        --repo-root  "$REPO_ROOT"    \
        --common-lib "$MV_COMMON_LIB" \
        --version    "$MV_VERSION"
      ;;

    unsupported)
      echo ""
      divider
      echo ""
      echo -e "  ${RED}${B}  ✘  Unsupported distribution${R}"
      echo ""
      echo -e "  ${GRAY}  Moonveil currently supports:${R}"
      echo -e "  ${GRAY}    ${PURPLE}◆${R}${GRAY}  Arch Linux, Manjaro, EndeavourOS, CachyOS, Garuda${R}"
      echo -e "  ${GRAY}    ${PURPLE}◆${R}${GRAY}  Debian, Ubuntu, Pop!_OS, Linux Mint, Zorin${R}"
      echo -e "  ${GRAY}    ${PURPLE}◆${R}${GRAY}  Fedora, Nobara${R}"
      echo ""
      echo -e "  ${GRAY}  Request support:  ${BLUE}${MV_REPO}/issues${R}"
      echo ""
      exit 1
      ;;
  esac
}

main "$@"
