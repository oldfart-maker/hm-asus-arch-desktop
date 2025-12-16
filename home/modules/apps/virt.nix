{ config, lib, pkgs, repoPath, ... }:

let
  enable = true;
in
lib.mkIf enable
{
  home.packages = with pkgs; [
    virt-manager
    virt-viewer
    libvirt
    qemu_kvm
  ];
}
