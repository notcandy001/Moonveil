{ config, pkgs, lib, ... }:

{
  home.stateVersion = "24.11";

  # Link all dotfiles
  home.file = {
    # Hyprland
    ".config/hypr".source = ../dots/.config/hypr;

    # CrescentShell
    ".config/quickshell/CrescentShell".source = ../dots/.config/quickshell/CrescentShell;

    # Kitty
    ".config/kitty".source = ../dots/.config/kitty;

    # Matugen
    ".config/matugen".source = ../dots/.config/matugen;

    # Cava
    ".config/cava".source = ../dots/.config/cava;

    # btop
    ".config/btop".source = ../dots/.config/btop;

    # fastfetch
    ".config/fastfetch".source = ../dots/.config/fastfetch;

    # GTK
    ".config/gtk-3.0".source = ../dots/.config/gtk-3.0;
    ".config/gtk-4.0".source = ../dots/.config/gtk-4.0;

    # Local bins
    ".local/bin/walset".source = ../dots/.local/bin/walset;
    ".local/bin/walset-backend".source = ../dots/.local/bin/walset-backend;
    ".local/bin/moonveil-control-center".source = ../dots/.local/bin/moonveil-control-center;

    # Shell
    ".zshrc".source = ../dots/shell/zshrc;
    ".p10k.zsh".source = ../dots/shell/p10k.zsh;
  };

  # Make local bins executable
  home.activation.makeScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    chmod +x $HOME/.local/bin/walset || true
    chmod +x $HOME/.local/bin/walset-backend || true
    chmod +x $HOME/.local/bin/moonveil-control-center || true
  '';

  # Cursor theme
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # GTK theme
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # ZSH
  programs.zsh = {
    enable = true;
    initExtra = ''
      source ~/.p10k.zsh
    '';
  };

  # Font config
  fonts.fontconfig.enable = true;
}
