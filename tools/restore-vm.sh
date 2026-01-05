#!/usr/bin/env bash
set -euo pipefail

URI="qemu:///system"
EXPORT_DIR="/mnt/backup/angel-win11-exports"
IMAGES_DIR="/var/lib/libvirt/images"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v virsh >/dev/null || die "virsh not found"
command -v rsync >/dev/null || die "rsync not found"

[[ -d "$EXPORT_DIR" ]] || die "Export directory not found: $EXPORT_DIR"

read -r -p "VM name to RESTORE: " VM

if [[ -z "$VM" ]]; then
  echo
  echo "Available disk images in $EXPORT_DIR:"
  ls -1 "$EXPORT_DIR"/*.qcow2 2>/dev/null | sed 's#.*/##'
  echo
  read -r -p "VM name to RESTORE: " VM
fi

[[ -n "$VM" ]] || die "VM name required"

XML_IN="${EXPORT_DIR}/${VM}.xml"
DISK_IN="${EXPORT_DIR}/${VM}.qcow2"
DISK_OUT="${IMAGES_DIR}/${VM}.qcow2"

[[ -f "$XML_IN" ]] || die "Missing XML: $XML_IN"
[[ -f "$DISK_IN" ]] || die "Missing disk image: $DISK_IN"

if virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1; then
  die "VM '$VM' already exists"
fi

echo "Copying disk into libvirt images..."
sudo rsync -a --sparse --info=progress2 "$DISK_IN" "$DISK_OUT"

if id qemu >/dev/null 2>&1; then
  sudo chown qemu:qemu "$DISK_OUT" || true
fi

echo "Defining VM..."
sudo virsh -c "$URI" define "$XML_IN"

read -r -p "Start VM now? [y/N]: " A
if [[ "$A" =~ ^[Yy]$ ]]; then
  sudo virsh -c "$URI" start "$VM"
fi

echo "Restore complete."
