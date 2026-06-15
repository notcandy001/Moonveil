#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  Moonveil — Installer Entry Point
#  https://github.com/notcandy001/Moonveil
# ==============================================================================

REPO_URL="https://github.com/notcandy001/Moonveil.git"
INSTALL_PATH="$HOME/.local/src/moonveil"
BIN_DIR="/usr/local/bin"
VERSION="1.0.0"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m' BLUE='\033[0;34m' CYAN='\033[0;36m'
YELLOW='\033[1;33m' RED='\033[0;31m' PURPLE='\033[0;35m'
BOLD='\033[1m' NC='\033[0m'

info()    { echo -e "${BLUE}ℹ  $1${NC}"; }
success() { echo -e "${GREEN}✔  $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠  $1${NC}"; }
error()   { echo -e "${RED}✖  $1${NC}" >&2; exit 1; }
step()    { echo -e "\n${PURPLE}${BOLD}══  $1${NC}\n"; }
divider() { echo -e "${CYAN}────────────────────────────────────────────────────${NC}"; }

has_cmd()   { command -v "$1" >/dev/null 2>&1; }
has_font()  { fc-list 2>/dev/null | grep -qi "$1"; }
has_theme() { [[ -d "/usr/share/themes/$1" || -d "$HOME/.themes/$1" ]]; }

[[ "$EUID" -eq 0 ]] && error "Do not run as root. Use your normal user account."

# ── Interrupt handler ─────────────────────────────────────────────────────────
trap 'echo -e "\n${YELLOW}Interrupted.${NC}"; exit 130' INT TERM

# ── Log ───────────────────────────────────────────────────────────────────────
LOG="/tmp/moonveil-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
info "Log: $LOG"

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${PURPLE}${BOLD}"
cat << 'EOF'
  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██╗██╗
  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██║██║
  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██║██║
  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║██║
  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║███████╗
  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝╚══════╝
EOF
echo -e "${NC}"
echo -e "  ${CYAN}A moonlit Hyprland environment powered by CrescentShell${NC}"
echo -e "  ${BLUE}https://github.com/notcandy001/Moonveil${NC}  ·  v${VERSION}"
echo ""
divider
echo ""

# ── Distro detection ──────────────────────────────────────────────────────────
detect_distro() {
  local id="" id_like=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  fi
  case "$id" in
    arch|artix|cachyos|endeavouros|garuda|manjaro) echo "arch"   ; return ;;
    debian|ubuntu|linuxmint|pop|elementary|zorin)  echo "debian" ; return ;;
    fedora|rhel|nobara|centos|almalinux)           echo "fedora" ; return ;;
  esac
  case "$id_like" in
    *arch*)             echo "arch"   ; return ;;
    *debian*|*ubuntu*)  echo "debian" ; return ;;
    *fedora*|*rhel*)    echo "fedora" ; return ;;
  esac
  echo "unknown"
}

DISTRO=$(detect_distro)
info "Detected distro family: ${DISTRO}"

# ── Package filtering — skip what's already installed ────────────────────────
# Maps package name → binary to check
declare -A BINARY_CHECK=(
  ["quickshell"]="qs"
  ["matugen"]="matugen"
  ["kitty"]="kitty"
  ["tmux"]="tmux"
  ["fuzzel"]="fuzzel"
  ["brightnessctl"]="brightnessctl"
  ["grim"]="grim"
  ["slurp"]="slurp"
  ["jq"]="jq"
  ["playerctl"]="playerctl"
  ["wtype"]="wtype"
  ["mpvpaper"]="mpvpaper"
  ["zenity"]="zenity"
  ["ddcutil"]="ddcutil"
  ["swaync"]="swaync"
  ["hyprlock"]="hyprlock"
  ["hypridle"]="hypridle"
  ["hyprpaper"]="hyprpaper"
  ["go"]="go"
)

declare -A THEME_CHECK=(
  ["adw-gtk-theme"]="adw-gtk3"
  ["adw-gtk3-theme"]="adw-gtk3"
)

declare -A FONT_CHECK=(
  ["ttf-phosphor-icons"]="Phosphor"
)

