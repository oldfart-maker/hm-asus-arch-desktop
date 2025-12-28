{ inputs, pkgs, repoPath, ... }:

let
  settingsJson = repoPath "home/data/apps/dankmaterialshell/settings.json";

  dmsShellAssets =
    "${inputs.dms.packages.${pkgs.system}.dms-shell}/share/quickshell/dms";

  matugenForDms = pkgs.matugen.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "InioX";
      repo  = "matugen";
      rev   = "HEAD";
      hash  = "sha256-USsStRd1J+yjtReWwXt8ZEnzLAp3qM/XkfVknjftd2k=";
    };
  });
    
in
{
  home.packages = [
    matugenForDms
  ];
  
  imports = [
    inputs.dms.homeModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = false;
  };

  home.file.".config/DankMaterialShell/settings.json".source = settingsJson;
  home.file.".config/quickshell/dms".source = dmsShellAssets;
}
