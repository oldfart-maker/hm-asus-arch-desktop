{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  #### officesync script (no repair_remote_docs) ####

  home.file.".local/bin/officesync.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      REMOTE_DIR='gdrive:Office-Docs (Global Sync)'
      LOCAL_DIR="$HOME/Documents/Office-Docs (Global Sync)"

      CACHE_DIR="$HOME/.cache/rclone"
      LOG="$CACHE_DIR/officesync.log"
      LOCK="$CACHE_DIR/officesync.lock"

      mkdir -p "$LOCAL_DIR" "$CACHE_DIR"

      # single-instance lock
      exec 9>"$LOCK"
      if ! flock -n 9; then
        echo "$(date -Is) already running; exiting" >> "$LOG"
        exit 0
      fi

      log() { echo "$(date -Is) $*" >> "$LOG"; }

      run_bisync() {
        nice -n 10 ionice -c2 -n7 rclone bisync "$LOCAL_DIR" "$REMOTE_DIR" \
          --conflict-resolve newer \
          --create-empty-src-dirs \
          --drive-skip-gdocs \
          --retries 1 --low-level-retries 1 \
          --log-file "$LOG" --log-level INFO -P
      }

      # 1) first attempt
      log "bisync: first attempt"
      if run_bisync; then
        log "bisync: success"
        exit 0
      fi

      # 2) fallback: one-time --resync, then a final normal pass
      log "bisync failed; attempting --resync"
      if nice -n 10 ionice -c2 -n7 rclone bisync "$LOCAL_DIR" "$REMOTE_DIR" \
            --resync --conflict-resolve newer \
            --create-empty-src-dirs \
            --drive-skip-gdocs \
            --retries 1 --low-level-retries 1 \
            --filter-from "$HOME/.config/rclone/officesync.filter" \
            --log-file "$LOG" --log-level INFO -P; then
        log "bisync --resync: success; running final normal pass"
        if run_bisync; then
          log "bisync: success after resync"
          exit 0
        fi
      fi

      log "bisync: still failing after resync"
      exit 1
    '';
    executable = true;
  };

  #### systemd user service + timer ####

  systemd.user.services."officesync" = {
    Unit = {
      Description = "Rclone bisync Office-Docs (Global Sync)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${homeDir}/.local/bin/officesync.sh";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers."officesync" = {
    Unit = {
      Description = "Run officesync every 30 minutes";
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
