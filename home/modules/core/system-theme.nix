# home/modules/system-theme.nix (only the relevant part shown)
{ config, pkgs, repoPath, lib, ... }:
{
  stylix = {
    enable = true;
    
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/chalk.yaml";
    image = repoPath "home/data/wallpapers/default.jpg";    
    polarity = "dark";

    cursor = {
      package = pkgs.qogir-icon-theme;
      name    = "Qogirr";
      size    = 12;
    };

    targets = {
      waybar = { enable = false; addCss = false; };
      rofi.enable = false;
      foot.enable = false;
      fish.enable = false;
      mako.enable = false;
    };
  };
}
