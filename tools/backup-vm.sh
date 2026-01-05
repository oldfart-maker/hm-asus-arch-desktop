#!/usr/bin/env bash
set -euo pipefail

URI="qemu:///system"
DEFAULT_BACKUP_ROOT="/mnt/backup"
IMAGES_DIR="/var/lib/libvirt/images"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need virsh
need rsync
need awk
need sed
need date

read -rp "VM name to BACKUP: " VM
[[ -n "${VM}" ]] || { echo "VM name required." >&2; exit 1; }

# confirm VM exists
if ! virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1; then
  echo "VM '$VM' not found in $URI" >&2
  exit 1
fi

read -rp "Backup root directory [${DEFAULT_BACKUP_ROOT}]: " BACKUP_ROOT
BACKUP_ROOT="${BACKUP_ROOT:-$DEFAULT_BACKUP_ROOT}"

TS="$(date +%Y%m%d-%H%M%S)"
OUTDIR="${BACKUP_ROOT}/${VM}/${TS}"
mkdir -p "$OUTDIR"

echo
echo "Backup destination: $OUTDIR"
echo

STATE="$(virsh -c "$URI" domstate "$VM" | tr -d '\r')"
if [[ "$STATE" =~ ^running|paused$ ]]; then
  read -rp "VM is '$STATE'. Shut it down for a consistent backup? [Y/n]: " ans
  ans="${ans:-Y}"
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "Requesting shutdown..."
    virsh -c "$URI" shutdown "$VM" || true

    echo "Waiting up to 120s for shutdown..."
    for _ in {1..120}; do
      STATE="$(virsh -c "$URI" domstate "$VM" | tr -d '\r')"
      [[ "$STATE" =~ ^shut\ off$ ]] && break
      sleep 1
    done

    STATE="$(virsh -c "$URI" domstate "$VM" | tr -d '\r')"
    if [[ ! "$STATE" =~ ^shut\ off$ ]]; then
      echo "VM did not shut down in time. Aborting to avoid inconsistent disk copy." >&2
      exit 1
    fi
  else
    echo "Continuing without shutdown (backup may be inconsistent)."
  fi
fi

# Dump XML
XML_OUT="${OUTDIR}/${VM}.xml"
echo "Dumping domain XML -> $XML_OUT"
virsh -c "$URI" dumpxml "$VM" > "$XML_OUT"

# Save a small manifest (helps future you)
MANIFEST="${OUTDIR}/MANIFEST.txt"
{
  echo "vm=${VM}"
  echo "timestamp=${TS}"
  echo "uri=${URI}"
  echo "host=$(hostname)"
  echo "state=${STATE}"
} > "$MANIFEST"

# Gather file-backed disks from domblklist
# Output format: target  source
mapfile -t DISK_LINES < <(virsh -c "$URI" domblklist "$VM" --details \
  | awk '$1=="file" && $3=="disk" {print $4 "\t" $5}')

if (( ${#DISK_LINES[@]} == 0 )); then
  echo "No file-backed disks found to back up (domblklist --details returned none)." >&2
  exit 1
fi

echo
echo "Disks to back up:"
printf '%s\n' "${DISK_LINES[@]}" | sed 's/\t/ -> /'
echo

DISK_DIR="${OUTDIR}/disks"
mkdir -p "$DISK_DIR"

# Copy each disk
while IFS=$'\t' read -r TARGET SRC; do
  [[ -n "$SRC" ]] || continue
  if [[ ! -f "$SRC" ]]; then
    echo "Disk source does not exist: $SRC" >&2
    exit 1
  fi

  base="$(basename "$SRC")"
  dest="${DISK_DIR}/${base}"

  echo "Copying ($TARGET) $SRC -> $dest"
  # --sparse preserves holes; -a preserves metadata; --info=progress2 is nice feedback
  sudo rsync -a --sparse --info=progress2 "$SRC" "$dest"

  # record mapping
  echo "${TARGET}=${base}" >> "${OUTDIR}/DISK_MAP.env"
done < <(printf '%s\n' "${DISK_LINES[@]}")

echo
echo "Backup complete."
echo "  XML:     $XML_OUT"
echo "  DISKS:   $DISK_DIR/"
echo "  MAP:     ${OUTDIR}/DISK_MAP.env"
echo
