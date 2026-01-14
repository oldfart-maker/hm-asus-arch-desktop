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

  # ---- HARD-CODE TARGET USER ----
  local TARGET_USER="username"

  # ---- SOURCE ----
  local sshconfig_src
  sshconfig_src="$REPO_ROOT/home/data/apps/ssh/config"

  # ---- TARGET PATHS (INSIDE INSTALLED SYSTEM) ----
  local ssh_dir sshconfig_tgt
  ssh_dir="$TARGET_MNT/home/$TARGET_USER/.ssh"
  sshconfig_tgt="$ssh_dir/config"

  # ensure source file exists
  [[ -f "$sshconfig_src" ]] || die "ssh config not found at: $sshconfig_src"

  # ensure target .ssh dir exists with correct perms
  install -d -m 700 "$ssh_dir"

  # install ssh client into target (idempotent)
  if [[ "$MODE" == "post-only" ]]; then
    arch-chroot "$TARGET_MNT" pacman --noconfirm -S --needed openssh
  fi

  # enable ssh daemon for inbound connections
  arch-chroot "$TARGET_MNT" systemctl enable sshd.service

  # install ssh config with correct perms
  echo "Installing ssh config from: $sshconfig_src"
  install -m 600 "$sshconfig_src" "$sshconfig_tgt"

  # fix ownership (ISO runs as root)
  arch-chroot "$TARGET_MNT" chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.ssh"

# Generate a GitHub-friendly SSH key on first install (idempotent)
# This avoids PAT/password prompts for git operations.
  local ssh_key="/home/$TARGET_USER/.ssh/id_ed25519"
  local ssh_pub="${ssh_key}.pub"

  if ! arch-chroot "$TARGET_MNT" test -f "$ssh_key"; then
      echo "Generating SSH key for $TARGET_USER inside target: $ssh_key"
      arch-chroot "$TARGET_MNT" su - "$TARGET_USER" -c \
      "ssh-keygen -t ed25519 -a 100 -N '' -f '$ssh_key' -C '${TARGET_USER}@${HOSTNAME:-arch}'"
  else
      echo "SSH key already exists for $TARGET_USER: $ssh_key"
  fi

# Pre-seed known_hosts for github.com to avoid first-connect prompt (safe to re-run)
  arch-chroot "$TARGET_MNT" su - "$TARGET_USER" -c \
    "mkdir -p ~/.ssh && touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts"
  arch-chroot "$TARGET_MNT" su - "$TARGET_USER" -c \
    "ssh-keyscan -H github.com 2>/dev/null >> ~/.ssh/known_hosts || true"

  echo "=== Add this public key to GitHub (Settings → SSH and GPG keys) ==="
  arch-chroot "$TARGET_MNT" cat "$ssh_pub" || true
  echo "=================================================================="
}

setup_external_mounts_in_target() {
  echo "=== bootstrap.sh: setting up external mountpoints in target ==="

  # Mountpoints *inside the installed system*
  mkdir -p "$TARGET_MNT/mnt/timeshift" "$TARGET_MNT/mnt/backup"
  chmod 0755 "$TARGET_MNT/mnt/timeshift" "$TARGET_MNT/mnt/backup"

  local fstab="$TARGET_MNT/etc/fstab"
  touch "$fstab"

  add_fstab_uuid_entry() {
    local dev="$1"
    local mnt="$2"
    local opts="${3:-defaults,nofail}"

    if [[ ! -b "$dev" ]]; then
      echo "WARN: $dev not found; skipping fstab entry for $mnt"
      return 0
    fi

    local uuid fstype
    uuid="$(blkid -s UUID -o value "$dev" 2>/dev/null || true)"
    fstype="$(blkid -s TYPE -o value "$dev" 2>/dev/null || true)"

    if [[ -z "$uuid" || -z "$fstype" ]]; then
      echo "WARN: could not read UUID/TYPE for $dev; skipping fstab entry for $mnt"
      return 0
    fi

    # Remove any existing non-comment entry for this mountpoint (prevents stale lines)
    sed -i "\|^[^#].*[[:space:]]${mnt}[[:space:]]|d" "$fstab"

    echo "Adding fstab entry for $dev -> $mnt (UUID=$uuid, TYPE=$fstype)"
    printf "UUID=%s\t%s\t%s\t%s\t0 2\n" "$uuid" "$mnt" "$fstype" "$opts" >> "$fstab"
  }

  # External partitions (adjust if layout changes)
  add_fstab_uuid_entry "/dev/sdc1" "/mnt/timeshift"
  add_fstab_uuid_entry "/dev/sdc2" "/mnt/backup"

  echo "=== bootstrap.sh: fstab entries now ==="
  grep -nE '(/mnt/timeshift|/mnt/backup)' "$fstab" || true
}

