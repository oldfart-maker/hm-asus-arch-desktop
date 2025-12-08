#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="user_configuration.json"
CREDS_FILE="user_credentials.json"

echo "=== bootstrap.sh: running archinstall ==="

# sanity checks so you don't get mysterious failures
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: $CONFIG_FILE not found in current directory."
  exit 1
fi

if [[ ! -f "$CREDS_FILE" ]]; then
  echo "ERROR: $CREDS_FILE not found in current directory."
  exit 1
fi

archinstall --config "$CONFIG_FILE" --creds "$CREDS_FILE" --silent
