# home/modules/rclone.nix
{ config, pkgs, lib, ... }:

let
  secretsRoot = "${config.home.homeDirectory}/projects/sys-secrets";
in
{
  home.packages = [ pkgs.rclone ];

  home.activation.linkRcloneSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.config/rclone"

    ln -sf "${secretsRoot}/rclone/rclone.conf" \
      "${config.home.homeDirectory}/.config/rclone/rclone.conf"

    ln -sf "${secretsRoot}/rclone/officesync.filter" \
      "${config.home.homeDirectory}/.config/rclone/officesync.filter"
  '';
}
