{ config, pkgs, repoPath, ... }:

let
  homeDir = config.home.homeDirectory;
  shellPath = repoPath "home/data/apps/utils/trim-screenshots.sh";
in
{
  home.file.".local/bin/trim-screenshots.sh" = {
      force = true;
      source = shellPath;
      executable = true;
  };
    
 systemd.user.services."trim-screenshots" = {
    Unit = {
      Description = "Delete screenshots > than count";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${homeDir}/.local/bin/trim-screenshots.sh";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers."trim-screenshots" = {
    Unit = {
      Description = "Run trim-screenshots every 30 minutes";
    };
    Timer = {
      OnCalendar = "*:0/30";  # every 30 minutes
      Persistent  = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