setup_smb_in_target() {
  echo "=== bootstrap.sh: setting up samba in target ==="

  # ---- HARD-CODE TARGET USER ----
  local TARGET_USER="username"

  # ---- SOURCE ----
  local smbconf_src
  smbconf_src="$REPO_ROOT/home/data/apps/smb/smb.conf"

  # ---- TARGET PATHS (INSIDE INSTALLED SYSTEM) ----
  local samba_dir smbconf_tgt
  samba_dir="$TARGET_MNT/etc/samba"
  smbconf_tgt="$samba_dir/smb.conf"

  [[ -f "$smbconf_src" ]] || die "Missing smb.conf source file: $smbconf_src"
  install -d -m 0755 "$samba_dir"

  # ensure share path exists inside installed system
  install -d -m 0755 "$TARGET_MNT/mnt/backup"

  # install samba package (always safe / idempotent)
  arch-chroot "$TARGET_MNT" pacman --noconfirm -S --needed samba

  echo "Installing smb.conf from: $smbconf_src"
  install -m 0644 "$smbconf_src" "$smbconf_tgt"

  # enable services
  arch-chroot "$TARGET_MNT" systemctl enable smb.service nmb.service

  # Provision samba credentials:
  # We intentionally do NOT store passwords in git. If running interactively, prompt once now.
  if [[ -t 0 ]]; then
    echo "=== bootstrap.sh: samba user provisioning ==="
    echo "You will be prompted to set the Samba password for: $TARGET_USER"
    echo "Tip: this can match your Linux password, or be different."
    arch-chroot "$TARGET_MNT" smbpasswd -a "$TARGET_USER"
    arch-chroot "$TARGET_MNT" smbpasswd -e "$TARGET_USER" || true
  else
    echo "NOTE: Non-interactive session; skipping smbpasswd provisioning."
    echo "After boot, run: sudo smbpasswd -a $TARGET_USER"
  fi
}

setup_virt_in_target() {
  echo "=== bootstrap.sh: setting up libvirt/qemu in target ==="

  local TARGET_USER="username"

  arch-chroot "$TARGET_MNT" pacman --noconfirm -S --needed \
    qemu-full libvirt  dnsmasq  bridge-utils

  # Sanity: user must exist in target
  if ! arch-chroot "$TARGET_MNT" id "$TARGET_USER" >/dev/null 2>&1; then
    echo "ERROR: target user '$TARGET_USER' does not exist in $TARGET_MNT yet."
    echo "Fix: ensure archinstall creates this user, or create it before setup_virt_in_target."
    return 1
  fi

  # Ensure required groups exist (safe if already present)
  arch-chroot "$TARGET_MNT" getent group libvirt >/dev/null 2>&1 || \
    arch-chroot "$TARGET_MNT" groupadd libvirt

  # Add user to groups typically needed for virtualization workflows
  arch-chroot "$TARGET_MNT" usermod -aG libvirt,kvm "$TARGET_USER"

  echo "=== bootstrap.sh: target user groups (inside chroot) ==="
  arch-chroot "$TARGET_MNT" id "$TARGET_USER"

  # Enable libvirt services (do NOT use --now in chroot)
  # Sanity check unit file exists
  if ! arch-chroot "$TARGET_MNT" test -f /usr/lib/systemd/system/libvirtd.service; then
    echo "ERROR: libvirtd.service unit not found in target. Package install may have failed."
    return 1
  fi

  arch-chroot "$TARGET_MNT" systemctl enable libvirtd.service

  # virtlogd is commonly present; enable if it exists
  if arch-chroot "$TARGET_MNT" test -f /usr/lib/systemd/system/virtlogd.service; then
    arch-chroot "$TARGET_MNT" systemctl enable virtlogd.service
  fi

  # Ensure default NAT network autostarts on boot (file-based autostart)
  mkdir -p "$TARGET_MNT/etc/libvirt/qemu/networks/autostart"

  if [[ -f "$TARGET_MNT/etc/libvirt/qemu/networks/default.xml" ]]; then
    ln -sf ../default.xml "$TARGET_MNT/etc/libvirt/qemu/networks/autostart/default.xml"
    echo "Configured libvirt default network to autostart."
  else
    echo "NOTE: $TARGET_MNT/etc/libvirt/qemu/networks/default.xml not found."
    echo "After first boot, run:"
    echo "  sudo virsh net-define /etc/libvirt/qemu/networks/default.xml"
    echo "  sudo virsh net-autostart default"
    echo "  sudo virsh net-start default"
  fi

  echo "=== bootstrap.sh: libvirt setup complete ==="
}

post_install() {
  echo "=== bootstrap.sh: running post-install configuration ==="
  ensure_target_mounted
  setup_external_mounts_in_target
  setup_avahi_in_target
  setup_ssh_in_target
  setup_smb_in_target
  setup_virt_in_target
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
