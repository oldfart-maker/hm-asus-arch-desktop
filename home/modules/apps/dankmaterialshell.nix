{ inputs, pkgs, repoPath, ... }:

let
  settingsJson =
    repoPath "home/data/apps/dankmaterialshell/settings.json";

  dmsShellAssets =
    "${inputs.dms.packages.${pkgs.system}.dms-shell}/share/quickshell/dms";
in
{
  imports = [
    inputs.dms.homeModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = false;
  };

  # Force DMS to use system matugen (3.1.0 from pacman)
#  systemd.user.services.dms = {
#    Service = {
#      Environment = [
#        "PATH=/usr/bin:/run/current-system/sw/bin"
#      ];
#    };
#  };

#  home.file.".config/DankMaterialShell/settings.json".source =
#    settingsJson;

#  home.file.".config/quickshell/dms".source =
#    dmsShellAssets;
}
