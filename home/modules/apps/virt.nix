{ pkgs, ... }:
{
  home.packages = with pkgs; [
    virt-manager
    virt-viewer
    libvirt
    qemu_kvm
  ];
}
