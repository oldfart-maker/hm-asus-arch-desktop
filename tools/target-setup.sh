#!/usr/bin/env bash
# target-setup.sh
#
# Bootstrap script for a fresh Arch target.
#
# Behavior:
# - If run as root:
#     * enables sshd
#     * re-execs itself as LOCAL_USER="username"
# - If run as non-root (username):
#     * assumes ~/projects/sys-secrets already exists (cloned manually)
#     * installs Nix (no-daemon), Home Manager, and nixGL
#     * runs home-manager switch using the REMOTE flake:
#         github:oldfart-maker/hm-asus-arch-desktop#username
#
# Assumptions:
# - Network is up (Wi-Fi/DNS working)
# - ~/projects/sys-secrets exists and contains your secrets repo

set -euo pipefail
IFS=$'\n\t'

progname="$(basename "$0")"

print_usage() {
  cat <<EOF
Usage: $progname

Run this as root or as the target login user ("username") on a newly
installed Arch system. It will:

  - enable sshd
  - verify that ~/projects/sys-secrets exists
  - install Nix (no-daemon) and Home Manager
  - install nixGL
  - run home-manager switch with the remote flake:
      github:oldfart-maker/hm-asus-arch-desktop#username

Before running this script, make sure you have already created:

  ~/projects/sys-secrets

and populated it with your secrets repository.

EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

# --- Root → non-root flip -----------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
  LOCAL_USER="username"

  echo "Running as root. Enabling sshd, then re-running as ${LOCAL_USER}..."
  systemctl enable sshd --now || true

  exec su - "${LOCAL_USER}" -c "$0"
fi

# From here on, we are non-root (running as LOCAL_USER or direct login user).

echo "=== ${progname}: bootstrap starting as ${USER} ==="

# --- Ensure sys-secrets directory exists -------------------------------------

PROJECTS_DIR="${HOME}/projects"
SECRETS_DIR="${PROJECTS_DIR}/sys-secrets"

echo
echo "-> Checking for secrets directory at ${SECRETS_DIR}"
if [[ ! -d "${SECRETS_DIR}" ]]; then
  echo "ERROR: ${SECRETS_DIR} not found."
  echo
  echo "This script assumes your secrets repo is already present at:"
  echo "  ${SECRETS_DIR}"
  echo
  echo "Clone or create it there first, then re-run ${progname}."
  exit 1
fi

# --- Local helper dirs used by HM config -------------------------------------

echo
echo "-> Creating local helper directories"
mkdir -p "${HOME}/.config/emacs-common" "${HOME}/Pictures/wallpapers"

# --- Install Nix (no-daemon) if missing --------------------------------------

echo
echo "-> Installing Nix (no-daemon) if not already installed"
if command -v nix >/dev/null 2>&1; then
  echo "   nix already present; skipping installer"
else
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# Source Nix profile if available
if [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
  # shellcheck disable=SC1090
  . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  echo "   Sourced nix profile"
else
  echo "Warning: nix profile not found at ~/.nix-profile/etc/profile.d/nix.sh (may require new login)."
fi

# --- Home Manager via channel -------------------------------------------------

echo
echo "-> Setting up Home Manager channel and installing"
if ! nix-channel --list | grep -q "home-manager"; then
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
fi
nix-channel --update
nix-shell '<home-manager>' -A install || echo "Warning: home-manager install returned non-zero status"

# --- Enable flakes and nix-command -------------------------------------------

echo
echo "-> Enabling flakes and nix-command"
mkdir -p "${HOME}/.config/nix"
printf "experimental-features = nix-command flakes\n" > "${HOME}/.config/nix/nix.conf"
if [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
  # shellcheck disable=SC1090
  . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
fi
hash -r

# --- Install nixGL for Wayland compatibility ---------------------------------

echo
echo "-> Installing nixGL via channel"
if ! nix-channel --list | grep -q "nixgl"; then
  nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl
fi
nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault || echo "Warning: nix-env -iA nixgl.auto.nixGLDefault failed"

# --- home-manager switch via REMOTE flake ------------------------------------

echo
echo "-> Running home-manager switch via remote flake"
FLAKE_REF="github:oldfart-maker/hm-asus-arch-desktop#username"

if command -v nix >/dev/null 2>&1; then
  nix run nixpkgs#home-manager -- switch --flake "${FLAKE_REF}" -v --refresh || {
    echo "Warning: home-manager flake switch returned non-zero. Inspect output for details."
  }
else
  echo "ERROR: nix not found after install; skipping flake switch step"
fi

# --- Prime wallpapers from arch-wallpapers/png -------------------------------

echo
echo "-> Cloning arch-wallpapers and moving all *.png into ~/Pictures/wallpapers"
TMP_DIR="$(mktemp -d)"
pushd "$TMP_DIR" >/dev/null

if git clone https://github.com/greatbot6120/arch-wallpapers.git; then
  if [[ -d arch-wallpapers/png ]]; then
    mkdir -p "${HOME}/Pictures/wallpapers"
    shopt -s nullglob
    PNGS=(arch-wallpapers/png/*.png)
    if [[ ${#PNGS[@]} -gt 0 ]]; then
      mv arch-wallpapers/png/*.png "${HOME}/Pictures/wallpapers/"
      echo "   Moved ${#PNGS[@]} PNG(s) to ${HOME}/Pictures/wallpapers"
    else
      echo "   No PNG files found in arch-wallpapers/png"
    fi
    shopt -u nullglob
  else
    echo "Warning: arch-wallpapers/png directory not found in cloned repo"
  fi
  rm -rf arch-wallpapers
else
  echo "Warning: git clone failed for arch-wallpapers"
fi

popd >/dev/null
rm -rf "$TMP_DIR"

# --- Finish ------------------------------------------------------------------

echo
echo "=== Finished ${progname} ==="
echo "Nix, Home Manager, nixGL, sys-secrets (pre-cloned), and the remote HM flake are now wired up."
