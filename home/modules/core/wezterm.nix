{ config, pkgs, repoPath, lib, ... }:

let
  cfgPath  = repoPath "home/data/apps/wezterm/wezterm.lua";
  keybindingsPath = repoPath "home/data/apps/wezterm/keybindings.lua";
  colorsPath = repoPath "home/data/apps/wezterm/colors";

  # Wrap wezterm to use nixGL
  weztermWrapped = pkgs.writeShellScriptBin "wezterm" ''
    export WINIT_UNIX_BACKEND=wayland
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

  xdg.configFile."wezterm/keybindings.lua" = {
    source = keybindingsPath;
    force  = true;
  };

  xdg.configFile."wezterm/colors" = lib.mkIf (builtins.pathExists colorsPath) {
    source    = colorsPath;
    recursive = true;
    force     = true;
  };
}
