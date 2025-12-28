{ inputs, ... }:
{
  imports = [
    inputs.dms.homeModules.dankMaterialShell.default
  ];

  programs.dankMaterialShell = {
    enable = true;

    # Pick ONE startup method:
    systemd.enable = true;  # simplest, compositor-agnostic
  };
}
