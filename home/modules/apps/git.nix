# modules/apps/git.nix
{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    userName  = "oldfart-maker"; 
    userEmail = "mkburns61@yahoo.com";

    # Optional but nice defaults
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
  };
}
