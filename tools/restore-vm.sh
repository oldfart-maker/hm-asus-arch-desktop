#!/usr/bin/env bash
set -euo pipefail

# Restore a libvirt VM from an export directory:
#   - reads <vm>.xml in export dir
#   - copies disk image into /var/lib/libvirt/images/
#   - defines VM
#   - optionally starts it
#
# Default export base: /mnt/backup
# Export dir:          /mnt/backup/<vm>-exports

URI="qemu:///system"
DEFAULT_BASE="/mnt/backup"
DEFAULT_IMAGES_DIR="/var/lib/libvirt/images"

die() { echo "ERROR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

need virsh
need rsync

read -r -p "VM name to RESTORE: " VM
[[ -n "${VM}" ]] || die "VM name is required."

read -r -p "Backup base dir [${DEFAULT_BASE}]: " BASE
BASE="${BASE:-$DEFAULT_BASE}"
[[ -d "$BASE" ]] || die "Backup base dir does not exist: $BASE"

SRC="${BASE%/}/${VM}-exports"
[[ -d "$SRC" ]] || die "Export dir not found: $SRC"

XML_IN="${SRC}/${VM}.xml"
[[ -f "$XML_IN" ]] || die "Missing XML: $XML_IN"

# Find a likely disk file in exports dir (prefer qcow2)
DISK_IN="$(
  ls -1 "$SRC" 2>/dev/null | awk '
    /\.qcow2$/ {print; exit}
    /\.img$/ {print; exit}
    /\.raw$/ {print; exit}
    {last=$0}
    END {if (last!="") print last}
  ' | head -n 1
)"

[[ -n "${DISK_IN}" ]] || die "Could not find a disk file in: $SRC"
DISK_IN="${SRC}/${DISK_IN}"
[[ -f "$DISK_IN" ]] || die "Disk file not found: $DISK_IN"

read -r -p "Libvirt images dir [${DEFAULT_IMAGES_DIR}]: " IMAGES_DIR
IMAGES_DIR="${IMAGES_DIR:-$DEFAULT_IMAGES_DIR}"
[[ -d "$IMAGES_DIR" ]] || die "Images dir does not exist: $IMAGES_DIR"

DISK_OUT="${IMAGES_DIR}/$(basename "$DISK_IN")"

echo
echo "Restore source:"
echo "  XML : $XML_IN"
echo "  DISK: $DISK_IN"
echo
echo "Restore destination:"
echo "  DISK -> $DISK_OUT"
echo

# If VM already exists, refuse unless user deletes it first (safer).
if virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1; then
  die "VM '$VM' already exists on this host. Undefine/delete it first (or choose a different name)."
fi

# Copy disk first
echo "Copying disk into libvirt images dir..."
sudo rsync -a --sparse --info=progress2 "$DISK_IN" "$DISK_OUT"

# Ensure ownership is libvirt-friendly (Arch often uses qemu:qemu)
# This is safe; if your system uses different user, adjust.
if id -u qemu >/dev/null 2>&1; then
  echo "Setting ownership to qemu:qemu..."
  sudo chown qemu:qemu "$DISK_OUT" || true
fi

# Define VM
echo "Defining VM from XML..."
sudo virsh -c "$URI" define "$XML_IN"

echo "VM defined."

read -r -p "Start VM now? [y/N]: " START
START="${START:-N}"
if [[ "$START" =~ ^[Yy]$ ]]; then
  echo "Starting VM..."
  sudo virsh -c "$URI" start "$VM"
  sudo virsh -c "$URI" list --all
fi

echo
echo "Restore complete."
