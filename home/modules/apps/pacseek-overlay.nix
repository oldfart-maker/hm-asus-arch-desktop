# home/modules/apps/pacseek-overlay.nix
{ repoPath }:
self: super: {
  pacseek = import (repoPath "home/modules/apps/pacseek.nix") {
    pkgs = super;
    lib  = super.lib;
  };
}
