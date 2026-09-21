#!/bin/bash
set -euo pipefail

# Run plugin initialization
/init-openrgb-plugins.sh

# Construct runtime flags cleanly handling spaced profile names
OPENRGB_ARGS=(
    --gui
    --server
    --noautoconnect
    --server-port "${OPENRGB_SERVER_PORT:-6742}"
)

if [[ -n "${OPENRGB_INITIAL_PROFILE:-}" ]]; then
    OPENRGB_ARGS+=(--profile "$OPENRGB_INITIAL_PROFILE")
fi

# Now start OpenRGB
exec /usr/bin/openrgb "${OPENRGB_ARGS[@]}"