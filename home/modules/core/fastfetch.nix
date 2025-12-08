{ config, pkgs, repoPath, lib, ... }:

let
  cfgPath  = repoPath "home/data/apps/fastfetch/config.jsonc";
  logoPath = repoPath "home/data/apps/fastfetch/logo";
in
{
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile."fastfetch/config.jsonc" = {
    source = cfgPath;
    force  = true;
  };

  xdg.configFile."fastfetch/logo" = lib.mkIf (builtins.pathExists logoPath) {
    source    = logoPath;
    recursive = true;
    force     = true;
  };
}
