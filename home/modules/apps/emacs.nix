# home/modules/apps/emacs/default.nix
{ self, config, pkgs, lib, ... }:

let
  emacsPkg = (pkgs.emacs30-pgtk or pkgs.emacs29-pgtk or pkgs.emacs-gtk or pkgs.emacs);
  # emacsPkg =  (pkgs.emacs30 or pkgs.emacs29 or pkgs.emacs-gtk or pkgs.emacs);  

  emacsSrcDir    = self + "/home/data/apps/emacs";
  srcEarly       = emacsSrcDir + "/early-init.el";
  srcInit        = emacsSrcDir + "/init.el";
  srcModules     = emacsSrcDir + "/modules"; 
  emacsDir       = "${config.xdg.configHome}/emacs-prod";
  emacsCommonDir = "${config.xdg.configHome}/emacs-common";

  # sys-secrets location on the TARGET (synced in target-setup.sh)
  secretsRoot   = "${config.home.homeDirectory}/projects/sys-secrets";
  apiKeysSource = "${secretsRoot}/emacs/api-keys.el";
  mkSecret    = config.lib.file.mkOutOfStoreSymlink;  
in
{
  home.packages = [ emacsPkg ];

  # keep-emacs-common dir present
  home.file."${emacsCommonDir}/.keep".text = "";

  # api-keys.el from sys-secrets → ~/.config/emacs-common/api-keys.el
  home.file."${emacsCommonDir}/api-keys.el".source =
    mkSecret "${secretsRoot}/emacs/api-keys.el";
  
  home.file."${emacsDir}/early-init.el".source    = srcEarly;
  home.file."${emacsDir}/init.el".source          = srcInit;

  home.file."${emacsDir}/modules" = {
    source    = srcModules;
    recursive = true;
  };
  
  systemd.user.services.emacs-prod = {
    Unit = {
      Description = "Emacs daemon (emacs-prod)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${emacsPkg}/bin/emacs --fg-daemon=emacs-prod --init-directory=%h/.config/emacs-prod";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
