#!/usr/bin/env bash
set -Eeuo pipefail
DIR="${1:-$HOME/Pictures/screenshots}"
KEEP="${2:-25}"

mapfile -d '' -t shots < <(
  find "$DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -printf '%T@ %p\0' | sort -rnz | cut -z -d' ' -f2-
)
(( ${#shots[@]} > KEEP )) || exit 0
to_remove=( "${shots[@]:$KEEP}" )
# delete older ones; swap to 'mv' into an archive if you prefer
printf '%s\0' "${to_remove[@]}" | xargs -0 -r rm -f --
