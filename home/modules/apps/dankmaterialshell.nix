{ inputs, repoPath, ... }:

let
  settingsJson =
    repoPath "home/data/apps/dankmaterialshell/settings.json";
in
{
  imports = [
    inputs.dms.homeModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;

    # nixpkgs on Arch doesn't have dgop
    enableSystemMonitoring = false;
  };

  home.file.".config/DankMaterialShell/settings.json".source =
    settingsJson;
}
