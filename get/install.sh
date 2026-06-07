#!/usr/bin/env bash
set -e

# ==============================================================================
#  get/install.sh  —  Entry Point
#
#  https://github.com/notcandy001/Moonveil
#
#  Detects your distro and hands off to dots-extra/arch/install.sh
# ==============================================================================

# === Configuration ===
readonly VERSION="1.0.0"
readonly REPO_URL="https://github.com/notcandy001/Moonveil.git"
readonly RAW_URL="https://raw.githubusercontent.com/notcandy001/Moonveil/refs/heads/master"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

readonly LOG_FILE="/tmp/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# === Colors ===
GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ  $1${NC}" >&2; }
log_success() { echo -e "${GREEN}✔  $1${NC}" >&2; }
log_warn()    { echo -e "${YELLOW}⚠  $1${NC}" >&2; }
log_error()   { echo -e "${RED}✖  $1${NC}" >&2; echo -e "  Log: ${LOG_FILE}" >&2; exit 1; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

_cleanup() { echo -e "\n  ${YELLOW}Interrupted.${NC}  Log: ${LOG_FILE}\n"; exit 130; }
trap _cleanup INT TERM

[[ "$EUID" -eq 0 ]] && log_error "Do not run as root. Use your normal user account."

# === Distro Detection ===
detect_distro() {
  local id="" id_like=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  elif has_cmd lsb_release; then
    id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  fi

  case "$id" in
    arch|artix|cachyos|endeavouros|garuda|manjaro) echo "arch" && return ;;
    *)
      case "$id_like" in
        *arch*) echo "arch" && return ;;
      esac
      ;;
  esac

  has_cmd pacman && echo "arch" && return
  echo "unsupported"
}

# === System Checks ===
check_system() {
  log_info "Checking internet connection..."
  ping -c1 -W3 github.com &>/dev/null || log_error "No internet connection. Please connect and retry."
  log_success "Internet OK"

  if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${XDG_SESSION_TYPE:-}" ]]; then
    log_warn "Could not detect Wayland session — if you are in a TTY this is expected."
  else
    log_success "Session type: ${XDG_SESSION_TYPE:-wayland}"
  fi

  local free_kb free_gb
  free_kb=$(df --output=avail "$HOME" | tail -1)
  free_gb=$(( free_kb / 1024 / 1024 ))
  if [[ "$free_gb" -lt 5 ]]; then
    log_warn "Low disk space: ~${free_gb} GB free — 5 GB+ recommended"
  else
    log_success "Disk space: ~${free_gb} GB free"
  fi
}

# === Common Lib Loader ===
ensure_common_lib() {
  local lib_local="${REPO_ROOT}/get/lib/common.sh"
  if [[ -f "$lib_local" ]]; then
    export COMMON_LIB="$lib_local"
    return 0
  fi

  local lib_tmp
  lib_tmp=$(mktemp /tmp/install-common-XXXXXX.sh)
  log_info "Downloading get/lib/common.sh..."
  if curl -fsSL "${RAW_URL}/get/lib/common.sh" -o "$lib_tmp" 2>/dev/null; then
    export COMMON_LIB="$lib_tmp"
    return 0
  fi

  log_error "Could not download get/lib/common.sh — check your internet connection."
}

# === Distro Script Loader ===
load_arch_script() {
  local local_path="${REPO_ROOT}/dots-extra/arch/install.sh"
  if [[ -f "$local_path" ]]; then
    echo "$local_path"
    return 0
  fi

  local tmp
  tmp=$(mktemp "/tmp/install-arch-XXXXXX.sh")
  log_info "Downloading dots-extra/arch/install.sh..."
  if curl -fsSL "${RAW_URL}/dots-extra/arch/install.sh" -o "$tmp" 2>/dev/null; then
    chmod +x "$tmp"
    echo "$tmp"
    return 0
  fi

  log_error "Could not download dots-extra/arch/install.sh — log: ${LOG_FILE}"
}

# === Main ===
main() {
  echo ""
  log_info "Installer  v${VERSION}"
  log_info "Log: ${LOG_FILE}"
  echo ""

  check_system

  local family
  family=$(detect_distro)

  case "$family" in
    arch)
      log_success "Detected: Arch-based"
      ;;
    unsupported)
      log_error "Unsupported distribution. Only Arch-based distros are supported (Arch, Manjaro, EndeavourOS, CachyOS, Garuda, Artix)."
      ;;
  esac

  ensure_common_lib

  local script
  script=$(load_arch_script)

  exec bash "$script" \
    --log        "$LOG_FILE"   \
    --repo-root  "$REPO_ROOT"  \
    --common-lib "$COMMON_LIB" \
    --version    "$VERSION"
}

main "$@"
