#!/bin/bash
set -euo pipefail

# Run plugin initialization
/init-openrgb-plugins.sh

# Now start OpenRGB
exec /usr/app/openrgb \
    --gui \
    --server \
    --noautoconnect \
    --server-port "$OPENRGB_SERVER_PORT" \
    ${OPENRGB_INITIAL_PROFILE:+--profile "$OPENRGB_INITIAL_PROFILE"}
