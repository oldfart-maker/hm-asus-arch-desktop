{ inputs, ... }:
{
  imports = [
    inputs.dms.homeModules.dankMaterialShell.default
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring=false;
  };
}
