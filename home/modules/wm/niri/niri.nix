{ config, lib, repoPath, ... }:

let
  cfgPath  = repoPath "home/data/apps/niri/config.kdl";
  keysPath = repoPath "home/data/apps/niri/keybindings.txt";
in
{
  # Use home.file so outputs appear under result/home-files
  home.file = {
    ".config/niri/config.kdl" = {
      force  = true;
      source = cfgPath;
    };
  }
  // lib.optionalAttrs (builtins.pathExists keysPath) {
    ".config/niri/key_bindings.txt" = {
      force  = true;
      source = keysPath;
    };
  };
}