filter_packages() {
  local pkgs=("$@")
  local needed=()
  for pkg in "${pkgs[@]}"; do
    local skip=0
    if [[ -n "${BINARY_CHECK[$pkg]:-}" ]] && has_cmd "${BINARY_CHECK[$pkg]}"; then
      info "  skip  $pkg  (${BINARY_CHECK[$pkg]} found)"
      skip=1
    elif [[ -n "${THEME_CHECK[$pkg]:-}" ]] && has_theme "${THEME_CHECK[$pkg]}"; then
      info "  skip  $pkg  (theme found)"
      skip=1
    elif [[ -n "${FONT_CHECK[$pkg]:-}" ]] && has_font "${FONT_CHECK[$pkg]}"; then
      info "  skip  $pkg  (font found)"
      skip=1
    fi
    [[ $skip -eq 0 ]] && needed+=("$pkg")
  done
  echo "${needed[@]:-}"
}

# ── Dependencies ──────────────────────────────────────────────────────────────
install_dependencies() {
  step "Installing Dependencies"

  case "$DISTRO" in
    arch)
      if ! has_cmd git || ! has_cmd makepkg; then
        info "Installing git + base-devel…"
        sudo pacman -S --needed --noconfirm git base-devel
      fi

      AUR_HELPER=""
      if has_cmd yay; then AUR_HELPER="yay"
      elif has_cmd paru; then AUR_HELPER="paru"
      else
        info "Installing yay…"
        local ytmp; ytmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$ytmp"
        (cd "$ytmp" && makepkg -si --noconfirm)
        rm -rf "$ytmp"
        AUR_HELPER="yay"
      fi

      local PKGS=(
        hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland
        quickshell kitty tmux fuzzel swaync
        pipewire wireplumber pavucontrol playerctl
        qt6-base qt6-declarative qt6-wayland qt6-svg qt6-tools
        qt6-imageformats qt6-multimedia qt6-shadertools
        syntax-highlighting breeze-icons hicolor-icon-theme
        matugen brightnessctl ddcutil grim slurp imagemagick
        jq sqlite upower wl-clipboard wlsunset wtype
        zenity libnotify go
        ttf-roboto ttf-roboto-mono ttf-dejavu ttf-liberation
        noto-fonts noto-fonts-cjk noto-fonts-emoji
        ttf-nerd-fonts-symbols ttf-phosphor-icons
        adw-gtk-theme mpvpaper
      )

      local FILTERED
      # shellcheck disable=SC2207
      FILTERED=($(filter_packages "${PKGS[@]}"))
      if [[ ${#FILTERED[@]} -gt 0 ]]; then
        info "Installing with ${AUR_HELPER}…"
        $AUR_HELPER -S --needed --noconfirm "${FILTERED[@]}"
      else
        success "All packages already installed"
      fi
      ;;

    fedora)
      info "Enabling COPR repositories…"
      sudo dnf install -y dnf-plugins-core
      yes | sudo dnf copr enable errornointernet/quickshell  || true
      yes | sudo dnf copr enable solopasha/hyprland          || true

      local PKGS=(
        hyprland hyprlock hypridle hyprpaper
        quickshell kitty tmux fuzzel swaync
        pipewire wireplumber easyeffects playerctl
        qt6-qtbase qt6-qtdeclarative qt6-qtwayland qt6-qtsvg qt6-qttools
        qt6-qtimageformats qt6-qtmultimedia qt6-qtshadertools
        kf6-syntax-highlighting kf6-breeze-icons hicolor-icon-theme
        matugen brightnessctl ddcutil grim slurp ImageMagick jq sqlite upower
        wl-clipboard wlsunset wtype zenity libnotify golang
        google-roboto-fonts google-roboto-mono-fonts dejavu-sans-fonts
        google-noto-fonts-common google-noto-cjk-fonts google-noto-emoji-fonts
        adw-gtk3-theme mpvpaper unzip curl
      )

      local FILTERED
      # shellcheck disable=SC2207
      FILTERED=($(filter_packages "${PKGS[@]}"))
      if [[ ${#FILTERED[@]} -gt 0 ]]; then
        info "Installing with dnf…"
        sudo dnf install -y --best --allowerasing \
          --setopt=install_weak_deps=False "${FILTERED[@]}"
      else
        success "All packages already installed"
      fi

      install_phosphor_fonts
      ;;

    debian)
      sudo apt-get update -qq

      local PKGS=(
        kitty tmux grim slurp brightnessctl
        jq sqlite3 upower wl-clipboard wtype
        zenity libnotify-bin golang
        fonts-roboto fonts-dejavu fonts-liberation fonts-noto
        adw-gtk3-theme
      )

      local FILTERED
      # shellcheck disable=SC2207
      FILTERED=($(filter_packages "${PKGS[@]}"))
      if [[ ${#FILTERED[@]} -gt 0 ]]; then
        info "Installing with apt…"
        sudo apt-get install -y "${FILTERED[@]}"
      fi

      # These need to be built/installed separately on Debian
      install_phosphor_fonts
      warn "Note: quickshell, hyprland, matugen may need to be installed manually on Debian-based systems."
      warn "See: https://wiki.hyprland.org/Getting-Started/Installation/"
      ;;

    *)
      warn "Unsupported distro '${DISTRO}' — skipping package installation."
      warn "Install dependencies manually. See the README."
      ;;
  esac

  success "Dependencies done"
}

install_phosphor_fonts() {
  has_font "Phosphor" && return
  info "Installing Phosphor Icons font…"
  local VERSION="2.1.2"
  local tmp; tmp="$(mktemp -d)"
  local FONT_DIR="$HOME/.local/share/fonts/phosphor"
  curl -sL "https://github.com/phosphor-icons/web/archive/refs/tags/v${VERSION}.zip" \
    -o "$tmp/phosphor.zip"
  unzip -q "$tmp/phosphor.zip" -d "$tmp"
  mkdir -p "$FONT_DIR"
  find "$tmp" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
  rm -rf "$tmp"
  fc-cache -f "$FONT_DIR"
  success "Phosphor Icons installed"
}

# ── rodctl ────────────────────────────────────────────────────────────────────
install_rodctl() {
  step "Installing rodctl"
  if has_cmd rodctl; then
    success "rodctl already installed — skipping"
    return
  fi
  info "Running rodctl installer…"
  curl -fsSL "https://raw.githubusercontent.com/notcandy001/rodctl/main/install.sh" | bash
  success "rodctl installed"
}

# ── Migration from old paths ──────────────────────────────────────────────────
migrate_old_paths() {
  info "Checking for legacy Moonveil paths…"

  # Old install location → new
  local OLD_SRC="$HOME/Moonveil"
  if [[ -d "$OLD_SRC" && ! -d "$INSTALL_PATH" ]]; then
    info "Migrating source: $OLD_SRC → $INSTALL_PATH"
    mkdir -p "$(dirname "$INSTALL_PATH")"
    cp -r "$OLD_SRC" "$INSTALL_PATH"
  fi

  # Config
  local OLD_CONFIG="$HOME/.config/Moonveil"
  local NEW_CONFIG="$HOME/.config/moonveil"
  if [[ -d "$OLD_CONFIG" && ! -d "$NEW_CONFIG" ]]; then
    info "Migrating config: $OLD_CONFIG → $NEW_CONFIG"
    mv "$OLD_CONFIG" "$NEW_CONFIG"
  fi

  # State
  local OLD_STATE="$HOME/.local/state/Moonveil"
  local NEW_STATE="$HOME/.local/state/moonveil"
  if [[ -d "$OLD_STATE" && ! -d "$NEW_STATE" ]]; then
    info "Migrating state: $OLD_STATE → $NEW_STATE"
    mv "$OLD_STATE" "$NEW_STATE"
  fi

  # Cache
  local OLD_CACHE="$HOME/.cache/Moonveil"
  local NEW_CACHE="$HOME/.cache/moonveil"
  if [[ -d "$OLD_CACHE" && ! -d "$NEW_CACHE" ]]; then
    info "Migrating cache: $OLD_CACHE → $NEW_CACHE"
    mv "$OLD_CACHE" "$NEW_CACHE"
  fi
}

# ── Repo setup ────────────────────────────────────────────────────────────────
setup_repo() {
  step "Setting Up Repository"

  if [[ ! -d "$INSTALL_PATH" ]]; then
    info "Cloning Moonveil to $INSTALL_PATH…"
    mkdir -p "$(dirname "$INSTALL_PATH")"
    git clone "$REPO_URL" "$INSTALL_PATH"
    success "Cloned"
    return
  fi

  if [[ ! -d "$INSTALL_PATH/.git" ]]; then
    warn "$INSTALL_PATH exists but is not a git repo — re-initializing…"
    local tmp; tmp="$(mktemp -d)"
    find "$INSTALL_PATH" -mindepth 1 -maxdepth 1 -exec mv -t "$tmp" {} +
    rm -rf "$INSTALL_PATH"
    git clone "$REPO_URL" "$INSTALL_PATH"
    cp -rn "$tmp"/. "$INSTALL_PATH/" 2>/dev/null || true
    rm -rf "$tmp"
    success "Re-initialized"
    return
  fi

  info "Checking for updates…"
  git -C "$INSTALL_PATH" fetch origin

  local BRANCH
  BRANCH=$(git -C "$INSTALL_PATH" rev-parse --abbrev-ref HEAD)

  if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
    warn "On branch '$BRANCH' — skipping auto-update."
    return
  fi

  local HAS_CHANGES=0
  [[ -n "$(git -C "$INSTALL_PATH" status --porcelain)" ]]          && HAS_CHANGES=1
  [[ -n "$(git -C "$INSTALL_PATH" log origin/${BRANCH}..HEAD)" ]]  && HAS_CHANGES=1

  if [[ "$HAS_CHANGES" -eq 1 ]]; then
    echo -e "${YELLOW}⚠  Local changes detected. This will discard them.${NC}"
    read -r -p "Continue? [y/N] " response </dev/tty
    [[ ! "$response" =~ ^[Yy]$ ]] && { warn "Update aborted."; return; }
  fi

  git -C "$INSTALL_PATH" reset --hard "origin/${BRANCH}"
  success "Repository up to date"
}

# ── Dotfile installation ──────────────────────────────────────────────────────
install_dotfiles() {
  step "Installing Dotfiles"

  local DOTS_SRC="$INSTALL_PATH/dots"
  if [[ ! -d "$DOTS_SRC" ]]; then
    warn "dots/ directory not found in $INSTALL_PATH — skipping dotfile install"
    return
  fi

  # Backup existing configs
  local BACKUP_DIR="$HOME/.moonveil-backup-$(date +%Y%m%d-%H%M%S)"
  info "Backing up existing configs to $BACKUP_DIR…"
  mkdir -p "$BACKUP_DIR"
  for dir in .config .local; do
    [[ -d "$HOME/$dir" ]] && cp -r "$HOME/$dir" "$BACKUP_DIR/$dir" 2>/dev/null || true
  done
  success "Backup saved: $BACKUP_DIR"

  info "Copying dotfiles…"
  cp -r "$DOTS_SRC/." "$HOME/"
  success "Dotfiles installed"
}

# ── Services ──────────────────────────────────────────────────────────────────
configure_services() {
  step "Configuring Services"

  if has_cmd systemctl; then
    # Disable iwd if present (conflicts with NetworkManager)
    if systemctl is-enabled --quiet iwd 2>/dev/null || \
       systemctl is-active  --quiet iwd 2>/dev/null; then
      warn "Disabling iwd (conflicts with NetworkManager)…"
      sudo systemctl stop iwd    2>/dev/null || true
      sudo systemctl disable iwd 2>/dev/null || true
    fi

    for svc in NetworkManager bluetooth power-profiles-daemon; do
      if systemctl list-unit-files "${svc}.service" &>/dev/null; then
        systemctl is-enabled --quiet "$svc" 2>/dev/null || {
          info "Enabling ${svc}…"
          sudo systemctl enable --now "$svc" || true
        }
      fi
    done
    success "Services configured"

  elif has_cmd rc-update; then
    for svc in NetworkManager bluetooth; do
      sudo rc-update add "$svc" default 2>/dev/null || true
      sudo rc-service "$svc" start      2>/dev/null || true
    done
    success "OpenRC services configured"

  else
    warn "Unknown init system — please enable NetworkManager and Bluetooth manually."
  fi
}

# ── matugen templates ─────────────────────────────────────────────────────────
setup_matugen() {
  step "Setting Up Matugen"
  has_cmd matugen || { warn "matugen not found — skipping template setup"; return; }

  # Create the ~/.config/matugen directory structure if needed
  mkdir -p "$HOME/.config/matugen/templates"

  # The templates are already installed via dotfiles step.
  # Run a first-pass generation if a wallpaper exists.
  local WALL=""
  for path in \
    "$HOME/.local/share/moonveil/wallpapers" \
    "$HOME/Pictures/wallpapers" \
    "$HOME/Pictures"; do
    WALL="$(find "$path" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | head -1 || true)"
    [[ -n "$WALL" ]] && break
  done

  if [[ -n "$WALL" ]]; then
    info "Generating initial color scheme from: $WALL"
    matugen image "$WALL" >> "$LOG" 2>&1 || warn "matugen failed — run manually after boot"
    success "Colors generated"
  else
    warn "No wallpaper found — run 'rodctl theme <image>' after setup to generate colors"
  fi
}

# ── Launcher ──────────────────────────────────────────────────────────────────
setup_launcher() {
  step "Creating Launcher"

  # Remove old user-local launcher if present
  [[ -f "$HOME/.local/bin/moonveil" ]] && rm -f "$HOME/.local/bin/moonveil"

  local LAUNCHER="$BIN_DIR/moonveil"
  info "Creating launcher at $LAUNCHER…"

  sudo tee "$LAUNCHER" >/dev/null << LAUNCHEREOF
#!/usr/bin/env bash
# Moonveil launcher — starts CrescentShell via quickshell
export PATH="\$HOME/.local/bin:\$PATH"
export QML2_IMPORT_PATH="\$HOME/.local/lib/qml:\${QML2_IMPORT_PATH:-}"
export QML_IMPORT_PATH="\$QML2_IMPORT_PATH"

case "\${1:-start}" in
  start)
    # Start rodctl daemon first (CrescentShell requires it)
    if ! rodctl status 2>/dev/null; then
      rodctl daemon &
      sleep 0.5
    fi
    exec quickshell --config "\$HOME/.config/quickshell/CrescentShell"
    ;;
  stop)
    pkill -f "quickshell.*CrescentShell" 2>/dev/null || true
    pkill rodctl 2>/dev/null || true
    ;;
  reload)
    rodctl reload
    ;;
  status)
    rodctl status
    ;;
  *)
    echo "Usage: moonveil [start|stop|reload|status]"
    ;;
esac
LAUNCHEREOF

  sudo chmod +x "$LAUNCHER"
  success "Launcher created: $LAUNCHER"
}

