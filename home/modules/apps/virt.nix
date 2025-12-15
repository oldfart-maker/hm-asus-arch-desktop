{ config, lib, pkgs, repoPath, ... }:

let
  enable = true;

  # Canonical VM XML(s) stored in git
  vmXmls = [
    (repoPath "home/data/apps/vms/ANGEL-ARCH.xml")
    # (repoPath "home/data/vms/other.xml")
  ];

  cfgDir = "${config.home.homeDirectory}/.config/libvirt/qemu";
in
lib.mkIf enable
{
  home.packages = with pkgs; [
    virt-manager
    libvirt     # virsh
    qemu_kvm
  ];

  home.activation.libvirtSessionVMs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      mkdir -p "${cfgDir}"

      ${lib.concatMapStrings (xml:
        let base = builtins.baseNameOf xml;
        in ''
          echo "Syncing ${base} -> ${cfgDir}/${base}"
          cp "${xml}" "${cfgDir}/${base}"

          # Define/refresh VM in per-user libvirt session
          if command -v virsh >/dev/null 2>&1; then
            virsh --connect qemu:///session define "${cfgDir}/${base}" >/dev/null 2>&1 || true
          fi
        ''
      ) vmXmls}
    '';
}
