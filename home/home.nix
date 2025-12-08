{ config, pkgs, lib, repoPath, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;

      # explicitly allow this insecure package
      permittedInsecurePackages = [
        "ventoy-1.1.07"
      ];
    };

    overlays = [
      (import (repoPath "home/modules/apps/pacseek-overlay.nix") {
        inherit repoPath;
      })
    ];
  };
  
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "24.05";

  # keep git installed via HM from now on
  home.packages = with pkgs; [ git ];

  imports = [
    ./modules/lib/paths.nix
    
    ./modules/core/user-dirs.nix    
    ./modules/core/system-theme.nix
    ./modules/core/fonts.nix
    ./modules/core/fonts-extra.nix
    ./modules/core/foot.nix    
    ./modules/core/fish.nix
    ./modules/core/fastfetch.nix
    ./modules/core/wallpaper.nix
    ./modules/core/misc-utils.nix
    ./modules/core/rclone.nix
    ./modules/core/rclone-officesync.nix
    ./modules/core/wezterm.nix
    ./modules/core/trim-screenshots.nix

    ./modules/apps/mako.nix
    ./modules/apps/emacs.nix
    ./modules/apps/bitwarden.nix
    ./modules/apps/qutebrowser.nix
    ./modules/apps/libreoffice.nix
    ./modules/apps/dankmaterialshell.nix
    
    ./modules/wm/niri/niri.nix
    ./modules/wm/niri/niri-data.nix
    ./modules/wm/niri/waybar.nix
    ./modules/wm/niri/rofi.nix
  ];

  programs.home-manager.enable = true;  
}
