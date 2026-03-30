{
  description = "Moonveil - A quiet, moonlit Hyprland environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, quickshell, matugen, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    # NixOS system config
    nixosConfigurations.moonveil = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        hyprland.nixosModules.default

        ({ pkgs, ... }: {
          programs.hyprland.enable = true;

          services.power-profiles-daemon.enable = true;
          services.upower.enable = true;
          services.networkmanager.enable = true;

          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
            nerd-fonts.geist-mono
            nerd-fonts.code-new-roman
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-emoji
            (pkgs.callPackage ./nix/libre-barcode.nix { })
          ];

          environment.systemPackages = with pkgs; [
            # Hyprland ecosystem
            xdg-desktop-portal-hyprland

            # Utilities
            grim
            slurp
            wl-clipboard
            hyprpicker
            imagemagick
            cava
            kitty
            fastfetch
            eza

            # System
            libnotify
            upower
            networkmanagerapplet

            # Apps
            nautilus
            pavucontrol

            # Theming
            lxappearance
            adw-gtk3

            # Shell tools
            zsh
            git
            curl
            wget
            unzip

            # Quickshell + Matugen
            quickshell.packages.${system}.default
            matugen.packages.${system}.default
          ];

          # Polkit
          security.polkit.enable = true;

          # Bluetooth
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;
        })

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.user = import ./nix/home.nix;
        }
      ];
    };

    # Standalone home-manager config
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./nix/home.nix
        {
          home.username = "user";
          home.homeDirectory = "/home/user";
        }
      ];
      extraSpecialArgs = {
        inherit quickshell matugen;
      };
    };

    # Dev shell for working on Moonveil
    devShells.${system}.default = pkgs.mkShell {
      name = "moonveil-dev";
      packages = with pkgs; [
        quickshell.packages.${system}.default
        matugen.packages.${system}.default
        git
        jq
      ];
      shellHook = ''
        echo "🌙 Moonveil dev shell"
        echo "Run: qs -p ~/.config/quickshell/CrescentShell/shell.qml"
      '';
    };
  };
}
