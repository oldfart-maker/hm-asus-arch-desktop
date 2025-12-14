{ config, lib, pkgs, ... }:

let
  # Flip this if you ever want to temporarily disable the whole module
  enable = true;

  # Keep your canonical XML(s) in git somewhere like: home/data/vms/*.xml
  # Adjust these paths to match your repo layout.
  vmXmls = [
    ../../data/vms/win11.xml
    # ../../data/vms/other.xml
  ];

  cfgDir = "${config.home.homeDirectory}/.config/libvirt/qemu";

in
lib.mkIf enable
{
  home.packages = with pkgs; [
    virt-manager
    libvirt     # provides virsh
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

          # Define/refresh the VM for per-user libvirt (qemu:///session)
          if command -v virsh >/dev/null 2>&1; then
            virsh --connect qemu:///session define "${cfgDir}/${base}" >/dev/null 2>&1 || true
          fi
        ''
      ) vmXmls}
    '';
}
