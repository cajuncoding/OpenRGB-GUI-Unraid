#!/bin/sh
exec /usr/app/openrgb \
    --gui \
    --server \
    --noautoconnect \
    --server-port "$OPENRGB_SERVER_PORT" \
