#!/usr/bin/env bash
set -euo pipefail

########################################
# Paths and constants
########################################

# source repo root from active script dir
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="$SCRIPT_DIR/user_configuration.json"
CREDS_FILE="$SCRIPT_DIR/user_credentials.json"

TARGET_MNT="/mnt"

########################################
# Modes / args
########################################

MODE="full"        # full | post-only
ROOT_PART=""       # required for --post-only
BOOT_PART=""       # optional for --post-only

usage() {
  cat <<EOF
Usage:
  ./bootstrap.sh
  ./bootstrap.sh --post-only --root /dev/XXX [--boot /dev/YYY]
  ./bootstrap.sh --post-only --root /dev/nvme0n1p2 --boot /dev/nvme0n1p1


Options:
  --post-only         Skip archinstall; mount an existing install and run post-install steps only
  --root /dev/XXX     Root partition to mount at $TARGET_MNT (required for --post-only)
  --boot /dev/YYY     Optional boot partition to mount at $TARGET_MNT/boot (only if needed)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --post-only)
        MODE="post-only"
        shift
        ;;
      --root)
        ROOT_PART="${2:-}"
        shift 2
        ;;
      --boot)
        BOOT_PART="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown arg: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

########################################
# Helper functions
########################################

die() {
  echo "ERROR: $*" >&2
  exit 1
}

check_prereqs() {
  echo "=== bootstrap.sh: sanity checks ==="

  # Only required in full mode
  if [[ "$MODE" == "full" ]]; then
    [[ -f "$CONFIG_FILE" ]] || die "$CONFIG_FILE not found."
    [[ -f "$CREDS_FILE"  ]] || die "$CREDS_FILE not found."
    command -v archinstall >/dev/null 2>&1 || die "archinstall not found in PATH."
  fi

  # arch-chroot is used in both modes (post-install)
  command -v arch-chroot >/dev/null 2>&1 || die "arch-chroot not found in PATH."

  # Optional: ensure we're running from the ISO environment
  [[ -d /sys/firmware/efi ]] || echo "WARNING: Not obviously in live ISO (no /sys/firmware/efi)."
}

run_archinstall() {
  echo "=== bootstrap.sh: running archinstall ==="
  archinstall --config "$CONFIG_FILE" --creds "$CREDS_FILE" --silent
}

ensure_target_mounted() {
  [[ -d "$TARGET_MNT/etc" ]] || die "Target mountpoint $TARGET_MNT does not look like a system (no etc/)."
  [[ -f "$TARGET_MNT/etc/os-release" ]] || die "Target mountpoint $TARGET_MNT missing /etc/os-release; not a valid install?"
}

mount_target_for_post_only() {
  [[ -n "$ROOT_PART" ]] || die "--post-only requires --root /dev/XYZ"

  echo "=== bootstrap.sh: post-only mode: mounting target ==="
  mkdir -p "$TARGET_MNT"

  # If already mounted, do not remount
  if mountpoint -q "$TARGET_MNT"; then
    echo "NOTE: $TARGET_MNT already mounted; leaving as-is."
  else
    echo "Mounting root: $ROOT_PART -> $TARGET_MNT"
    mount "$ROOT_PART" "$TARGET_MNT"
  fi

  # Only mount boot if explicitly provided
  if [[ -n "$BOOT_PART" ]]; then
    mkdir -p "$TARGET_MNT/boot"
    if mountpoint -q "$TARGET_MNT/boot"; then
      echo "NOTE: $TARGET_MNT/boot already mounted; leaving as-is."
    else
      echo "Mounting boot: $BOOT_PART -> $TARGET_MNT/boot"
      mount "$BOOT_PART" "$TARGET_MNT/boot"
    fi
  fi

  ensure_target_mounted
}

cleanup_mounts() {
  # Only unmount if we mounted in post-only mode
  [[ "$MODE" == "post-only" ]] || return 0

  set +e
  if mountpoint -q "$TARGET_MNT/boot"; then
    umount "$TARGET_MNT/boot"
  fi
  if mountpoint -q "$TARGET_MNT"; then
    umount "$TARGET_MNT"
  fi
  set -e
}

setup_avahi_in_target() {
  echo "=== bootstrap.sh: setting up Avahi + nss-mdns in target ==="

  # source / target locations
  local nsswitch_src nsswitch_tgt
  nsswitch_src="$REPO_ROOT/home/data/apps/avahi/nsswitch.conf"
  nsswitch_tgt="$TARGET_MNT/etc/nsswitch.conf"

  local sshservice_src sshservice_tgt
  sshservice_src="$REPO_ROOT/home/data/apps/avahi/ssh.service"
  sshservice_tgt="$TARGET_MNT/etc/avahi/services/ssh.service"

  # ensure source files exist
  [[ -f "$nsswitch_src" ]] || die "nsswitch.conf not found at: $nsswitch_src"
  [[ -f "$sshservice_src" ]] || die "ssh.service not found at: $sshservice_src"

  # ensure target dirs exist
  mkdir -p "$TARGET_MNT/etc/avahi/services"

  # Install packages into the target system (idempotent)
  if [[ "$MODE" == "post-only" ]]; then
      arch-chroot "$TARGET_MNT" pacman --noconfirm -S --needed avahi nss-mdns
  fi

  # Enable the systemd service (will start on first boot)
  arch-chroot "$TARGET_MNT" systemctl enable avahi-daemon.service

  # Install configuration files
  echo "Installing nsswitch.conf from: $nsswitch_src"
  install -m 644 "$nsswitch_src" "$nsswitch_tgt"

  echo "Installing ssh.service from: $sshservice_src"
  install -m 644 "$sshservice_src" "$sshservice_tgt"
}

setup_ssh_in_target() {
  echo "=== bootstrap.sh: setting up ssh in target ==="

  # source / target locations
  local sshconfig_src sshconfig_tgt
  sshconfig_src="$REPO_ROOT/home/data/apps/ssh/config"
  sshconfig_tgt="$TARGET_MNT~/.ssh/config"

  # ensure source files exist
  [[ -f "$sshconfig_src" ]] || die "ssh config not found at: $sshconfig_src"

  # ensure target dirs exist
  mkdir -p "$TARGET_MNT~/.ssh"

  # Install packages into the target system (idempotent)
  if [[ "$MODE" == "post-only" ]]; then
      arch-chroot "$TARGET_MNT" pacman --noconfirm -S --needed openssh
  fi

  # Enable the systemd service (will start on first boot)
  arch-chroot "$TARGET_MNT" systemctl enable sshd.service

  # Install configuration files
  echo "Installing ssh config from: $sshconfig_src"
  install -m 644 "$sshconfig_src" "$sshconfig_tgt"
}

post_install() {
  echo "=== bootstrap.sh: running post-install configuration ==="
  ensure_target_mounted
  setup_avahi_in_target
  setup_ssh_in_target
}

main() {
  parse_args "$@"
  trap cleanup_mounts EXIT

  check_prereqs

  if [[ "$MODE" == "full" ]]; then
    run_archinstall
    post_install
  else
    mount_target_for_post_only
    post_install
  fi

  echo "=== bootstrap.sh: DONE ==="
  if [[ "$MODE" == "full" ]]; then
    echo "You can now reboot into the installed system and run target-setup.sh."
  else
    echo "Post-only mode complete."
  fi
}

main "$@"