# ── Completion banner ─────────────────────────────────────────────────────────
print_complete() {
  echo ""
  echo -e "${GREEN}${BOLD}"
  cat << 'EOF'
  ┌─────────────────────────────────────────────────────┐
  │            ✔  Installation Complete!                │
  └─────────────────────────────────────────────────────┘
EOF
  echo -e "${NC}"

  echo -e "  ${PURPLE}${BOLD}──  Locations${NC}"
  echo -e "  ${CYAN}     Source      ${NC}  ${INSTALL_PATH}"
  echo -e "  ${CYAN}     Dotfiles    ${NC}  ~/.config  &  ~/.local"
  echo -e "  ${CYAN}     Log         ${NC}  ${LOG}"
  echo ""

  echo -e "  ${PURPLE}${BOLD}──  Stack${NC}"
  echo -e "  ${CYAN}     Compositor  ${NC}  Hyprland"
  echo -e "  ${CYAN}     Shell UI    ${NC}  CrescentShell (QuickShell / QML)"
  echo -e "  ${CYAN}     Controller  ${NC}  rodctl (daemon + CLI)"
  echo -e "  ${CYAN}     Terminal    ${NC}  Kitty"
  echo -e "  ${CYAN}     Theming     ${NC}  matugen  (Material You)"
  echo -e "  ${CYAN}     Notifs      ${NC}  swaync"
  echo ""

  echo -e "  ${PURPLE}${BOLD}──  Key Binds${NC}"
  echo -e "  ${CYAN}     Super + Space   ${NC}  App Launcher"
  echo -e "  ${CYAN}     Super + A       ${NC}  Sidebar / Control Center"
  echo -e "  ${CYAN}     Super + Tab     ${NC}  Overview / Workspaces"
  echo -e "  ${CYAN}     Super + L       ${NC}  Lock Screen"
  echo -e "  ${CYAN}     Super + W       ${NC}  Wallpaper Selector"
  echo -e "  ${CYAN}     Super + Return  ${NC}  Terminal (Kitty)"
  echo ""

  echo -e "  ${PURPLE}${BOLD}──  Getting Started${NC}"
  echo -e "  ${CYAN}     1.  ${NC}Log out and select Hyprland from your display manager"
  echo -e "  ${CYAN}     2.  ${NC}Or run:  ${BOLD}Hyprland${NC}"
  echo -e "  ${CYAN}     3.  ${NC}rodctl daemon starts automatically with CrescentShell"
  echo -e "  ${CYAN}     4.  ${NC}Set a wallpaper:  ${BOLD}rodctl theme ~/path/to/image.jpg${NC}"
  echo ""
  divider
  echo ""
  echo -e "  ${BLUE}https://github.com/notcandy001/Moonveil${NC}  ·  ⭐ Star the repo!"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  # Pre-flight checks
  step "Pre-flight Checks"
  has_cmd curl || error "curl is required. Install it and retry."
  has_cmd git  || error "git is required. Install it and retry."
  if ! ping -c1 -W3 github.com &>/dev/null; then
    error "No internet connection. Please connect and retry."
  fi
  success "Pre-flight OK"

  migrate_old_paths
  install_dependencies
  install_rodctl
  setup_repo
  install_dotfiles
  configure_services
  setup_matugen
  setup_launcher
  print_complete
}

main "$@"
