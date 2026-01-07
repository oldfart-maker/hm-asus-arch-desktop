{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    vesktop
    element-desktop
    spotify
  ];
}
