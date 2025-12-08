{ config, pkgs, repoPath, lib, ... }:

let
  cfgPath  = repoPath "home/data/apps/wezterm/wezterm.lua";
  colorsPath = repoPath "home/data/apps/wezterm/colors";

  # Wrap wezterm to use nixGL
  weztermWrapped = pkgs.writeShellScriptBin "wezterm" ''
    export WAYLAND_DISPLAY="wayland-0"
    export WINIT_UNIX_BACKEND=wayland

    # If you have a specific nixGL variant, use it here
    exec nixGL "${pkgs.wezterm}/bin/wezterm" "$@"
  '';  
in
{
  programs.wezterm = {
    enable = true;
    package = weztermWrapped;
  };

  xdg.configFile."wezterm/wezterm.lua" = {
    source = cfgPath;
    force  = true;
  };

  xdg.configFile."wezterm/colors" = lib.mkIf (builtins.pathExists colorsPath) {
    source    = colorsPath;
    recursive = true;
    force     = true;
  };
}
