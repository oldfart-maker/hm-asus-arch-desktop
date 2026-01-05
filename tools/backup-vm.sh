#!/usr/bin/env bash
set -euo pipefail

URI="qemu:///system"
EXPORT_DIR="/mnt/backup/angel-win11-exports"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v virsh >/dev/null || die "virsh not found"
command -v rsync >/dev/null || die "rsync not found"

[[ -d "$EXPORT_DIR" ]] || die "Export directory not found: $EXPORT_DIR"

echo "Available VMs:"
virsh -c "$URI" list --all --name | sed '/^$/d'
echo

read -r -p "VM name to BACKUP: " VM
[[ -n "$VM" ]] || die "VM name required"

# Validate VM exists
virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1 \
  || die "VM '$VM' does not exist"

# Find primary disk
DISK_PATH="$(
  virsh -c "$URI" domblklist "$VM" --details \
  | awk '$1=="file" && $2=="disk" {print $4; exit}'
)"

[[ -n "$DISK_PATH" ]] || die "No disk found for VM"
[[ -f "$DISK_PATH" ]] || die "Disk file not found: $DISK_PATH"

XML_OUT="${EXPORT_DIR}/${VM}.xml"
DISK_OUT="${EXPORT_DIR}/${VM}.qcow2"

STATE="$(virsh -c "$URI" domstate "$VM")"
if [[ "$STATE" == "running" ]]; then
  read -r -p "VM is running. Shut down before backup? [Y/n]: " A
  A="${A:-Y}"
  if [[ "$A" =~ ^[Yy]$ ]]; then
    virsh -c "$URI" shutdown "$VM"
    echo "Waiting for shutdown..."
    until [[ "$(virsh -c "$URI" domstate "$VM")" == "shut off" ]]; do
      sleep 2
    done
  else
    die "Refusing live backup without snapshotting"
  fi
fi

echo "Dumping XML..."
virsh -c "$URI" dumpxml "$VM" > "$XML_OUT"

echo "Copying disk..."
sudo rsync -a --sparse --info=progress2 "$DISK_PATH" "$DISK_OUT"

echo "Backup complete:"
echo "  $XML_OUT"
echo "  $DISK_OUT"
