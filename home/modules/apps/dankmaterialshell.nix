{ inputs, pkgs, repoPath, ... }:

let
  settingsJson = repoPath "home/data/apps/dankmaterialshell/settings.json";

  dmsShellAssets =
    "${inputs.dms.packages.${pkgs.system}.dms-shell}/share/quickshell/dms";

  matugenForDms = pkgs.matugen.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "InioX";
      repo  = "matugen";
      rev   = "v2.4.1";
      hash  = "sha256-USsStRd1J+yjtReWwXt8ZEnzLAp3qM/XkfVknjftd2k=";
      cargoHash = "";          
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
